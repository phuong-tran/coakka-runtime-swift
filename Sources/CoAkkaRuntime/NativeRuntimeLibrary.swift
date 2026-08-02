import CoAkkaRuntimeC
import Foundation

final class NativeRuntimeLibrary {
    private static let processLock = NSLock()
    nonisolated(unsafe) private static var processHandle: OpaquePointer?
    nonisolated(unsafe) private static var processPath: String?

    private(set) var handle: OpaquePointer?
    let path: String

    init(path: String) throws {
        let canonicalPath = URL(fileURLWithPath: path)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
        self.path = canonicalPath

        Self.processLock.lock()
        defer {
            Self.processLock.unlock()
        }
        if let processHandle = Self.processHandle, let processPath = Self.processPath {
#if os(Windows)
            let samePath = processPath.caseInsensitiveCompare(canonicalPath) == .orderedSame
#else
            let samePath = processPath == canonicalPath
#endif
            guard samePath else {
                throw RuntimeError.loadFailed(
                    "A different CoAkka runtime library is already loaded in this process: \(processPath)"
                )
            }
            handle = processHandle
            return
        }

        var opened: OpaquePointer?
        var error = [CChar](repeating: 0, count: 512)
        let status = canonicalPath.withCString { cPath in
            coakka_swift_runtime_library_open(cPath, &opened, &error, error.count)
        }
        guard status == Int32(COAKKA_SWIFT_OK), let opened else {
            let message = error.prefix { $0 != 0 }
            throw RuntimeError.loadFailed(String(decoding: message.map { UInt8(bitPattern: $0) }, as: UTF8.self))
        }
        handle = opened
        Self.processHandle = opened
        Self.processPath = canonicalPath
    }

    deinit {
        close()
    }

    func close() {
        handle = nil
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
    for variable in ["COAKKA_RUNTIME_LIB", "COAKKA_RUNTIME_NATIVE_PATH"] {
        if let envPath = ProcessInfo.processInfo.environment[variable],
           !envPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envPath
        }
    }
#if os(macOS) && arch(arm64)
    let resourcePlatform = "macos-aarch64"
    let resourceExtension = "dylib"
#elseif os(Linux) && arch(arm64)
    let resourcePlatform = "linux-aarch64"
    let resourceExtension = "so"
#elseif os(Windows) && arch(x86_64)
    let resourcePlatform = "windows-x86_64"
    let resourceExtension = "dll"
#else
    throw RuntimeError.loadFailed("No bundled CoAkka runtime matches this OS and CPU architecture")
#endif
    guard let url = Bundle.module.url(
        forResource: "libcoakka_runtime_v2",
        withExtension: resourceExtension,
        subdirectory: "Resources/\(resourcePlatform)"
    ) else {
        throw RuntimeError.loadFailed(
            "Bundled CoAkka runtime library is missing for \(resourcePlatform)"
        )
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
