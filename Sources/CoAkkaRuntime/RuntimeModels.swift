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

    public init(target: String, host: String = "127.0.0.1", port: UInt16 = 19191) {
        self.target = target
        self.host = host
        self.port = port
    }

    public static func local(_ target: String, port: UInt16 = 19191, host: String = "127.0.0.1") -> RuntimeRouteSpec {
        RuntimeRouteSpec(target: target, host: host, port: port)
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

    public init(
        systemName: String,
        nodeID: String,
        strictNoDrop: Bool = true,
        queueCapacity: Int32 = 128,
        generation: UInt64 = 1,
        routes: [RuntimeRouteSpec],
        separateDeliveredRequestLane: Bool = true
    ) {
        self.systemName = systemName
        self.nodeID = nodeID
        self.strictNoDrop = strictNoDrop
        self.queueCapacity = queueCapacity
        self.generation = generation
        self.routes = routes
        self.separateDeliveredRequestLane = separateDeliveredRequestLane
    }

    func normalized() -> ConnectorStartSpec {
        var copy = self
        if copy.nodeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            copy.nodeID = "\(copy.systemName)-swift"
        }
        if copy.queueCapacity <= 0 {
            copy.queueCapacity = 128
        }
        if copy.generation == 0 {
            copy.generation = 1
        }
        return copy
    }

    func validate() throws {
        guard !systemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuntimeError.invalidArgument("systemName must not be blank")
        }
        guard !nodeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RuntimeError.invalidArgument("nodeID must not be blank")
        }
        guard !routes.isEmpty else {
            throw RuntimeError.invalidArgument("at least one local route is required")
        }
        for route in routes {
            guard !route.target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RuntimeError.invalidArgument("route target must not be blank")
            }
            guard !route.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RuntimeError.invalidArgument("route host must not be blank")
            }
            guard route.port > 0 else {
                throw RuntimeError.invalidArgument("route port must be non-zero")
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
        }
    }
}
