import CoAkkaRuntimeC
import XCTest
@testable import CoAkkaRuntime

final class StartupQueueDefaultsTests: XCTestCase {
    private enum CleanupFailure: Error { case operationAndClose(any Error, any Error) }

    private func direct(_ capacity: Int32) throws -> coakka_swift_startup_config_t {
        let library = try NativeRuntimeLibrary(path: runtimeNativePath(explicitPath: nil))
        let handle = try library.requireHandle()
        var output: OpaquePointer?
        try "queue-control".withCString { system in
            try "queue-control".withCString { node in
                try throwIfNativeError(coakka_swift_runtime_create_native(handle, system, node, 1, capacity, nil, &output),
                    operation: "direct queue control")
            }
        }
        let runtime = try XCTUnwrap(output)
        defer { coakka_swift_runtime_destroy(handle, runtime) }
        var snapshot = coakka_swift_startup_config_t()
        snapshot.struct_size = MemoryLayout.size(ofValue: snapshot)
        try throwIfNativeError(coakka_swift_runtime_get_startup_config(handle, runtime, &snapshot), operation: "direct queue snapshot")
        return snapshot
    }

    private func projected(_ create: () throws -> RuntimeHost) throws -> (Int32, RuntimeStartupSnapshot) {
        let host = try create()
        let outcome = Result { (host.startSpec.queueCapacity, try host.startupConfig()) }
        do { try host.close() }
        catch {
            if case .failure(let primary) = outcome { throw CleanupFailure.operationAndClose(primary, error) }
            throw error
        }
        return try outcome.get()
    }

    func testOmittedQueueUsesCoreDefault() throws {
        let expected = try direct(0)
        let constructor = try projected {
            try RuntimeHost.start(ConnectorStartSpec(systemName: "constructor", nodeID: "constructor", routes: []))
        }
        let helper = try projected { try RuntimeHost.startLocal(systemName: "helper", target: "echo") }
        // Native controls and both host owners retire before the omission oracle.
        for value in [constructor, helper] {
            XCTAssertEqual(value.0, 0, "Omitted intent must reach Core unchanged")
            XCTAssertEqual(value.1.queueCapacity, expected.queue_capacity)
            XCTAssertEqual(value.1.requestMaxFrameSize, expected.request_max_frame_size)
        }
    }

    func testExplicitQueueNormalizationIsCoreOwned() throws {
        for capacity: Int32 in [0, -1, 3, 65, 128, 1024] {
            let expected = try direct(capacity)
            let constructor = try projected {
                try RuntimeHost.start(ConnectorStartSpec(systemName: "explicit", nodeID: "explicit", queueCapacity: capacity, routes: []))
            }
            let helper = try projected { try RuntimeHost.startLocal(systemName: "helper", target: "echo", queueCapacity: capacity) }
            for value in [constructor, helper] {
                XCTAssertEqual(value.0, capacity)
                XCTAssertEqual(value.1.queueCapacity, expected.queue_capacity)
                XCTAssertEqual(value.1.requestMaxFrameSize, expected.request_max_frame_size)
            }
        }
    }
}
