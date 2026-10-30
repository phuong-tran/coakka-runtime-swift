import CoAkkaRuntimeC
import Foundation

final class NativeRuntimeLibrary {
    private static let processLock = NSLock()
    nonisolated(unsafe) private static var processHandle: OpaquePointer?
    nonisolated(unsafe) private static var processPath: String?

    private(set) var handle: OpaquePointer?
    let path: String

    init(path: String) throws {
        try validateCString(path, name: "runtime library path")
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

    func deadletterReasonName(_ reason: UInt32) throws -> String {
        try coreDeadletterReasonName(requireHandle(), reason)
    }
}

// The module (unlike an instance/wrapper) is retained for the process lifetime.
// Completed ask projection may therefore copy this fact after session retirement.
func coreDeadletterReasonName(_ module: OpaquePointer, _ reason: UInt32) throws -> String {
    guard let pointer = coakka_swift_deadletter_reason_name(module, reason) else {
        throw RuntimeError.contractViolation("Core did not provide a deadletter reason name")
    }
    return String(cString: pointer)
}

// Only use after an actual OK constructor status. A missing success output is
// a broken boundary contract, not evidence that Core reported allocation failure.
func requireCoreOwner(_ value: OpaquePointer?, operation: String) throws -> OpaquePointer {
    guard let value else {
        throw RuntimeError.contractViolation("Core accepted \(operation) without an owner")
    }
    return value
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
#elseif os(Linux) && arch(x86_64)
    let resourcePlatform = "linux-x86_64"
    let resourceExtension = "so"
#elseif os(Windows) && arch(arm64)
    let resourcePlatform = "windows-aarch64"
    let resourceExtension = "dll"
#elseif os(Windows) && arch(x86_64)
    let resourcePlatform = "windows-x86_64"
    let resourceExtension = "dll"
#else
    throw RuntimeError.loadFailed("No bundled CoAkka runtime matches this OS and CPU architecture")
#endif
    #if os(macOS)
    let bundleName = "coakka-v2-runtime-swift_CoAkkaRuntime.bundle"
    #else
    let bundleName = "coakka-v2-runtime-swift_CoAkkaRuntime.resources"
    #endif
    // Artifact loading is the only OS/filesystem selection owned here. Avoid
    // SwiftPM's generated absolute build-tree fallback in shipped code. The
    // application deploys the product resource bundle adjacent to its executable
    // (or in its app resources), just as it deploys its language runtime.
    let roots = [Bundle.main.bundleURL, Bundle.main.resourceURL].compactMap { $0 }
    for root in roots {
        let path = root.appendingPathComponent(bundleName)
            .appendingPathComponent("Resources/\(resourcePlatform)/libcoakka_runtime_v2.\(resourceExtension)")
        if FileManager.default.fileExists(atPath: path.path) { return path.path }
    }
    #if DEBUG
    // Development/sanitizer products remain diagnosable and may use SwiftPM's
    // build-tree resources. The release compiler never references this accessor.
    if let url = Bundle.module.url(forResource: "libcoakka_runtime_v2", withExtension: resourceExtension,
        subdirectory: "Resources/\(resourcePlatform)") { return url.path }
    #endif
    throw RuntimeError.loadFailed("Bundled CoAkka runtime library is missing for \(resourcePlatform)")
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

func requireCoreFeature(_ handle: OpaquePointer,
    query: (OpaquePointer?, UnsafeMutablePointer<UInt32>?) -> Int32, operation: String) throws {
    var compiled: UInt32 = 0
    try throwIfNativeError(query(handle, &compiled), operation: operation)
    guard compiled <= 1 else { throw RuntimeError.contractViolation("Core feature projection is not boolean") }
    guard compiled == 1 else { throw RuntimeError.nativeStatus(Int32(COAKKA_V2_ERR_FEATURE_UNAVAILABLE.rawValue), operation) }
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

func toRuntimeState(_ value: UInt32) -> RuntimeState {
    switch value {
    case 0: return .created
    case 1: return .started
    case 2: return .stopped
    default: return .unknown(Int(value))
    }
}
