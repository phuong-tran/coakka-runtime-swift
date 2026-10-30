import Foundation

public enum RuntimeState: Equatable, Sendable {
    case created
    case started
    case stopped
    case unknown(Int)
}

public enum DeliveryHint: UInt32, Sendable {
    case routerDefault = 1
    case requireLocal = 3
}

public struct RuntimeRouteSpec: Sendable {
    public var target: String
    public var host: String
    public var port: UInt16
    public var isLocal: Bool

    public init(target: String, host: String = "127.0.0.1", port: UInt16 = 0, isLocal: Bool = true) {
        self.target = target
        self.host = host
        self.port = port
        self.isLocal = isLocal
    }

    public static func local(_ target: String, port: UInt16 = 0, host: String = "127.0.0.1") -> RuntimeRouteSpec {
        RuntimeRouteSpec(target: target, host: host, port: port)
    }

    public static func remote(_ target: String, host: String, port: UInt16) -> RuntimeRouteSpec {
        RuntimeRouteSpec(target: target, host: host, port: port, isLocal: false)
    }
}

public enum RuntimeNetworkMode: UInt32, Sendable {
    case embedded = 1
    case outboundOnly = 2
    case networkNode = 3
}

public struct RuntimeNetworkConfig: Sendable {
    public var mode: RuntimeNetworkMode
    public var bindHost: String?
    public var bindPort: UInt16
    public var advertiseHost: String?
    public var advertisePort: UInt16

    public static func embedded() -> RuntimeNetworkConfig {
        RuntimeNetworkConfig(mode: .embedded)
    }

    public static func outboundOnly() -> RuntimeNetworkConfig {
        RuntimeNetworkConfig(mode: .outboundOnly)
    }

    public static func networkNode(
        bindHost: String,
        bindPort: UInt16,
        advertiseHost: String,
        advertisePort: UInt16 = 0
    ) -> RuntimeNetworkConfig {
        RuntimeNetworkConfig(
            mode: .networkNode,
            bindHost: bindHost,
            bindPort: bindPort,
            advertiseHost: advertiseHost,
            advertisePort: advertisePort
        )
    }

    public init(
        mode: RuntimeNetworkMode,
        bindHost: String? = nil,
        bindPort: UInt16 = 0,
        advertiseHost: String? = nil,
        advertisePort: UInt16 = 0
    ) {
        self.mode = mode
        self.bindHost = bindHost
        self.bindPort = bindPort
        self.advertiseHost = advertiseHost
        self.advertisePort = advertisePort
    }

    func validate() throws {
        if let bindHost { try validateCString(bindHost, name: "bindHost") }
        if let advertiseHost { try validateCString(advertiseHost, name: "advertiseHost") }
    }
}

public enum RuntimeCpuPolicy: UInt32, Sendable {
    case auto = 0
    case single = 1
}

public struct ConnectorStartSpec: Sendable {
    public var systemName: String
    public var nodeID: String
    public var strictNoDrop: Bool
    /// Requested ingress bound; zero delegates normalization/default resolution to Core.
    public var queueCapacity: Int32
    public var generation: UInt64
    public var routes: [RuntimeRouteSpec]
    public var connectionStrategy: TcpConnectionStrategySpec?
    public var security: TcpSecuritySpec?
    public var network: RuntimeNetworkConfig
    public var cpuPolicy: RuntimeCpuPolicy?
    public var useIoUring: Bool?
    public var enableMonitor: Bool?

    public init(
        systemName: String,
        nodeID: String,
        strictNoDrop: Bool = true,
        queueCapacity: Int32 = 0,
        generation: UInt64 = 1,
        routes: [RuntimeRouteSpec],
        connectionStrategy: TcpConnectionStrategySpec? = nil,
        security: TcpSecuritySpec? = nil,
        network: RuntimeNetworkConfig = .embedded(),
        cpuPolicy: RuntimeCpuPolicy? = nil,
        useIoUring: Bool? = nil,
        enableMonitor: Bool? = nil
    ) {
        self.systemName = systemName
        self.nodeID = nodeID
        self.strictNoDrop = strictNoDrop
        self.queueCapacity = queueCapacity
        self.generation = generation
        self.routes = routes
        self.connectionStrategy = connectionStrategy
        self.security = security
        self.network = network
        self.cpuPolicy = cpuPolicy
        self.useIoUring = useIoUring
        self.enableMonitor = enableMonitor
    }

    func validate() throws {
        try validateCString(systemName, name: "systemName")
        try validateCString(nodeID, name: "nodeID")
        try network.validate()
        for route in routes {
            try validateCString(route.target, name: "route target")
            try validateCString(route.host, name: "route host")
        }
    }
}

public struct RuntimeRequest: Sendable {
    public var messageID: String
    public var source: String
    public var target: String
    public var payload: Data
    public var oneWay: Bool

    public func payloadString(encoding: String.Encoding = .utf8) -> String? {
        String(data: payload, encoding: encoding)
    }
}

public struct RuntimeResponse: Sendable {
    public var messageID: String
    public var correlationID: String
    public var source: String
    public var target: String
    public var payload: Data

    public func payloadString(encoding: String.Encoding = .utf8) -> String? {
        String(data: payload, encoding: encoding)
    }
}

public struct RuntimeDeadletter: Sendable {
    /// Exact Core code, including future values.
    public var reasonCode: UInt32
    /// Exact Core name; unknown codes keep Core's unknown label.
    public var reason: String
    public var detail: String
    public var originalMessageID: String
    public var originalSource: String
    public var originalTarget: String
}

public struct RuntimeInfoSnapshot: Sendable {
    public var abiVersion: UInt32
    public var featureFlags: UInt32
    public var runtimeVersion: String
    public var gitCommit: String
    public var backend: String
}

public struct RuntimeConfigSnapshot: Sendable {
    public var systemName: String
    public var nodeID: String
    public var strictNoDrop: Bool
    public var queueCapacity: Int32
    public var runtimeState: RuntimeState
    public var snapshotPresent: Bool
    public var appliedGeneration: UInt64
    public var routeCount: Int
}

public struct RuntimeHealthSnapshot: Sendable {
    public var runtimeState: RuntimeState
    public var flags: UInt32
    public var appliedGeneration: UInt64
}

public struct RuntimeStatsSnapshot: Sendable {
    public var appliedGeneration: UInt64
    public var routeCount: Int
    public var runtimeState: RuntimeState
    public var ingressQueueCapacity: Int
    public var ingressQueueDepth: Int
    public var ingressQueueHighWatermark: Int
    public var queueRejectedCount: UInt64
    public var routeMissCount: UInt64
    public var deadletterCount: UInt64
    public var deliveryFailedCount: UInt64
}

public struct RuntimeClientStats: Sendable {
    public var deliveredRequests: UInt64
    public var matchedResponses: UInt64
    public var matchedDeadletters: UInt64
}

public enum RuntimeError: Error, CustomStringConvertible, Sendable {
    case invalidArgument(String)
    case loadFailed(String)
    case nativeStatus(Int32, String)
    case unsupportedABI(UInt32)
    case alreadyStarted
    case closed
    case timeout(String)
    case deadletter(RuntimeDeadletter)
    case tcpConnectionApply(TcpConnectionApplyResult)
    case tcpSecurityApply(TcpSecurityApplyResult)
    case resourceLimit(String)
    case shutdown(String)
    case contractViolation(String)
    case nativeCreationRefused(String)

    public var description: String {
        switch self {
        case .invalidArgument(let message):
            return message
        case .loadFailed(let message):
            return message
        case .nativeStatus(let status, let operation):
            return "\(operation) failed with status \(status)"
        case .unsupportedABI(let version):
            return "Unsupported runtime ABI version \(version)"
        case .alreadyStarted:
            return "RuntimeHost is already started for this process"
        case .closed:
            return "RuntimeHost is closed"
        case .timeout(let messageID):
            return "Timed out waiting for response to \(messageID)"
        case .deadletter(let deadletter):
            return "Runtime deadletter \(deadletter.reason) for target \(deadletter.originalTarget)"
        case .tcpConnectionApply(let result):
            return "TCP connection apply failed with status \(result.status.rawValue) (\(result.reasonName))"
        case .tcpSecurityApply(let result):
            return "TCP security apply failed with status \(result.status.rawValue) (\(result.reasonName))"
        case .resourceLimit(let message), .shutdown(let message), .contractViolation(let message), .nativeCreationRefused(let message):
            return message
        }
    }
}

func validateCString(_ value: String, name: String) throws {
    guard !value.utf8.contains(0) else { throw RuntimeError.invalidArgument("\(name) must not contain NUL") }
    guard value.utf8.count <= Int(Int32.max) else { throw RuntimeError.invalidArgument("\(name) exceeds native string bounds") }
}

// Own only the UTF-8 projection borrowed by one synchronous C call. Validate
// every string before allocating: throwing must not orphan a retained callback
// or silently truncate Swift input at an embedded NUL. Core owns text policy.
final class NativeCStringStorage {
    private var pointers: [UnsafeMutablePointer<CChar>] = []
    init(_ values: [String]) throws {
        for value in values { try validateCString(value, name: "native text") }
        for value in values {
            let bytes = value.utf8CString
            let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
            bytes.withUnsafeBufferPointer { pointer.initialize(from: $0.baseAddress!, count: bytes.count) }
            pointers.append(pointer)
        }
    }
    deinit { for pointer in pointers { pointer.deallocate() } }
    subscript(_ index: Int) -> UnsafePointer<CChar> { UnsafePointer(pointers[index]) }
}
