import CoAkkaRuntimeC
import Foundation

public final class RuntimeHost: @unchecked Sendable {
    private static let expectedABI: UInt32 = 1
    private static let activeLock = NSLock()
    nonisolated(unsafe) private static var active = false

    private let library: NativeRuntimeLibrary
    private var runtime: OpaquePointer?
    private var askClient: OpaquePointer?
    private var requestReader: RuntimeFrameReader?
    private let clientLock = NSLock()
    private var handlers: [String: @Sendable (RuntimeRequest) throws -> Data] = [:]
    private var nextID: UInt64 = 0
    private var deliveredRequests: UInt64 = 0
    private var matchedResponses: UInt64 = 0
    private var matchedDeadletters: UInt64 = 0
    private var closed = false

    public let runtimeLibPath: String
    public let startSpec: ConnectorStartSpec

    private init(library: NativeRuntimeLibrary, runtime: OpaquePointer, startSpec: ConnectorStartSpec) {
        self.library = library
        self.runtime = runtime
        self.runtimeLibPath = library.path
        self.startSpec = startSpec
    }

    deinit {
        close()
    }

    public static func start(_ startSpec: ConnectorStartSpec, runtimeLibPath: String? = nil) throws -> RuntimeHost {
        let normalized = startSpec.normalized()
        try normalized.validate()

        activeLock.lock()
        defer {
            activeLock.unlock()
        }
        guard !active else {
            throw RuntimeError.alreadyStarted
        }

        let path = try runtimeNativePath(explicitPath: runtimeLibPath)
        let library = try NativeRuntimeLibrary(path: path)
        let handle = try library.requireHandle()
        let abi = coakka_swift_runtime_get_abi_version(handle)
        guard abi == expectedABI else {
            throw RuntimeError.unsupportedABI(abi)
        }

        let runtime = try normalized.systemName.withCString { systemName in
            try normalized.nodeID.withCString { nodeID in
                guard let runtime = coakka_swift_runtime_create(
                    handle,
                    systemName,
                    nodeID,
                    normalized.strictNoDrop ? 1 : 0,
                    normalized.queueCapacity
                ) else {
                    throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "create runtime")
                }
                return runtime
            }
        }

        do {
            var handles = coakka_swift_host_handles_t()
            let flags = normalized.separateDeliveredRequestLane ? UInt32(COAKKA_SWIFT_HOST_SEPARATE_DELIVERED_REQUEST_LANE) : 0
            try throwIfNativeError(
                coakka_swift_runtime_get_host_handles(handle, runtime, flags, &handles),
                operation: "get runtime host handles"
            )
            try applyRoutes(library: library, runtime: runtime, generation: normalized.generation, routes: normalized.routes)
            try throwIfNativeError(coakka_swift_runtime_start(handle, runtime), operation: "start runtime")
            guard let askClient = coakka_swift_ask_client_create(handle, runtime, &handles) else {
                throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "create ask client")
            }

            let host = RuntimeHost(library: library, runtime: runtime, startSpec: normalized)
            host.askClient = askClient
            try host.startReaders(handles: handles)
            active = true
            return host
        } catch {
            coakka_swift_runtime_destroy(handle, runtime)
            library.close()
            throw error
        }
    }

    public static func startLocal(
        systemName: String,
        target: String,
        nodeID: String? = nil,
        queueCapacity: Int32 = 128,
        generation: UInt64 = 1,
        runtimeLibPath: String? = nil
    ) throws -> RuntimeHost {
        try start(
            ConnectorStartSpec(
                systemName: systemName,
                nodeID: nodeID ?? "\(systemName)-swift",
                queueCapacity: queueCapacity,
                generation: generation,
                routes: [.local(target)]
            ),
            runtimeLibPath: runtimeLibPath
        )
    }

    public func registerHandler(_ target: String, handler: @escaping @Sendable (RuntimeRequest) throws -> Data) throws {
        try throwIfClosed()
        guard !target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuntimeError.invalidArgument("handler target must not be blank")
        }
        clientLock.lock()
        defer {
            clientLock.unlock()
        }
        guard handlers[target] == nil else {
            throw RuntimeError.invalidArgument("handler already registered for target \(target)")
        }
        handlers[target] = handler
    }

    public func registerTextHandler(_ target: String, handler: @escaping @Sendable (String) throws -> String) throws {
        try registerHandler(target) { request in
            Data(try handler(request.payloadString()).utf8)
        }
    }

    public func ask(
        source: String,
        target: String,
        payload: Data,
        timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault
    ) throws -> RuntimeResponse {
        try throwIfClosed()
        let messageID = nextMessageID(source: source)
        let replyTo = "\(source)/replies"
        let request = try buildRawRequest(
            messageID: messageID,
            source: source,
            target: target,
            replyTo: replyTo,
            payload: payload,
            timeoutMs: timeoutMs,
            deliveryHint: deliveryHint
        )

        let handle = try library.requireHandle()
        guard let askClient else {
            throw RuntimeError.closed
        }
        var ticket: OpaquePointer?
        try request.withUnsafeBytes { bytes in
            let pointer = bytes.bindMemory(to: UInt8.self).baseAddress
            try throwIfNativeError(
                coakka_swift_ask_client_begin(handle, askClient, pointer, request.count, &ticket),
                operation: "begin ask"
            )
        }
        guard let ticket else {
            throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "begin ask")
        }
        defer {
            coakka_swift_ask_ticket_destroy(handle, ticket)
        }

        var resultKind: UInt32 = 0
        var resultBuffer: UnsafeMutablePointer<UInt8>?
        var resultLength = 0
        let status = coakka_swift_ask_ticket_await(handle, ticket, timeoutMs, &resultKind, &resultBuffer, &resultLength)
        if status == Int32(COAKKA_SWIFT_STATUS_WOULD_BLOCK) {
            throw RuntimeError.timeout(messageID)
        }
        try throwIfNativeError(status, operation: "await ask response")
        guard let resultBuffer else {
            throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "await ask response")
        }
        let resultData = Data(bytes: resultBuffer, count: resultLength)
        coakka_swift_client_bytes_release(handle, resultBuffer)

        if resultKind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER) {
            incrementMatchedDeadletters()
            throw RuntimeError.deadletter(try RuntimeEnvelopeCodec.decodeDeadletter(resultData))
        }
        guard resultKind == UInt32(COAKKA_SWIFT_CLIENT_RESULT_RESPONSE) else {
            throw RuntimeError.nativeStatus(Int32(resultKind), "await ask response")
        }
        incrementMatchedResponses()
        let envelope = try RuntimeEnvelopeCodec.decodeEnvelope(resultData)
        return RuntimeResponse(
            messageID: envelope.messageID,
            correlationID: envelope.correlationID,
            source: envelope.source,
            target: envelope.target,
            payload: envelope.payload
        )
    }

    public func askText(
        source: String,
        target: String,
        payload: String,
        timeoutMs: UInt32 = 5_000,
        deliveryHint: DeliveryHint = .routerDefault
    ) throws -> String {
        try ask(
            source: source,
            target: target,
            payload: Data(payload.utf8),
            timeoutMs: timeoutMs,
            deliveryHint: deliveryHint
        ).payloadString()
    }

    public func runtimeInfo() throws -> RuntimeInfoSnapshot {
        try throwIfClosed()
        let handle = try library.requireHandle()
        var info = coakka_swift_runtime_info_t()
        try throwIfNativeError(coakka_swift_runtime_get_info(handle, &info), operation: "read runtime info")
        return RuntimeInfoSnapshot(
            abiVersion: info.abi_version,
            featureFlags: info.feature_flags,
            runtimeVersion: nativeString(info.runtime_version),
            gitCommit: nativeString(info.git_commit),
            backend: nativeString(info.backend)
        )
    }

    public func runtimeConfig() throws -> RuntimeConfigSnapshot {
        try throwIfClosed()
        let handle = try library.requireHandle()
        guard let runtime else {
            throw RuntimeError.closed
        }
        var config = coakka_swift_runtime_config_view_t()
        try throwIfNativeError(coakka_swift_runtime_get_config(handle, runtime, &config), operation: "read runtime config")
        return RuntimeConfigSnapshot(
            systemName: nativeString(config.system_name),
            nodeID: nativeString(config.node_id),
            strictNoDrop: config.strict_no_drop != 0,
            queueCapacity: config.queue_capacity,
            runtimeState: toRuntimeState(config.runtime_state),
            snapshotPresent: config.snapshot_present != 0,
            appliedGeneration: config.applied_generation,
            routeCount: config.route_count
        )
    }

    public func health() throws -> RuntimeHealthSnapshot {
        try throwIfClosed()
        let handle = try library.requireHandle()
        guard let runtime else {
            throw RuntimeError.closed
        }
        var health = coakka_swift_runtime_health_t()
        try throwIfNativeError(coakka_swift_runtime_get_health(handle, runtime, &health), operation: "read runtime health")
        return RuntimeHealthSnapshot(
            runtimeState: toRuntimeState(health.runtime_state),
            flags: health.flags,
            appliedGeneration: health.applied_generation
        )
    }

    public func stats() throws -> RuntimeStatsSnapshot {
        try throwIfClosed()
        let handle = try library.requireHandle()
        guard let runtime else {
            throw RuntimeError.closed
        }
        var stats = coakka_swift_runtime_stats_t()
        try throwIfNativeError(coakka_swift_runtime_get_stats(handle, runtime, &stats), operation: "read runtime stats")
        return RuntimeStatsSnapshot(
            appliedGeneration: stats.applied_generation,
            routeCount: stats.route_count,
            runtimeState: toRuntimeState(stats.runtime_state),
            ingressQueueCapacity: stats.ingress_queue_capacity,
            ingressQueueDepth: stats.ingress_queue_depth,
            ingressQueueHighWatermark: stats.ingress_queue_high_watermark,
            queueRejectedCount: stats.queue_rejected_count,
            routeMissCount: stats.route_miss_count,
            deadletterCount: stats.deadletter_count,
            deliveryFailedCount: stats.delivery_failed_count
        )
    }

    public func clientStats() -> RuntimeClientStats {
        clientLock.lock()
        defer {
            clientLock.unlock()
        }
        return RuntimeClientStats(
            deliveredRequests: deliveredRequests,
            matchedResponses: matchedResponses,
            matchedDeadletters: matchedDeadletters
        )
    }

    public func close() {
        clientLock.lock()
        if closed {
            clientLock.unlock()
            return
        }
        closed = true
        clientLock.unlock()

        requestReader?.stop()
        requestReader = nil

        if let handle = library.handle {
            if let askClient {
                coakka_swift_ask_client_destroy(handle, askClient)
                self.askClient = nil
            }
            if let runtime {
                _ = coakka_swift_runtime_stop(handle, runtime)
                coakka_swift_runtime_destroy(handle, runtime)
                self.runtime = nil
            }
        }
        library.close()

        RuntimeHost.activeLock.lock()
        RuntimeHost.active = false
        RuntimeHost.activeLock.unlock()
    }

    private func startReaders(handles: coakka_swift_host_handles_t) throws {
        let fd = handles.delivered_request_read_fd >= 0 ? handles.delivered_request_read_fd : handles.response_read_fd
        requestReader = try RuntimeFrameReader(
            library: library,
            fd: fd,
            name: "request",
            onFrame: { [weak self] frame in
                self?.dispatchRequest(frame)
            },
            onError: { _ in }
        )
    }

    private func dispatchRequest(_ frame: Data) {
        do {
            let envelope = try RuntimeEnvelopeCodec.decodeEnvelope(frame)
            let request = RuntimeRequest(
                messageID: envelope.messageID,
                source: envelope.source,
                target: envelope.target,
                payload: envelope.payload,
                oneWay: envelope.oneWay
            )
            let handler: (@Sendable (RuntimeRequest) throws -> Data)?
            clientLock.lock()
            deliveredRequests += 1
            handler = handlers[request.target]
            clientLock.unlock()
            guard let handler else {
                return
            }
            let replyPayload = try handler(request)
            guard !request.oneWay else {
                return
            }
            let reply = try buildRawReply(requestFrame: frame, source: request.target, payload: replyPayload)
            try submitRawEnvelope(reply)
        } catch {
        }
    }

    private func buildRawRequest(
        messageID: String,
        source: String,
        target: String,
        replyTo: String,
        payload: Data,
        timeoutMs: UInt32,
        deliveryHint: DeliveryHint
    ) throws -> Data {
        let handle = try library.requireHandle()
        return try messageID.withCString { cMessageID in
            try source.withCString { cSource in
                try target.withCString { cTarget in
                    try replyTo.withCString { cReplyTo in
                        try payload.withUnsafeBytes { rawPayload in
                            var spec = coakka_swift_raw_request_spec_t()
                            spec.struct_size = MemoryLayout<coakka_swift_raw_request_spec_t>.size
                            spec.message_id = cMessageID
                            spec.source = cSource
                            spec.target = cTarget
                            spec.reply_to = cReplyTo
                            spec.payload = rawPayload.bindMemory(to: UInt8.self).baseAddress
                            spec.payload_len = payload.count
                            spec.timeout_ms = timeoutMs
                            spec.delivery_hint = deliveryHint.rawValue
                            spec.one_way = 0
                            var outBuffer: UnsafeMutablePointer<UInt8>?
                            var outLength = 0
                            try throwIfNativeError(
                                coakka_swift_build_raw_request(handle, &spec, &outBuffer, &outLength),
                                operation: "build request"
                            )
                            guard let outBuffer else {
                                throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "build request")
                            }
                            let data = Data(bytes: outBuffer, count: outLength)
                            coakka_swift_client_bytes_release(handle, outBuffer)
                            return data
                        }
                    }
                }
            }
        }
    }

    private func buildRawReply(requestFrame: Data, source: String, payload: Data) throws -> Data {
        let handle = try library.requireHandle()
        return try source.withCString { cSource in
            try requestFrame.withUnsafeBytes { requestBytes in
                try payload.withUnsafeBytes { payloadBytes in
                    var spec = coakka_swift_raw_reply_spec_t()
                    spec.struct_size = MemoryLayout<coakka_swift_raw_reply_spec_t>.size
                    spec.request_buf = requestBytes.bindMemory(to: UInt8.self).baseAddress
                    spec.request_len = requestFrame.count
                    spec.source = cSource
                    spec.payload = payloadBytes.bindMemory(to: UInt8.self).baseAddress
                    spec.payload_len = payload.count
                    var outBuffer: UnsafeMutablePointer<UInt8>?
                    var outLength = 0
                    try throwIfNativeError(
                        coakka_swift_build_raw_reply(handle, &spec, &outBuffer, &outLength),
                        operation: "build reply"
                    )
                    guard let outBuffer else {
                        throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_BAD_STATE), "build reply")
                    }
                    let data = Data(bytes: outBuffer, count: outLength)
                    coakka_swift_client_bytes_release(handle, outBuffer)
                    return data
                }
            }
        }
    }

    private func submitRawEnvelope(_ data: Data) throws {
        let handle = try library.requireHandle()
        guard let runtime else {
            throw RuntimeError.closed
        }
        try data.withUnsafeBytes { bytes in
            try throwIfNativeError(
                coakka_swift_runtime_submit_envelope(handle, runtime, bytes.bindMemory(to: UInt8.self).baseAddress, data.count),
                operation: "submit reply"
            )
        }
    }

    private func nextMessageID(source: String) -> String {
        clientLock.lock()
        nextID += 1
        let value = nextID
        clientLock.unlock()
        return "\(source)-swift-\(value)"
    }

    private func incrementMatchedResponses() {
        clientLock.lock()
        matchedResponses += 1
        clientLock.unlock()
    }

    private func incrementMatchedDeadletters() {
        clientLock.lock()
        matchedDeadletters += 1
        clientLock.unlock()
    }

    private func throwIfClosed() throws {
        clientLock.lock()
        let isClosed = closed
        clientLock.unlock()
        if isClosed {
            throw RuntimeError.closed
        }
    }
}

private func applyRoutes(
    library: NativeRuntimeLibrary,
    runtime: OpaquePointer,
    generation: UInt64,
    routes: [RuntimeRouteSpec]
) throws {
    let handle = try library.requireHandle()
    var endpointStorage: [UnsafeMutablePointer<coakka_swift_endpoint_spec_t>] = []
    var allocatedStrings: [UnsafeMutablePointer<CChar>] = []
    var cRoutes: [coakka_swift_route_spec_t] = []

    defer {
        for endpoint in endpointStorage {
            endpoint.deallocate()
        }
        for string in allocatedStrings {
            free(string)
        }
    }

    for route in routes {
        guard let target = strdup(route.target), let host = strdup(route.host), let hint = strdup("") else {
            throw RuntimeError.nativeStatus(Int32(COAKKA_SWIFT_STATUS_NOMEM), "prepare routes")
        }
        allocatedStrings.append(target)
        allocatedStrings.append(host)
        allocatedStrings.append(hint)

        let endpoint = UnsafeMutablePointer<coakka_swift_endpoint_spec_t>.allocate(capacity: 1)
        endpoint.initialize(to: coakka_swift_endpoint_spec_t(
            host: UnsafePointer(host),
            port: route.port,
            weight: 1,
            flags: UInt32(COAKKA_SWIFT_ENDPOINT_LOCAL)
        ))
        endpointStorage.append(endpoint)
        cRoutes.append(coakka_swift_route_spec_t(
            target: UnsafePointer(target),
            strategy: UInt32(COAKKA_SWIFT_ROUTE_SINGLE_OWNER),
            route_key_hint: UnsafePointer(hint),
            flags: 0,
            endpoints: UnsafePointer(endpoint),
            endpoint_count: 1
        ))
    }

    try cRoutes.withUnsafeBufferPointer { routeBuffer in
        try throwIfNativeError(
            coakka_swift_runtime_apply_snapshot(handle, runtime, generation, routeBuffer.baseAddress, routes.count),
            operation: "apply route snapshot"
        )
    }
}
