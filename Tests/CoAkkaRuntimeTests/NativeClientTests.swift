import CoAkkaRuntimeC
import Foundation
import XCTest
@testable import CoAkkaRuntime

// No shared mutable fixture state. Concurrent closures use session gates or
// LockedResult; XCTest's per-case object is not used as a worker state owner.
final class NativeClientTests: XCTestCase, @unchecked Sendable {
    // The probe owns only a weak slot and cannot extend the runtime's lifetime.
    private final class WeakHost {
        weak var value: RuntimeHost?
        init(_ value: RuntimeHost) { self.value = value }
    }

    private func host(_ suffix: String = "test", monitor: Bool? = nil) throws -> RuntimeHost {
        try RuntimeHost.start(ConnectorStartSpec(systemName: "swift-native", nodeID: suffix,
            routes: [.local("echo")], enableMonitor: monitor))
    }

    func testCoreStartupPresenceAndDelivery() throws {
        XCTAssertEqual(toRuntimeState(UInt32.max), .unknown(Int(UInt32.max)))
        let omitted = try host("omitted"), explicit = try host("explicit", monitor: false)
        defer { try? omitted.close(); try? explicit.close() }
        let a = try omitted.startupConfig(), b = try explicit.startupConfig()
        XCTAssertEqual(a.defaultedGroups, 15)
        XCTAssertEqual(b.defaultedGroups, 7)
        XCTAssertEqual(a.connection.mode, .multiplexing)
        XCTAssertEqual(a.execution.requestedPolicy, 0)
        XCTAssertFalse(a.io.requested)
        XCTAssertFalse(a.io.probed)
        XCTAssertFalse(a.monitorEnabled)
        XCTAssertFalse(b.monitorEnabled)
        XCTAssertNil(omitted.startupTcpConnectionResult())
        // Exact f6/metadata-r1 images select owned delivery on all three hosts.
        // This is a sealed artifact assertion, never connector platform policy.
        let expectedMode: UInt32 = 2
        XCTAssertEqual(try omitted.deliveryConfig().requestMode, expectedMode)
        XCTAssertEqual(try omitted.deliveryConfig().responseMode, expectedMode)
        let changed = try omitted.applyTcpConnectionStrategy(TcpConnectionStrategySpec(mode: .perExchange))
        XCTAssertEqual(changed.status, .badState)
        XCTAssertFalse(changed.changed)
        XCTAssertEqual(changed.activeConfig.mode, .multiplexing)
        try omitted.close(); try explicit.close()
    }

    func testEmptyLargeBytesAndRichIdentity() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        try runtime.registerHandler("echo") { request in
            XCTAssertTrue(request.messageID.hasPrefix("client-swift-"))
            XCTAssertEqual(request.source, "client")
            XCTAssertEqual(request.target, "echo")
            XCTAssertFalse(request.oneWay)
            return request.payload
        }
        XCTAssertEqual(try runtime.askPayload(source: "client", target: "echo", payload: Data(), timeoutMs: 2000), Data())
        let payload = Data((0..<(96 * 1024)).map { UInt8(truncatingIfNeeded: $0 * 31 + 17) })
        let response = try runtime.ask(source: "client", target: "echo", payload: payload, timeoutMs: 2000)
        XCTAssertEqual(response.payload, payload)
        XCTAssertEqual(response.correlationID, "client-swift-2")
        XCTAssertFalse(response.messageID.isEmpty)
        XCTAssertEqual(response.source, "echo")
        XCTAssertEqual(response.target, "client")
        XCTAssertEqual(runtime.clientStats().matchedResponses, 2)
        try runtime.close()
    }

    func testExplicitGroupsUnknownValuesAndOneShotTicket() throws {
        let runtime = try RuntimeHost.start(ConnectorStartSpec(systemName: "explicit", nodeID: "explicit", routes: [.local("echo")],
            connectionStrategy: TcpConnectionStrategySpec(mode: .multiplexing), cpuPolicy: .auto, useIoUring: false, enableMonitor: false))
        defer { try? runtime.close() }
        let value = try runtime.startupConfig()
        XCTAssertEqual(value.defaultedGroups, 0)
        XCTAssertEqual(value.connection.explicitlyConfiguredFields & 1, 1)
        XCTAssertFalse(value.io.requested)
        XCTAssertFalse(value.monitorEnabled)
        try runtime.registerPayloadHandler("echo") { $0 }
        let ticket = try runtime.beginAsk(source: "client", target: "echo", payload: Data([1]), timeoutMs: 2000, hint: .routerDefault)
        XCTAssertEqual(try ticket.awaitResult(timeoutMs: 2000, payloadOnly: true).bytes, Data([1]))
        XCTAssertThrowsError(try ticket.awaitResult(timeoutMs: 0, payloadOnly: true))
        XCTAssertEqual(runtime.session.borrowedAsks, 0)
        let invalid = RuntimeRequest(messageID: "id", source: "source", target: "echo", payload: Data([0xff]), oneWay: false)
        XCTAssertNil(invalid.payloadString())
        try runtime.close()
    }

    func testDeadletterTimeoutAndCStringSafety() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        XCTAssertThrowsError(try runtime.askPayload(source: "client", target: "absent", payload: Data(), timeoutMs: 2000)) { error in
            guard case RuntimeError.deadletter(let value) = error else { return XCTFail("\(error)") }
            XCTAssertEqual(value.reasonCode, 2)
            XCTAssertEqual(value.reason, "route_miss")
            XCTAssertEqual(value.originalTarget, "absent")
            XCTAssertEqual(value.originalSource, "client")
            XCTAssertEqual(value.originalMessageID, "client-swift-1")
        }
        XCTAssertThrowsError(try runtime.askPayload(source: "client", target: "echo", payload: Data(), timeoutMs: 10)) { error in
            guard case RuntimeError.timeout = error else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try runtime.askPayload(source: "bad\0name", target: "echo", payload: Data())) { error in
            guard case RuntimeError.invalidArgument = error else { return XCTFail("\(error)") }
        }
        XCTAssertEqual(runtime.session.borrowedAsks, 0)
        try runtime.close()
    }

    func testRegistrationBoundAndDuplicate() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        for i in 0..<256 { try runtime.registerPayloadHandler("target-\(i)") { $0 } }
        XCTAssertThrowsError(try runtime.registerPayloadHandler("target-0") { $0 })
        XCTAssertThrowsError(try runtime.registerPayloadHandler("overflow") { $0 }) { error in
            guard case RuntimeError.resourceLimit = error else { return XCTFail("\(error)") }
        }
        let other = try host("bytes")
        defer { try? other.close() }
        try other.registerPayloadHandler(String(repeating: "a", count: 64 * 1024)) { $0 }
        XCTAssertThrowsError(try other.registerPayloadHandler("b") { $0 })
        try runtime.close(); try other.close()
    }

    func testAskSaturationStopAndBorrowerRetention() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        var tickets: [NativeAskTicket] = []
        for _ in 0..<64 {
            tickets.append(try runtime.beginAsk(source: "client", target: "echo", payload: Data(), timeoutMs: 2000, hint: .routerDefault))
        }
        XCTAssertEqual(runtime.session.borrowedAsks, 64)
        XCTAssertThrowsError(try runtime.beginAsk(source: "client", target: "echo", payload: Data(), timeoutMs: 2000, hint: .routerDefault)) { error in
            guard case RuntimeError.resourceLimit = error else { return XCTFail("\(error)") }
        }
        // Admission is not host handoff. If stop races undelivered local jobs,
        // Core correctly returns runtime_stopped deadletters, not CLOSED.
        // Establish this fixture's unanswered-but-dispatched state first;
        // all64 CLOSED assertions and existing close/test bounds stay intact.
        let handoffDeadline = DispatchTime.now() + .seconds(1)
        while runtime.clientStats().deliveredRequests < 64 && DispatchTime.now() < handoffDeadline {
            Thread.sleep(forTimeInterval: 0.001)
        }
        XCTAssertEqual(runtime.clientStats().deliveredRequests, 64, "all requests must cross the actual Core reader before stop")
        XCTAssertThrowsError(try runtime.close()) { error in
            guard case RuntimeError.shutdown = error else { return XCTFail("\(error)") }
        }
        XCTAssertEqual(runtime.session.borrowedAsks, 64)
        // Core is stopped but the client is alive until these exclusive owners
        // observe CLOSED and destroy every ticket. No native pointer is reused.
        for ticket in tickets {
            XCTAssertThrowsError(try {
                let result = try ticket.awaitResult(timeoutMs: 0, payloadOnly: true)
                if result.kind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER) {
                    let value = try RuntimeEnvelopeCodec.decodeDeadletter(result.bytes,
                        reasonName: { try coreDeadletterReasonName(runtime.session.handle, $0) })
                    print("SATURATION_UNEXPECTED_TERMINAL kind=\(result.kind) reason=\(value.reasonCode):\(value.reason)")
                } else { print("SATURATION_UNEXPECTED_TERMINAL kind=\(result.kind) bytes=\(result.bytes.count)") }
                return result
            }()) { error in
                guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("\(error)") }
                XCTAssertEqual(status, -7)
            }
        }
        XCTAssertEqual(runtime.session.borrowedAsks, 0)
        try runtime.close()
    }

    func testReentrantCloseRefusesBeforeMutation() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        try runtime.registerPayloadHandler("echo") { [weak runtime] payload in
            guard let runtime else { throw RuntimeError.closed }
            do { try runtime.close(); XCTFail("reentrant close succeeded") }
            catch RuntimeError.shutdown { }
            XCTAssertEqual(try runtime.startupConfig().runtimeState, .started)
            return payload
        }
        XCTAssertEqual(try runtime.askPayload(source: "client", target: "echo", payload: Data([1]), timeoutMs: 2000), Data([1]))
        XCTAssertEqual(try runtime.askPayload(source: "client", target: "echo", payload: Data([2]), timeoutMs: 2000), Data([2]))
        try runtime.close()
    }

    func testFailedReaderJoinRetainsOwnerAndAllowsRetry() throws {
        let runtime = try host()
        let entered = DispatchSemaphore(value: 0), release = DispatchSemaphore(value: 0)
        let done = DispatchGroup(), result = LockedResult()
        defer { release.signal(); try? runtime.close() }
        try runtime.registerPayloadHandler("echo") { payload in entered.signal(); release.wait(); return payload }
        done.enter()
        DispatchQueue.global().async {
            defer { done.leave() }
            do { _ = try runtime.askPayload(source: "client", target: "echo", payload: Data(), timeoutMs: 2000); result.fail("ask unexpectedly completed") }
            catch RuntimeError.nativeStatus(let status, _) { if status != -7 { result.fail("unexpected native status \(status)") } }
            catch { result.fail("unexpected error \(error)") }
        }
        XCTAssertEqual(entered.wait(timeout: .now() + 2), .success)
        XCTAssertThrowsError(try runtime.close()) { error in
            guard case RuntimeError.shutdown = error else { return XCTFail("\(error)") }
        }
        XCTAssertEqual(runtime.session.borrowedAsks, 1)
        XCTAssertThrowsError(try runtime.startupConfig())
        release.signal()
        XCTAssertEqual(done.wait(timeout: .now() + 2), .success)
        XCTAssertNil(result.error)
        try runtime.close()
    }

    func testConcurrentInspectionAndClose() throws {
        let runtime = try host()
        let done = DispatchGroup(), result = LockedResult()
        for _ in 0..<4 {
            done.enter()
            DispatchQueue.global().async {
                defer { done.leave() }
                for _ in 0..<100 {
                    do { _ = try runtime.runtimeConfig(); _ = try runtime.startupConfig(); _ = try runtime.tcpConnectionConfig() }
                    catch RuntimeError.closed { return }
                    catch { result.fail("\(error)"); return }
                }
            }
        }
        try runtime.close()
        XCTAssertEqual(done.wait(timeout: .now() + 2), .success)
        XCTAssertNil(result.error)
        try runtime.close()
    }

    func testIndependentHostsAndARCRetirement() throws {
        for round in 0..<20 {
            var a: RuntimeHost? = try host("a-\(round)")
            let b = try host("b-\(round)")
            try a!.registerPayloadHandler("echo") { $0 }
            try b.registerPayloadHandler("echo") { $0 }
            XCTAssertEqual(try a!.askPayload(source: "a", target: "echo", payload: Data([1]), timeoutMs: 2000), Data([1]))
            XCTAssertEqual(try b.askPayload(source: "b", target: "echo", payload: Data([2]), timeoutMs: 2000), Data([2]))
            let releasedHost = WeakHost(a!)
            let session = a!.session
            a = nil // no explicit close; session's runner retires its native owners
            XCTAssertNil(releasedHost.value)
            XCTAssertTrue(session.waitRetired(timeout: .now() + 1))
            XCTAssertEqual(try b.askPayload(source: "b", target: "echo", payload: Data([3]), timeoutMs: 2000), Data([3]))
            try b.close()
        }
    }

    func testAsyncPayloadAndCooperativeTaskCancellation() async throws {
        let runtime = try host()
        defer { try? runtime.close() }
        try runtime.registerPayloadHandler("echo") { $0 }
        let value = try await runtime.askPayloadAsync(source: "client", target: "echo", payload: Data([7]), timeoutMs: 2000)
        XCTAssertEqual(value, Data([7]))
        let entered = DispatchSemaphore(value: 0), release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        // Route is Core-owned: a separate host with this route avoids mutating a
        // local matcher/route cache for test synchronization.
        let blocked = try RuntimeHost.start(ConnectorStartSpec(systemName: "cancel", nodeID: "cancel", routes: [.local("blocked")]))
        defer { try? blocked.close() }
        try blocked.registerPayloadHandler("blocked") { payload in entered.signal(); release.wait(); return payload }
        let task = Task.detached { try await blocked.askPayloadAsync(source: "client", target: "blocked", payload: Data(), timeoutMs: 2000) }
        XCTAssertEqual(entered.wait(timeout: .now() + 2), .success)
        task.cancel()
        release.signal()
        do { _ = try await task.value; XCTFail("cancelled task returned success") }
        catch is CancellationError { }
        XCTAssertEqual(blocked.session.borrowedAsks, 0)
        try blocked.close(); try runtime.close()
    }

    func testBoundedValueProjectionFuzz() throws {
        let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: nil))
        let bad: [Data] = [Data([0x0a] + Array(repeating: 0xff, count: 9) + [0x02]),
            Data([0x0a, 0x7f]), Data([0]), Data([0x0a, 0x01, 0xff])]
        for bytes in bad { XCTAssertThrowsError(try RuntimeEnvelopeCodec.decodeEnvelope(bytes)) }
        var seed: UInt64 = 0x51_46_54
        for i in 0..<1000 {
            var bytes = Data()
            for _ in 0..<(i % 257) {
                seed = seed &* 6364136223846793005 &+ 1
                bytes.append(UInt8(truncatingIfNeeded: seed >> 32))
            }
            _ = try? RuntimeEnvelopeCodec.decodeEnvelope(bytes)
            _ = try? RuntimeEnvelopeCodec.decodeDeadletter(bytes, reasonName: library.deadletterReasonName)
        }
    }

    func testAsyncExecutorHasEightIndependentBoundedLanes() {
        let entered = DispatchSemaphore(value: 0), release = DispatchSemaphore(value: 0), done = DispatchGroup()
        for _ in 0..<8 {
            done.enter()
            RuntimeAskExecutor.enqueue { entered.signal(); release.wait(); done.leave() }
        }
        defer { for _ in 0..<8 { release.signal() } }
        for _ in 0..<8 { XCTAssertEqual(entered.wait(timeout: .now() + 2), .success) }
        for _ in 0..<8 { release.signal() }
        XCTAssertEqual(done.wait(timeout: .now() + 2), .success)
    }

    func testDispatchProjectionDoesNotCacheMissingHandler() throws {
        let runtime = try host()
        defer { try? runtime.close() }
        XCTAssertThrowsError(try runtime.askPayload(source: "client", target: "echo", payload: Data(), timeoutMs: 10))
        try runtime.registerPayloadHandler("echo") { $0 }
        for _ in 0..<3 { XCTAssertEqual(try runtime.askPayload(source: "client", target: "echo", payload: Data([1]), timeoutMs: 2000), Data([1])) }
        try runtime.close()
    }
}

private final class LockedResult: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?
    func fail(_ error: String) { lock.lock(); if value == nil { value = error }; lock.unlock() }
    var error: String? { lock.lock(); defer { lock.unlock() }; return value }
}
