import CoAkkaRuntime
import Foundation

func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

let runtime = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "swift-smoke",
        nodeID: "swift-smoke-node",
        queueCapacity: 64,
        routes: [.local("svc.echo", port: 19191)],
        connectionStrategy: TcpConnectionStrategySpec(),
        security: TcpSecuritySpec()
    )
)
defer {
    runtime.close()
}

try runtime.registerTextHandler("svc.echo") { request in
    "echo-\(request)"
}

let response = try runtime.askText(
    source: "swift-smoke",
    target: "svc.echo",
    payload: "hello-swift-runtime",
    timeoutMs: 2_000,
    deliveryHint: .requireLocal
)

var sawRouteMiss = false
do {
    _ = try runtime.askText(
        source: "swift-smoke",
        target: "svc.missing",
        payload: "missing",
        timeoutMs: 2_000,
        deliveryHint: .requireLocal
    )
} catch RuntimeError.deadletter(let deadletter) {
    sawRouteMiss = deadletter.reason == "DEADLETTER_REASON_ROUTE_MISS"
}

let info = try runtime.runtimeInfo()
let config = try runtime.runtimeConfig()
let health = try runtime.health()
let stats = try runtime.stats()
let clientStats = runtime.clientStats()

assertTrue(info.abiVersion == 1, "expected ABI version 1")
assertTrue(!info.runtimeVersion.isEmpty, "runtime version should be present")
assertTrue(config.systemName == "swift-smoke", "unexpected system name \(config.systemName)")
assertTrue(config.nodeID == "swift-smoke-node", "unexpected node id \(config.nodeID)")
assertTrue(config.routeCount == 1, "expected one route")
assertTrue(config.runtimeState == .started, "unexpected config state")
assertTrue(health.runtimeState == .started, "unexpected health state")
assertTrue(stats.ingressQueueCapacity > 0, "ingress queue capacity should be positive")
assertTrue(response.contains("hello-swift-runtime"), "response should contain echo payload")
assertTrue(sawRouteMiss, "route miss should surface as a deadletter")
assertTrue(clientStats.deliveredRequests == 1, "expected one delivered request")
assertTrue(clientStats.matchedResponses == 1, "expected one matched response")
assertTrue(clientStats.matchedDeadletters == 1, "expected one matched deadletter")

print("CoAkka Swift runtime smoke ok")
print("runtime=\(info.runtimeVersion) git=\(info.gitCommit) backend=\(info.backend)")
print("lib=\(runtime.runtimeLibPath)")
print("response=\(response) delivered=\(clientStats.deliveredRequests) matched=\(clientStats.matchedResponses) deadletters=\(clientStats.matchedDeadletters)")
