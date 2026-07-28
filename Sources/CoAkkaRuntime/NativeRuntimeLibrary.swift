import CoAkkaRuntimeC
import Foundation

final class NativeRuntimeLibrary {
    private(set) var handle: OpaquePointer?
    let path: String

    init(path: String) throws {
        self.path = path
        var opened: OpaquePointer?
        var error = [CChar](repeating: 0, count: 512)
        let status = path.withCString { cPath in
            coakka_swift_runtime_library_open(cPath, &opened, &error, error.count)
        }
        guard status == Int32(COAKKA_SWIFT_OK), let opened else {
            let message = error.prefix { $0 != 0 }
            throw RuntimeError.loadFailed(String(decoding: message.map { UInt8(bitPattern: $0) }, as: UTF8.self))
        }
        handle = opened
    }

    deinit {
        close()
    }

    func close() {
        if let handle {
            coakka_swift_runtime_library_close(handle)
            self.handle = nil
        }
    }

    func requireHandle() throws -> OpaquePointer {
        guard let handle else {
            throw RuntimeError.closed
        }
        return handle
    }
}

func runtimeNativePath(explicitPath: String?) throws -> String {
    if let explicitPath, !explicitPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return explicitPath
    }
    if let envPath = ProcessInfo.processInfo.environment["COAKKA_RUNTIME_NATIVE_PATH"],
       !envPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return envPath
    }
    guard let url = Bundle.module.url(
        forResource: "libcoakka_runtime_v2",
        withExtension: "dylib",
        subdirectory: "Resources/macos-aarch64"
    ) else {
        throw RuntimeError.loadFailed("Bundled CoAkka runtime library is missing")
    }
    return url.path
}

func nativeString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

func throwIfNativeError(_ status: Int32, operation: String) throws {
    guard status == Int32(COAKKA_SWIFT_STATUS_OK) else {
        throw RuntimeError.nativeStatus(status, operation)
    }
}

func toRuntimeState(_ value: Int32) -> RuntimeState {
    switch value {
    case Int32(COAKKA_SWIFT_STATE_CREATED):
        return .created
    case Int32(COAKKA_SWIFT_STATE_STARTED):
        return .started
    case Int32(COAKKA_SWIFT_STATE_STOPPED):
        return .stopped
    default:
        return .unknown(Int(value))
    }
}
