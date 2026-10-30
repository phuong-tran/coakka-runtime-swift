import CoAkkaRuntimeC
import Foundation

public struct RuntimeExecutionSnapshot: Sendable {
    public let requestedPolicy, availableCpuCount, selectedCpuCount: UInt32
    public let selectedCpuID0, selectedCpuID1: UInt32
    public let supported, startupApplied: Bool
}

public struct RuntimeIoSnapshot: Sendable {
    public let requested, compiled, probed, supported, effective: Bool
    public let probeError: Int32
}

public struct RuntimeStartupSnapshot: Sendable {
    public let defaultsRevision, defaultedGroups, queueCapacity: UInt32
    public let strictNoDrop: Bool
    public let requestMaxFrameSize: UInt64
    public let runtimeState: RuntimeState
    public let execution: RuntimeExecutionSnapshot
    public let connection: TcpConnectionConfigSnapshot
    public let io: RuntimeIoSnapshot
    public let monitorEnabled: Bool
}

public struct RuntimeDeliverySnapshot: Sendable {
    public let compiled: Bool
    public let requestMode, responseMode, remoteBatchMaxCalls, slotCapacity: UInt32
    public let byteCapacity: UInt64
}

extension RuntimeHost {
    /// Copies accepted Core state and presence/default provenance. No live OS probe.
    public func startupConfig() throws -> RuntimeStartupSnapshot {
        try session.withOpen { runtime in
            var native = coakka_swift_startup_config_t()
            native.struct_size = MemoryLayout.size(ofValue: native)
            try throwIfNativeError(coakka_swift_runtime_get_startup_config(session.handle, runtime, &native), operation: "read startup config")
            let cpu = native.execution, io = native.io
            return RuntimeStartupSnapshot(defaultsRevision: native.defaults_revision,
                defaultedGroups: native.defaulted_groups, queueCapacity: native.queue_capacity,
                strictNoDrop: native.strict_no_drop != 0, requestMaxFrameSize: native.request_max_frame_size,
                runtimeState: toRuntimeState(native.runtime_state),
                execution: RuntimeExecutionSnapshot(requestedPolicy: cpu.requested_policy,
                    availableCpuCount: cpu.available_cpu_count, selectedCpuCount: cpu.selected_cpu_count,
                    selectedCpuID0: cpu.selected_cpu_ids.0, selectedCpuID1: cpu.selected_cpu_ids.1,
                    supported: cpu.supported != 0, startupApplied: cpu.startup_applied != 0),
                connection: connectionConfig(native.connection),
                io: RuntimeIoSnapshot(requested: io.requested != 0, compiled: io.compiled != 0,
                    probed: io.probed != 0, supported: io.supported != 0, effective: io.effective != 0,
                    probeError: io.probe_error), monitorEnabled: native.monitor.enabled != 0)
        }
    }

    public func deliveryConfig() throws -> RuntimeDeliverySnapshot {
        try session.withOpen { runtime in
            var native = coakka_swift_delivery_config_t()
            native.struct_size = MemoryLayout.size(ofValue: native)
            try throwIfNativeError(coakka_swift_runtime_get_delivery_config(session.handle, runtime, &native), operation: "read delivery config")
            return RuntimeDeliverySnapshot(compiled: native.compiled != 0,
                requestMode: native.request_mode, responseMode: native.response_mode,
                remoteBatchMaxCalls: native.remote_batch_max_calls, slotCapacity: native.slot_capacity,
                byteCapacity: native.byte_capacity)
        }
    }
}

func createNative(library: NativeRuntimeLibrary, spec: ConnectorStartSpec) throws -> OpaquePointer {
    let handle = try library.requireHandle()
    var execution = coakka_swift_startup_execution_options_t()
    execution.struct_size = MemoryLayout.size(ofValue: execution)
    execution.cpu_policy = spec.cpuPolicy?.rawValue ?? 0
    var io = coakka_swift_startup_io_options_t()
    io.struct_size = MemoryLayout.size(ofValue: io)
    io.use_io_uring = spec.useIoUring == true ? 1 : 0
    var monitor = coakka_swift_startup_monitor_options_t()
    monitor.struct_size = MemoryLayout.size(ofValue: monitor)
    monitor.enabled = spec.enableMonitor == true ? 1 : 0
    var connection = connectionOptions(spec.connectionStrategy)
    return try withUnsafePointer(to: &execution) { executionPointer in
        try withUnsafePointer(to: &io) { ioPointer in
            try withUnsafePointer(to: &monitor) { monitorPointer in
                try withUnsafePointer(to: &connection) { connectionPointer in
                    var options = coakka_swift_startup_options_t()
                    options.struct_size = MemoryLayout.size(ofValue: options)
                    options.execution = spec.cpuPolicy == nil ? nil : executionPointer
                    options.io = spec.useIoUring == nil ? nil : ioPointer
                    options.monitor = spec.enableMonitor == nil ? nil : monitorPointer
                    options.connection = spec.connectionStrategy == nil ? nil : connectionPointer
                    return try spec.systemName.withCString { system in
                        try spec.nodeID.withCString { node in
                            var runtime: OpaquePointer?
                            try throwIfNativeError(coakka_swift_runtime_create_native(handle, system, node,
                                spec.strictNoDrop ? 1 : 0, spec.queueCapacity, &options, &runtime), operation: "create native runtime")
                            guard let runtime else { throw RuntimeError.contractViolation("Core returned success without a runtime") }
                            return runtime
                        }
                    }
                }
            }
        }
    }
}

func connectionOptions(_ spec: TcpConnectionStrategySpec?) -> coakka_swift_tcp_connection_options_t {
    var options = coakka_swift_tcp_connection_options_t()
    options.struct_size = MemoryLayout.size(ofValue: options)
    guard let spec else { return options }
    options.fields = UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MODE)
    options.mode = spec.mode.rawValue
    if let value = spec.maxConnections {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_CONNECTIONS)
        options.max_connections = value
    }
    if let value = spec.maxRequestsPerConnection {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_REQUESTS_PER_CONNECTION)
        options.max_requests_per_connection = value
    }
    if let value = spec.idleTimeoutMs {
        options.fields |= UInt64(COAKKA_SWIFT_TCP_CONNECTION_FIELD_IDLE_TIMEOUT_MS)
        options.idle_timeout_ms = value
    }
    return options
}

func applyNetwork(library: NativeRuntimeLibrary, runtime: OpaquePointer, network: RuntimeNetworkConfig) throws {
    let bind = network.bindHost.map(duplicateCString)
    let advertise = network.advertiseHost.map(duplicateCString)
    defer { bind?.deallocate(); advertise?.deallocate() }
    try throwIfNativeError(coakka_swift_runtime_apply_network(try library.requireHandle(), runtime,
        network.mode.rawValue, bind.map { UnsafePointer($0) }, network.bindPort,
        advertise.map { UnsafePointer($0) }, network.advertisePort), operation: "apply runtime network policy")
}

func applyRoutes(library: NativeRuntimeLibrary, runtime: OpaquePointer, generation: UInt64, routes: [RuntimeRouteSpec]) throws {
    var endpoints: [UnsafeMutablePointer<coakka_swift_endpoint_spec_t>] = []
    var strings: [UnsafeMutablePointer<CChar>] = []
    var values: [coakka_swift_route_spec_t] = []
    defer { endpoints.forEach { $0.deallocate() }; strings.forEach { $0.deallocate() } }
    for route in routes {
        let target = duplicateCString(route.target), host = duplicateCString(route.host)
        strings.append(target); strings.append(host)
        let endpoint = UnsafeMutablePointer<coakka_swift_endpoint_spec_t>.allocate(capacity: 1)
        endpoint.initialize(to: coakka_swift_endpoint_spec_t(host: UnsafePointer(host), port: route.port,
            weight: 1, flags: route.isLocal ? UInt32(COAKKA_SWIFT_ENDPOINT_LOCAL) : 0))
        endpoints.append(endpoint)
        values.append(coakka_swift_route_spec_t(target: UnsafePointer(target), strategy: COAKKA_V2_ROUTE_STRATEGY_SINGLE_OWNER,
            route_key_hint: nil, flags: 0, endpoints: UnsafePointer(endpoint), endpoint_count: 1))
    }
    try values.withUnsafeBufferPointer { buffer in
        try throwIfNativeError(coakka_swift_runtime_apply_snapshot(try library.requireHandle(), runtime,
            generation, buffer.baseAddress, buffer.count), operation: "apply route snapshot")
    }
}

private func duplicateCString(_ value: String) -> UnsafeMutablePointer<CChar> {
    let bytes = value.utf8CString
    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
    bytes.withUnsafeBufferPointer { pointer.initialize(from: $0.baseAddress!, count: $0.count) }
    return pointer
}
