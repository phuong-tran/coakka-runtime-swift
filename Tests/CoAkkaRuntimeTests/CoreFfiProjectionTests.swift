import CoAkkaRuntimeC
import Foundation
import XCTest
@testable import CoAkkaRuntime

final class CoreFfiProjectionTests: XCTestCase {
    func testCStringProjectionIsLosslessOrRefused() throws {
        for bad in ["\0", "prefix\0suffix", "😺\0"] {
            XCTAssertThrowsError(try NativeCStringStorage(["first", bad, "last"]))
        }
        let strings = try NativeCStringStorage(["", "Đường dẫn/😺", " "])
        XCTAssertEqual(String(cString: strings[0]), "")
        XCTAssertEqual(String(cString: strings[1]), "Đường dẫn/😺")
        XCTAssertEqual(String(cString: strings[2]), " ")
    }

    func testEmbeddedNulCannotAliasAnotherLaneRecordOrPath() throws {
        func refused(_ body: () throws -> Void) {
            XCTAssertThrowsError(try body()) { error in
                guard case RuntimeError.invalidArgument = error else { return XCTFail("NUL crossed C boundary") }
            }
        }
        let bad = "prefix\0suffix"
        var fileConfig = FileLaneConfig(); fileConfig.bindHost = bad
        refused { _ = try FileLane.open(fileConfig) }
        var streamConfig = StreamLaneConfig(); streamConfig.bindHost = bad
        refused { _ = try StreamLane.open(streamConfig) }
        refused { _ = try FileLane.sha256(path: bad) }
        let file = try FileLane.open()
        defer { try? file.close() }
        refused { _ = try file.transfer(bad, direction: .receive) }
        refused { try file.cancel(bad, direction: .send) }
        refused { try file.prepareReceive(FileReceiveSpec(transferID: "test", authorizationToken: "token",
            destinationPath: bad, expectedSize: 0, expectedSHA256: Data(repeating: 0, count: 32))) }
        XCTAssertEqual(try file.stats().preparedReceiveCount, 0)
        let stream = try StreamLane.open()
        defer { try? stream.close() }
        refused { _ = try stream.session(bad, direction: .publish) }
        refused { _ = try stream.pressure(bad, direction: .subscribe) }
        refused { try stream.forget(bad, direction: .publish) }
        refused { try stream.preparePublish(StreamPublishSpec(sessionID: bad, authorizationToken: "token",
            formatID: 1, maxFrameBytes: 1024) { _ in XCTFail("refused callback invoked"); return .end }) }
        refused { try stream.subscribe(StreamSubscribeSpec(sessionID: "test", authorizationToken: "token",
            remoteHost: bad, remotePort: 1, formatID: 1, maxFrameBytes: 1024, initialWindowBytes: 1024) { _, _ in
                XCTFail("refused callback invoked"); return .continue
            }) }
        XCTAssertEqual(try stream.stats().preparedPublisherCount, 0)
    }

    func testCoreRefusalReleasesCallbackBorrow() throws {
        let lane = try StreamLane.open()
        defer { try? lane.close() }
        final class Capture: Sendable {}
        weak var released: Capture?
        do {
            let capture = Capture(); released = capture
            let spec = StreamPublishSpec(sessionID: "bad-frame", authorizationToken: "token", formatID: 1,
                maxFrameBytes: UInt32.max) { [capture] _ in _ = capture; return .end }
            XCTAssertThrowsError(try lane.preparePublish(spec)) { error in
                guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("Core frame refusal was mirrored") }
                XCTAssertEqual(status, -1)
            }
        }
        XCTAssertNil(released, "failed Core admission retained callback")
    }

    func testInspectionFailureIsNotAnUnsupportedFact() throws {
        let handle = try XCTUnwrap(OpaquePointer(bitPattern: 1))
        for status: Int32 in [-2, -5, 42] {
            XCTAssertThrowsError(try requireCoreFeature(handle, query: { _, output in
                output?.pointee = 1
                return status
            }, operation: "projection-test")) { error in
                guard case RuntimeError.nativeStatus(let actual, _) = error else {
                    return XCTFail("Core inspection status was reclassified")
                }
                XCTAssertEqual(actual, status)
            }
        }
        XCTAssertThrowsError(try requireCoreFeature(handle, query: { _, output in
            output?.pointee = 2; return 0
        }, operation: "projection-test")) { error in
            guard case RuntimeError.contractViolation = error else { return XCTFail("invalid boolean accepted") }
        }
    }

    func testLaneRefusalComesFromCore() throws {
        var file = FileLaneConfig()
        file.senderWorkerCount = UInt32.max
        XCTAssertThrowsError(try FileLane.open(file)) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("connector duplicated Core refusal") }
            XCTAssertEqual(status, -1)
        }
        var stream = StreamLaneConfig()
        stream.flags = []
        XCTAssertThrowsError(try StreamLane.open(stream)) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("connector duplicated Core refusal") }
            XCTAssertEqual(status, -1)
        }
    }

    func testCapacityUsesAcceptedCorePolicy() throws {
        let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: nil))
        let handle = try library.requireHandle()
        var input = coakka_swift_stream_config_t()
        input.struct_size = MemoryLayout.size(ofValue: input)
        input.flags = StreamLaneFlags.subscriber.rawValue
        input.capacity = 65
        var native: OpaquePointer?
        try "127.0.0.1".withCString { host in
            input.bind_host = host
            try throwIfNativeError(coakka_swift_stream_create(handle, &input, &native), operation: "direct Core create")
        }
        let direct = try XCTUnwrap(native)
        defer { coakka_swift_stream_destroy(handle, direct) }
        var stats = coakka_swift_stream_stats_t()
        try throwIfNativeError(coakka_swift_stream_stats(handle, direct, &stats), operation: "direct Core stats")
        var config = StreamLaneConfig()
        config.flags = [.subscriber]
        config.capacity = 65
        let lane = try StreamLane.open(config)
        defer { try? lane.close() }
        XCTAssertEqual(try lane.stats().capacity, stats.capacity)
    }
}
