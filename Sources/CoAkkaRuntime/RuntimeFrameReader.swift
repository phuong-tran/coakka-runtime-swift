import CoAkkaRuntimeC
import Foundation

final class RuntimeFrameReader: @unchecked Sendable {
    private let library: NativeRuntimeLibrary
    private var reader: OpaquePointer?
    private let onFrame: @Sendable (Data) -> Void
    private let onError: @Sendable (Error) -> Void
    private let lock = NSLock()
    private let group = DispatchGroup()
    private var running = true

    init(
        library: NativeRuntimeLibrary,
        fd: Int32,
        maxFrameSize: Int = 4 * 1024 * 1024,
        name: String,
        onFrame: @escaping @Sendable (Data) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        self.library = library
        self.onFrame = onFrame
        self.onError = onError
        let handle = try library.requireHandle()
        guard let reader = coakka_swift_frame_reader_create(handle, fd, maxFrameSize) else {
            throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_INVALID_ARG), "create \(name) frame reader")
        }
        self.reader = reader
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.readLoop()
            self?.group.leave()
        }
    }

    func stop() {
        lock.lock()
        running = false
        lock.unlock()
        _ = group.wait(timeout: .now() + 1)
        if let reader, let handle = library.handle {
            coakka_swift_frame_reader_destroy(handle, reader)
            self.reader = nil
        }
    }

    deinit {
        stop()
    }

    private func shouldRun() -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        return running
    }

    private func readLoop() {
        while shouldRun() {
            do {
                try drainAvailableFrames()
            } catch {
                onError(error)
            }
            usleep(5_000)
        }
    }

    private func drainAvailableFrames() throws {
        guard let handle = library.handle, let reader else {
            return
        }
        while shouldRun() {
            var buffer: UnsafeMutablePointer<UInt8>?
            var length = 0
            let status = coakka_swift_frame_read_try(handle, reader, &buffer, &length)
            if status == Int32(COAKKA_SWIFT_STATUS_WOULD_BLOCK) {
                return
            }
            if status == Int32(COAKKA_SWIFT_STATUS_CLOSED) {
                stopFromReader()
                return
            }
            try throwIfNativeError(status, operation: "read runtime frame")
            if let buffer {
                let data = Data(bytes: buffer, count: length)
                coakka_swift_frame_release(handle, buffer)
                onFrame(data)
            }
        }
    }

    private func stopFromReader() {
        lock.lock()
        running = false
        lock.unlock()
    }
}
