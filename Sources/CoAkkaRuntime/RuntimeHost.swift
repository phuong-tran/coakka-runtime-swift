import CoAkkaRuntimeC
import Foundation

public final class RuntimeHost: @unchecked Sendable {
    static let expectedABI: UInt32 = 1
    let session: RuntimeSession
    var library: NativeRuntimeLibrary { session.library }
    let startupConnectionResult: TcpConnectionApplyResult? = nil
    let startupSecurityResult: TcpSecurityApplyResult?
    let clientLock = NSLock()
    private var handlers: [String: Handler] = [:]
    private var registrationBytes = 0
    private var dispatchFailures: UInt64 = 0
    private var lastDispatchFailure: String?
    // Sole request runner owns this immutable projection. Registrations are
    // append-only, so a found handler remains valid. Misses are never cached.
    private struct DispatchProjection {
        let bytes: Data
        let target: String
        let handler: Handler
    }
    private var dispatchProjection: DispatchProjection?
    var nextID: UInt64 = 0
    var deliveredRequests: UInt64 = 0
    var matchedResponses: UInt64 = 0
    var matchedDeadletters: UInt64 = 0

    enum Handler: Sendable {
        case rich(@Sendable (RuntimeRequest) throws -> Data)
        case payload(@Sendable (Data) throws -> Data)
    }

    public let runtimeLibPath: String
    public let startSpec: ConnectorStartSpec

    private init(session: RuntimeSession, spec: ConnectorStartSpec, security: TcpSecurityApplyResult?) {
        self.session = session
        startSpec = spec
        runtimeLibPath = session.library.path
        startupSecurityResult = security
        session.start { [weak self] data, size in self?.dispatchRequest(data, size: size) }
    }

    deinit { session.requestRetirement() }

    public static func start(_ spec: ConnectorStartSpec, runtimeLibPath: String? = nil) throws -> RuntimeHost {
        try spec.validate()
        let path = try runtimeNativePath(explicitPath: runtimeLibPath)
        try validateCString(path, name: "runtime library path")
        let library = try NativeRuntimeLibrary(path: path)
        let handle = try library.requireHandle()
        let abi = coakka_swift_runtime_get_abi_version(handle)
        guard abi == expectedABI else { throw RuntimeError.unsupportedABI(abi) }
        let runtime = try createNative(library: library, spec: spec)
        var handles = coakka_swift_host_handles_t()
        var handlesOwned = false, started = false
        var client: OpaquePointer?
        var reader: OpaquePointer?
        do {
            try applyNetwork(library: library, runtime: runtime, network: spec.network)
            var security: TcpSecurityApplyResult?
            if let intent = spec.security {
                let result = try applySecurity(library: library, runtime: runtime, spec: intent)
                guard result.applied else { throw RuntimeError.tcpSecurityApply(result) }
                security = result
            }
            try applyRoutes(library: library, runtime: runtime, generation: spec.generation, routes: spec.routes)
            // Native Core selects its request lane. No descriptor-based inference.
            try throwIfNativeError(coakka_swift_runtime_get_host_handles(handle, runtime, 0, &handles), operation: "get host handles")
            handlesOwned = true
            try throwIfNativeError(coakka_swift_runtime_start(handle, runtime), operation: "start runtime")
            started = true
            client = coakka_swift_ask_client_create(handle, runtime, &handles)
            guard let client else { throw RuntimeError.nativeCreationRefused("Core refused ask-client construction without a causal status") }
            try throwIfNativeError(coakka_swift_runtime_request_reader_create(handle, runtime, &handles, &reader), operation: "create request reader")
            guard let reader else { throw RuntimeError.contractViolation("Core returned success without a reader") }
            return RuntimeHost(session: RuntimeSession(library: library, handle: handle, runtime: runtime,
                client: client, handles: handles, reader: reader), spec: spec, security: security)
        } catch {
            if let reader { coakka_swift_request_reader_destroy(handle, reader) }
            if started { _ = coakka_swift_runtime_stop(handle, runtime) }
            if let client { coakka_swift_ask_client_destroy(handle, client) }
            if handlesOwned { coakka_swift_host_handles_close(handle, &handles) }
            coakka_swift_runtime_destroy(handle, runtime)
            library.close()
            throw error
        }
    }

    /// Omitted queue intent forwards zero; Core's startup snapshot reports the accepted bound.
    public static func startLocal(systemName: String, target: String, nodeID: String? = nil,
        queueCapacity: Int32 = 0, generation: UInt64 = 1, runtimeLibPath: String? = nil) throws -> RuntimeHost {
        try start(ConnectorStartSpec(systemName: systemName, nodeID: nodeID ?? "\(systemName)-swift",
            queueCapacity: queueCapacity, generation: generation, routes: [.local(target)]), runtimeLibPath: runtimeLibPath)
    }

    public func registerHandler(_ target: String, handler: @escaping @Sendable (RuntimeRequest) throws -> Data) throws {
        try register(target, .rich(handler))
    }

    public func registerPayloadHandler(_ target: String, handler: @escaping @Sendable (Data) throws -> Data) throws {
        try register(target, .payload(handler))
    }

    public func registerTextHandler(_ target: String, handler: @escaping @Sendable (String) throws -> String) throws {
        try registerPayloadHandler(target) { payload in
            guard let text = String(data: payload, encoding: .utf8) else {
                throw RuntimeError.invalidArgument("request payload is not UTF-8")
            }
            return Data(try handler(text).utf8)
        }
    }

    private func register(_ target: String, _ handler: Handler) throws {
        try validateCString(target, name: "handler target")
        guard !target.isEmpty else { throw RuntimeError.invalidArgument("handler target is empty") }
        try session.withOpen { _ in
            clientLock.lock()
            defer { clientLock.unlock() }
            guard handlers[target] == nil else { throw RuntimeError.invalidArgument("handler target already registered") }
            let size = target.utf8.count
            guard handlers.count < 256, size <= 64 * 1024 - registrationBytes else {
                throw RuntimeError.resourceLimit("handler registration budget exhausted")
            }
            handlers[target] = handler
            registrationBytes += size
        }
    }

    /// A failed join preserves owners and can be retried. Reentrant handler close
    /// refuses before sealing admission. Timeout/cancel never promises remote undo.
    public func close() throws { try session.close() }

    /// Managed dispatch diagnostics, not inferred native state. Reader failure is
    /// the exact Core status or a violated FFI contract, never guessed native state.
    public func dispatchDiagnostics() -> (failures: UInt64, lastError: String?, readerError: RuntimeError?) {
        clientLock.lock()
        let value = (dispatchFailures, lastDispatchFailure)
        clientLock.unlock()
        return (value.0, value.1, session.readerFailure)
    }

    public func clientStats() -> RuntimeClientStats {
        clientLock.lock()
        defer { clientLock.unlock() }
        return RuntimeClientStats(deliveredRequests: deliveredRequests, matchedResponses: matchedResponses, matchedDeadletters: matchedDeadletters)
    }

    public func runtimeInfo() throws -> RuntimeInfoSnapshot {
        try session.withOpen { _ in
            var value = coakka_swift_runtime_info_t()
            try throwIfNativeError(coakka_swift_runtime_get_info(session.handle, &value), operation: "read runtime info")
            return RuntimeInfoSnapshot(abiVersion: value.abi_version, featureFlags: value.feature_flags,
                runtimeVersion: nativeString(value.runtime_version), gitCommit: nativeString(value.git_commit), backend: nativeString(value.backend))
        }
    }

    public func runtimeConfig() throws -> RuntimeConfigSnapshot {
        try session.withOpen { runtime in
            var value = coakka_swift_runtime_config_view_t()
            try throwIfNativeError(coakka_swift_runtime_get_config(session.handle, runtime, &value), operation: "read runtime config")
            return RuntimeConfigSnapshot(systemName: nativeString(value.system_name), nodeID: nativeString(value.node_id),
                strictNoDrop: value.strict_no_drop != 0, queueCapacity: value.queue_capacity,
                runtimeState: toRuntimeState(value.runtime_state), snapshotPresent: value.snapshot_present != 0,
                appliedGeneration: value.applied_generation, routeCount: value.route_count)
        }
    }

    public func health() throws -> RuntimeHealthSnapshot {
        try session.withOpen { runtime in
            var value = coakka_swift_runtime_health_t()
            try throwIfNativeError(coakka_swift_runtime_get_health(session.handle, runtime, &value), operation: "read runtime health")
            return RuntimeHealthSnapshot(runtimeState: toRuntimeState(value.runtime_state.rawValue), flags: value.flags, appliedGeneration: value.applied_generation)
        }
    }

    public func stats() throws -> RuntimeStatsSnapshot {
        try session.withOpen { runtime in
            var value = coakka_swift_runtime_stats_t()
            try throwIfNativeError(coakka_swift_runtime_get_stats(session.handle, runtime, &value), operation: "read runtime stats")
            return RuntimeStatsSnapshot(appliedGeneration: value.applied_generation, routeCount: value.route_count,
                runtimeState: toRuntimeState(value.runtime_state.rawValue), ingressQueueCapacity: value.ingress_queue_capacity,
                ingressQueueDepth: value.ingress_queue_depth, ingressQueueHighWatermark: value.ingress_queue_high_watermark,
                queueRejectedCount: value.queue_rejected_count, routeMissCount: value.route_miss_count,
                deadletterCount: value.deadletter_count, deliveryFailedCount: value.delivery_failed_count)
        }
    }

    private func dispatchRequest(_ frame: UnsafePointer<UInt8>, size: Int) {
        var targetBytes: UnsafeMutablePointer<UInt8>?, payloadBytes: UnsafeMutablePointer<UInt8>?
        var targetSize = 0, payloadSize = 0
        var oneWay: UInt32 = 0
        defer {
            coakka_swift_client_bytes_release(session.handle, targetBytes)
            coakka_swift_client_bytes_release(session.handle, payloadBytes)
        }
        do {
            try throwIfNativeError(coakka_swift_copy_request_dispatch(session.handle, frame, size,
                &targetBytes, &targetSize, &payloadBytes, &payloadSize, &oneWay), operation: "copy request dispatch")
            let (target, handler) = try projectDispatchTarget(targetBytes, size: targetSize)
            let payload = try copyNativeBytes(payloadBytes, count: payloadSize)
            clientLock.lock()
            deliveredRequests &+= 1
            clientLock.unlock()
            guard let handler else { return }
            let response: Data
            switch handler {
            case .payload(let callback): response = try callback(payload)
            case .rich(let callback):
                let envelope = try RuntimeEnvelopeCodec.decodeEnvelope(Data(bytes: frame, count: size))
                response = try callback(RuntimeRequest(messageID: envelope.messageID, source: envelope.source,
                    target: target, payload: payload, oneWay: oneWay != 0))
            }
            guard oneWay == 0 else { return }
            try session.withOpen { runtime in
                try target.withCString { source in
                    try response.withUnsafeBytes { bytes in
                        var reply = coakka_swift_raw_reply_spec_t(struct_size: MemoryLayout<coakka_swift_raw_reply_spec_t>.size,
                            request_buf: frame, request_len: size, source: source,
                            payload: bytes.bindMemory(to: UInt8.self).baseAddress, payload_len: response.count)
                        var wire: UnsafeMutablePointer<UInt8>?
                        var length = 0
                        defer { coakka_swift_client_bytes_release(session.handle, wire) }
                        try throwIfNativeError(coakka_swift_build_raw_reply(session.handle, &reply, &wire, &length), operation: "build reply")
                        try throwIfNativeError(coakka_swift_runtime_submit_envelope(session.handle, runtime, wire, length), operation: "submit reply")
                    }
                }
            }
        } catch {
            clientLock.lock()
            dispatchFailures &+= 1
            lastDispatchFailure = String(String(describing: error).prefix(1024))
            clientLock.unlock()
        }
    }

    private func projectDispatchTarget(_ pointer: UnsafePointer<UInt8>?, size: Int) throws -> (String, Handler?) {
        guard size > 0, let pointer else { throw RuntimeError.contractViolation("invalid Core dispatch target span") }
        let bytes = UnsafeBufferPointer(start: pointer, count: size)
        if let cached = dispatchProjection, cached.bytes.count == size,
           cached.bytes.withUnsafeBytes({ $0.elementsEqual(UnsafeRawBufferPointer(bytes)) }) {
            return (cached.target, cached.handler)
        }
        // Remove the avoidable transient Data-to-String copy. Core's returned
        // target and payload ownership copies remain unchanged.
        guard let target = String(bytes: bytes, encoding: .utf8) else {
            throw RuntimeError.contractViolation("Core dispatch target is not UTF-8")
        }
        clientLock.lock()
        let handler = handlers[target]
        clientLock.unlock()
        if size <= 256, let handler {
            dispatchProjection = DispatchProjection(bytes: Data(bytes), target: target, handler: handler)
        }
        return (target, handler)
    }
}

func copyNativeBytes(_ pointer: UnsafePointer<UInt8>?, count: Int) throws -> Data {
    guard count >= 0, count == 0 || pointer != nil else { throw RuntimeError.contractViolation("invalid native byte span") }
    return count == 0 ? Data() : Data(bytes: pointer!, count: count)
}
