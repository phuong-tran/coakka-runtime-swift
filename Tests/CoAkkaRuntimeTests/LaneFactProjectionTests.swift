import Foundation
import CoAkkaRuntimeC
import XCTest
@testable import CoAkkaRuntime

final class LaneFactProjectionTests: XCTestCase {
    private func project<T: RawRepresentable>(_ type: T.Type, _ value: UInt32) -> UInt32?
        where T.RawValue == UInt32 {
        T(rawValue: value)?.rawValue
    }

    func testFutureScalarsAreLosslessRatherThanNilOrDefault() {
        for value: UInt32 in [0, 65536, .max] {
            XCTAssertEqual(project(FileTransferDirection.self, value), value)
            XCTAssertEqual(project(FileTransferState.self, value), value)
            XCTAssertEqual(project(FileTransferResult.self, value), value)
            XCTAssertEqual(project(StreamDirection.self, value), value)
            XCTAssertEqual(project(StreamState.self, value), value)
            XCTAssertEqual(project(StreamResult.self, value), value)
            XCTAssertEqual(project(StreamPressureState.self, value), value)
        }
    }

    func testEveryKnownSDKNameKeepsItsFrozenNumericIdentity() {
        XCTAssertEqual([FileTransferDirection.send, .receive].map(\.rawValue), [1, 2])
        XCTAssertEqual([StreamDirection.publish, .subscribe].map(\.rawValue), [1, 2])
        XCTAssertEqual([FileTransferState.prepared, .queued, .connecting, .transferring, .verifying,
            .completed, .paused, .rejected, .failed, .canceled].map(\.rawValue), Array(UInt32(1)...10))
        XCTAssertEqual([StreamState.prepared, .queued, .connecting, .active, .stopping,
            .ended, .rejected, .failed, .canceled].map(\.rawValue), Array(UInt32(1)...9))
        XCTAssertEqual([StreamPressureState.inactive, .flowing, .pressured, .stalled, .recovering].map(\.rawValue), Array(UInt32(0)...4))
        XCTAssertEqual([FileTransferResult.none, .ok, .notPrepared, .tokenMismatch, .metadataMismatch,
            .sizeLimit, .storageIO, .integrityMismatch, .networkIO, .timeout, .queueFull, .protocolError,
            .sourceChanged, .internalError, .canceledByHost, .tlsConfigInvalid, .tlsHandshakeFailed,
            .peerCertUntrusted, .peerCertExpired, .peerIdentityMismatch, .clientCertRequired].map(\.rawValue), Array(UInt32(0)...20))
        XCTAssertEqual([StreamResult.none, .ok, .notPrepared, .tokenMismatch, .formatMismatch, .frameLimit,
            .networkIO, .timeout, .queueFull, .protocolError, .sourceError, .consumerError, .internalError,
            .canceledByHost, .tlsConfigInvalid, .tlsHandshakeFailed, .peerCertUntrusted, .peerCertExpired,
            .peerIdentityMismatch, .clientCertRequired].map(\.rawValue), Array(UInt32(0)...19))
        XCTAssertEqual(MemoryLayout<StreamState>.size, MemoryLayout<UInt32>.size)
        XCTAssertEqual(Set([StreamState(rawValue: .max), StreamState(rawValue: .max)]).count, 1)
    }

    func testPausedIsNotAnObservedCoreTerminalTransition() {
        let snapshot = FileTransferSnapshot(direction: .receive, state: .paused, result: .none,
            expectedSize: 100, transferredBytes: 50, committedOffset: 50, progressMilli: 50000,
            cancelRequested: false, updateSequence: 7, submittedMonoNs: 10, startedMonoNs: 20,
            updatedMonoNs: 30, terminalMonoNs: 0, detail: "paused")
        XCTAssertFalse(snapshot.terminal, "Core explicitly excludes PAUSED from terminal states")
        XCTAssertFalse(snapshot.succeeded)
    }

    func testNativeSnapshotsPreserveFutureFactsAndCoreTerminalMarker() {
        var seed: UInt32 = 401
        func next() -> UInt32 {
            seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
            return seed
        }
        for round in 0..<4096 {
            let direction = next(), state = next(), result = next()
            let marker: UInt64 = round % 2 == 0 ? 0 : UInt64(round + 1)
            var file = coakka_swift_file_transfer_snapshot_t()
            file.direction = direction; file.state = state; file.result = result
            file.expected_size = 100; file.transferred_bytes = 90; file.committed_offset = 80
            file.progress_milli = 90000; file.cancel_requested = 1; file.update_sequence = 71
            file.submitted_mono_ns = 10; file.started_mono_ns = 20; file.updated_mono_ns = 30
            file.terminal_mono_ns = marker
            let projectedFile = FileTransferSnapshot(native: file)
            XCTAssertEqual(projectedFile.direction.rawValue, direction)
            XCTAssertEqual(projectedFile.state.rawValue, state)
            XCTAssertEqual(projectedFile.result.rawValue, result)
            XCTAssertEqual(projectedFile.terminal, marker != 0)
            XCTAssertEqual(projectedFile.terminalMonoNs, marker)
            XCTAssertEqual(projectedFile.expectedSize, 100)
            XCTAssertEqual(projectedFile.transferredBytes, 90)
            XCTAssertEqual(projectedFile.committedOffset, 80)
            XCTAssertEqual(projectedFile.updateSequence, 71)
            XCTAssertTrue(projectedFile.cancelRequested)

            var session = coakka_swift_stream_session_snapshot_t()
            session.direction = direction; session.state = state; session.result = result
            session.format_id = 41; session.frames = 42; session.bytes = 43
            session.dropped_frames = 44; session.last_sequence = 45
            session.negotiated_max_frame_bytes = 46; session.window_bytes = 47
            session.terminal_mono_ns = marker
            let projectedSession = StreamSessionSnapshot(native: session)
            XCTAssertEqual(projectedSession.direction.rawValue, direction)
            XCTAssertEqual(projectedSession.state.rawValue, state)
            XCTAssertEqual(projectedSession.result.rawValue, result)
            XCTAssertEqual(projectedSession.terminal, marker != 0)
            XCTAssertEqual(projectedSession.formatID, 41)
            XCTAssertEqual(projectedSession.frames, 42)
            XCTAssertEqual(projectedSession.bytes, 43)
            XCTAssertEqual(projectedSession.droppedFrames, 44)
            XCTAssertEqual(projectedSession.lastSequence, 45)
            XCTAssertEqual(projectedSession.negotiatedMaxFrameBytes, 46)
            XCTAssertEqual(projectedSession.windowBytes, 47)

            var pressure = coakka_swift_stream_pressure_snapshot_t()
            pressure.direction = direction; pressure.state = state; pressure.reason_bits = result
            pressure.current_operation_ns = 51; pressure.last_operation_ns = 52
            pressure.total_pressured_ns = 53; pressure.max_pressured_ns = 54
            let projectedPressure = StreamPressureSnapshot(native: pressure)
            XCTAssertEqual(projectedPressure.direction.rawValue, direction)
            XCTAssertEqual(projectedPressure.state.rawValue, state)
            XCTAssertEqual(projectedPressure.reasons.rawValue, result)
            XCTAssertEqual(projectedPressure.currentOperationNs, 51)
            XCTAssertEqual(projectedPressure.lastOperationNs, 52)
            XCTAssertEqual(projectedPressure.totalPressuredNs, 53)
            XCTAssertEqual(projectedPressure.maxPressuredNs, 54)
        }
    }

    func testRecognizedSuccessRequiresCoreMarkerAndKnownOutcome() {
        var file = coakka_swift_file_transfer_snapshot_t()
        file.state = FileTransferState.completed.rawValue; file.result = FileTransferResult.ok.rawValue
        XCTAssertFalse(FileTransferSnapshot(native: file).succeeded)
        file.terminal_mono_ns = 1
        XCTAssertTrue(FileTransferSnapshot(native: file).succeeded)
        file.result = .max
        XCTAssertFalse(FileTransferSnapshot(native: file).succeeded)
        file.state = .max; file.result = FileTransferResult.ok.rawValue
        XCTAssertFalse(FileTransferSnapshot(native: file).succeeded)
        var session = coakka_swift_stream_session_snapshot_t()
        session.state = StreamState.ended.rawValue; session.result = StreamResult.ok.rawValue
        XCTAssertFalse(StreamSessionSnapshot(native: session).succeeded)
        session.terminal_mono_ns = 1
        XCTAssertTrue(StreamSessionSnapshot(native: session).succeeded)
        session.result = .max
        XCTAssertFalse(StreamSessionSnapshot(native: session).succeeded)
    }

    func testFixedDetailHasNoUnboundedCStringRead() {
        var file = coakka_swift_file_transfer_snapshot_t()
        _ = withUnsafeMutableBytes(of: &file.detail) { $0.initializeMemory(as: UInt8.self, repeating: 0x78) }
        XCTAssertEqual(FileTransferSnapshot(native: file).detail, String(repeating: "x", count: MemoryLayout.size(ofValue: file.detail)))
        var session = coakka_swift_stream_session_snapshot_t()
        _ = withUnsafeMutableBytes(of: &session.detail) { $0.initializeMemory(as: UInt8.self, repeating: 0xFF) }
        XCTAssertEqual(StreamSessionSnapshot(native: session).detail.count, MemoryLayout.size(ofValue: session.detail))
    }

    func testUnknownDirectionReachesCoreAdmissionUnchanged() throws {
        let lane = try StreamLane.open()
        defer { try? lane.close() }
        XCTAssertThrowsError(try lane.session("unknown-direction", direction: StreamDirection(rawValue: .max))) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("direction policy mirrored") }
            XCTAssertEqual(status, -1)
        }
        let file = try FileLane.open()
        defer { try? file.close() }
        XCTAssertThrowsError(try file.transfer("unknown-direction", direction: FileTransferDirection(rawValue: .max))) { error in
            guard case RuntimeError.nativeStatus(let status, _) = error else { return XCTFail("File direction policy mirrored") }
            XCTAssertEqual(status, -1)
        }
    }
}
