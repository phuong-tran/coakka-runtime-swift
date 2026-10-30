import CoAkkaRuntimeC
import Foundation

/// The lock owns pointer admission and retirement. The request queue alone owns
/// reader/read/frame release; each ask borrower alone owns its ticket. Native
/// await never holds the lock. These disjoint owners justify unchecked Sendable.
final class RuntimeSession: @unchecked Sendable {
    let library: NativeRuntimeLibrary
    let handle: OpaquePointer
    let lock = NSLock()
    private(set) var runtime: OpaquePointer?
    let client: OpaquePointer
    private var handles: coakka_swift_host_handles_t
    private let reader: OpaquePointer
    private let queue = DispatchQueue(label: "CoAkka.Runtime.requests")
    private let queueKey = DispatchSpecificKey<UInt8>()
    private let readerDone = DispatchGroup()
    private let retirementDone = DispatchGroup()
    private let closeLock = NSLock()
    private var closing = false
    private var readerRetired = false
    private var stopped = false
    private var activeAsks = 0
    private var stopFailure: Int32?
    private var readFailure: RuntimeError?
    private var failedStopOwner: RuntimeSession?

    init(library: NativeRuntimeLibrary, handle: OpaquePointer, runtime: OpaquePointer,
         client: OpaquePointer, handles: coakka_swift_host_handles_t, reader: OpaquePointer) {
        self.library = library
        self.handle = handle
        self.runtime = runtime
        self.client = client
        self.handles = handles
        self.reader = reader
        queue.setSpecific(key: queueKey, value: 1)
        readerDone.enter()
        retirementDone.enter()
    }

    func start(_ dispatch: @escaping @Sendable (UnsafePointer<UInt8>, Int) -> Void) {
        // The runner retains the session, not RuntimeHost. A host released on its
        // own callback requests retirement without self-joining or freeing it.
        queue.async { [self] in
            defer {
                coakka_swift_request_reader_destroy(handle, reader)
                lock.lock()
                readerRetired = true
                closing = true
                stopLocked()
                retireLocked()
                lock.unlock()
                readerDone.leave()
            }
            while !isClosing {
                var frame: OpaquePointer?
                let status = coakka_swift_request_reader_read(handle, reader, 100, &frame)
                defer { if let frame { coakka_swift_owned_frame_release(handle, frame) } }
                if status == Int32(COAKKA_SWIFT_STATUS_WOULD_BLOCK) { continue }
                if status == Int32(COAKKA_SWIFT_STATUS_CLOSED) { break }
                guard status == 0, let frame,
                      let data = coakka_swift_owned_frame_data(handle, frame) else {
                    lock.lock()
                    readFailure = status == 0 ? .contractViolation("Core returned success without readable frame bytes") : .nativeStatus(status, "read delivered request")
                    lock.unlock()
                    break
                }
                let size = coakka_swift_owned_frame_size(handle, frame)
                guard size > 0 else {
                    lock.lock(); readFailure = .contractViolation("Core returned an empty delivered frame"); lock.unlock()
                    break
                }
                dispatch(data, size)
            }
        }
    }

    var isClosing: Bool {
        lock.lock()
        defer { lock.unlock() }
        return closing
    }

    var readerFailure: RuntimeError? {
        lock.lock()
        defer { lock.unlock() }
        return readFailure
    }

    func requireOpenLocked() throws -> OpaquePointer {
        guard !closing, let runtime else { throw RuntimeError.closed }
        return runtime
    }

    func withOpen<T>(_ operation: (OpaquePointer) throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation(requireOpenLocked())
    }

    func begin(_ frame: UnsafePointer<UInt8>?, count: Int) throws -> OpaquePointer {
        lock.lock()
        defer { lock.unlock() }
        _ = try requireOpenLocked()
        guard activeAsks < 64 else { throw RuntimeError.resourceLimit("64 active asks exhausted") }
        var ticket: OpaquePointer?
        try throwIfNativeError(coakka_swift_ask_client_begin(handle, client, frame, count, &ticket), operation: "begin ask")
        guard let ticket else { throw RuntimeError.contractViolation("Core returned success without an ask ticket") }
        activeAsks += 1
        return ticket
    }

    func endBorrow() {
        lock.lock()
        activeAsks -= 1
        retireLocked()
        lock.unlock()
    }

    var borrowedAsks: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeAsks
    }

    // Private test seam for ARC retirement, not an inferred public runtime state.
    func waitRetired(timeout: DispatchTime) -> Bool {
        retirementDone.wait(timeout: timeout) == .success
    }

    func requestRetirement() {
        lock.lock()
        closing = true
        lock.unlock()
    }

    /// Failure preserves native owners. The runner or final borrower can finish
    /// retirement later; a caller can retry close. Core stop has its own contract,
    /// not a fabricated whole-operation one-second deadline.
    func close() throws {
        guard DispatchQueue.getSpecific(key: queueKey) == nil else {
            throw RuntimeError.shutdown("close from a request handler is not permitted")
        }
        guard closeLock.try() else { throw RuntimeError.shutdown("close already in progress") }
        defer { closeLock.unlock() }
        requestRetirement()
        guard readerDone.wait(timeout: .now() + 1) == .success else {
            throw RuntimeError.shutdown("request runner did not join within 1000 ms; native owners retained")
        }
        lock.lock()
        if !stopped { stopLocked(); retireLocked() }
        let failure = stopFailure
        lock.unlock()
        if let failure { throw RuntimeError.nativeStatus(failure, "stop runtime; native owners retained") }
        guard retirementDone.wait(timeout: .now() + 1) == .success else {
            throw RuntimeError.shutdown("ask borrowers did not retire within 1000 ms; native owners retained")
        }
    }

    private func stopLocked() {
        guard readerRetired, !stopped, let runtime else { return }
        let status = coakka_swift_runtime_stop(handle, runtime)
        stopFailure = status == 0 ? nil : status
        stopped = status == 0
        // Unexpected stop refusal must not orphan the only recoverable owner if
        // Host is dropped. One retained owner per failed session, no registry.
        failedStopOwner = status == 0 ? nil : self
    }

    private func retireLocked() {
        guard readerRetired, stopped, activeAsks == 0, let runtime else { return }
        coakka_swift_ask_client_destroy(handle, client)
        coakka_swift_host_handles_close(handle, &handles)
        coakka_swift_runtime_destroy(handle, runtime)
        self.runtime = nil
        library.close()
        retirementDone.leave()
    }
}

/// Cancellation intent is a Swift fact, never a concurrent Core ticket call.
final class RuntimeCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
}
