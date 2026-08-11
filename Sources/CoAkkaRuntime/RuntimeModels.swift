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

    public init(target: String, host: String = "127.0.0.1", port: UInt16 = 0) {
        self.target = target
        self.host = host
        self.port = port
    }

    public static func local(_ target: String, port: UInt16 = 0, host: String = "127.0.0.1") -> RuntimeRouteSpec {
        RuntimeRouteSpec(target: target, host: host, port: port)
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
            advertisePort: advertisePort == 0 ? bindPort : advertisePort
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
        if mode == .networkNode {
            guard let bindHost, !bindHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  bindPort > 0 else {
                throw RuntimeError.invalidArgument("networkNode requires bindHost and bindPort")
            }
            guard let advertiseHost,
                  !advertiseHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  advertisePort > 0 else {
                throw RuntimeError.invalidArgument("networkNode requires advertiseHost and advertisePort")
            }
            guard !["0.0.0.0", "::", "[::]", "::0"].contains(advertiseHost) else {
                throw RuntimeError.invalidArgument("advertiseHost must not be wildcard")
            }
        } else if bindHost != nil || bindPort != 0 || advertiseHost != nil || advertisePort != 0 {
            throw RuntimeError.invalidArgument("embedded and outboundOnly do not accept a listener")
        }
    }
}

public struct ConnectorStartSpec: Sendable {
    public var systemName: String
    public var nodeID: String
    public var strictNoDrop: Bool
    public var queueCapacity: Int32
    public var generation: UInt64
    public var routes: [RuntimeRouteSpec]
    public var separateDeliveredRequestLane: Bool
    public var connectionStrategy: TcpConnectionStrategySpec?
    public var security: TcpSecuritySpec?
    public var network: RuntimeNetworkConfig

    public init(
        systemName: String,
        nodeID: String,
        strictNoDrop: Bool = true,
        queueCapacity: Int32 = 128,
        generation: UInt64 = 1,
        routes: [RuntimeRouteSpec],
        separateDeliveredRequestLane: Bool = true,
        connectionStrategy: TcpConnectionStrategySpec? = nil,
        security: TcpSecuritySpec? = nil,
        network: RuntimeNetworkConfig = .embedded()
    ) {
        self.systemName = systemName
        self.nodeID = nodeID
        self.strictNoDrop = strictNoDrop
        self.queueCapacity = queueCapacity
        self.generation = generation
        self.routes = routes
        self.separateDeliveredRequestLane = separateDeliveredRequestLane
        self.connectionStrategy = connectionStrategy
        self.security = security
        self.network = network
    }

    func validate() throws {
        guard !systemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuntimeError.invalidArgument("systemName must not be blank")
        }
        guard !systemName.utf8.contains(0) else {
            throw RuntimeError.invalidArgument("systemName must not contain NUL")
        }
        guard !nodeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuntimeError.invalidArgument("nodeID must not be blank")
        }
        guard !nodeID.utf8.contains(0) else {
            throw RuntimeError.invalidArgument("nodeID must not contain NUL")
        }
        guard queueCapacity > 0 else {
            throw RuntimeError.invalidArgument("queueCapacity must be greater than zero")
        }
        guard generation > 0 else {
            throw RuntimeError.invalidArgument("generation must be greater than zero")
        }
        try network.validate()
        guard !routes.isEmpty else {
            throw RuntimeError.invalidArgument("at least one local route is required")
        }
        for route in routes {
            guard !route.target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RuntimeError.invalidArgument("route target must not be blank")
            }
            guard !route.target.utf8.contains(0) else {
                throw RuntimeError.invalidArgument("route target must not contain NUL")
            }
            guard !route.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RuntimeError.invalidArgument("route host must not be blank")
            }
            guard !route.host.utf8.contains(0) else {
                throw RuntimeError.invalidArgument("route host must not contain NUL")
            }
        }
    }
}

public struct RuntimeRequest: Sendable {
    public var messageID: String
    public var source: String
    public var target: String
    public var payload: Data
    public var oneWay: Bool

    public func payloadString(encoding: String.Encoding = .utf8) -> String {
        String(data: payload, encoding: encoding) ?? ""
    }
}

public struct RuntimeResponse: Sendable {
    public var messageID: String
    public var correlationID: String
    public var source: String
    public var target: String
    public var payload: Data

    public func payloadString(encoding: String.Encoding = .utf8) -> String {
        String(data: payload, encoding: encoding) ?? ""
    }
}

public struct RuntimeDeadletter: Sendable {
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
        }
    }
}
