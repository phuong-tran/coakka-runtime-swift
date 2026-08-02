import CoAkkaRuntime
import Foundation

func require(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    guard try condition() else {
        throw RuntimeError.invalidArgument("transport smoke: \(message)")
    }
}

func startSpec(
    _ suffix: String,
    connection: TcpConnectionStrategySpec? = nil,
    security: TcpSecuritySpec? = nil
) -> ConnectorStartSpec {
    ConnectorStartSpec(
        systemName: "connector-swift-transport-smoke",
        nodeID: "node-\(suffix)",
        queueCapacity: 32,
        routes: [.local("svc.echo", port: 19_560)],
        connectionStrategy: connection,
        security: security
    )
}

func tlsSpec(root: URL, generation: UInt64, credentialID: String, keyName: String) -> TcpSecuritySpec {
    TcpSecuritySpec(
        mode: .tls,
        credentialGeneration: generation,
        credentialID: credentialID,
        caCertificateFile: root.appendingPathComponent("ca.pem").path,
        identityCertificateFile: root.appendingPathComponent("server.pem").path,
        privateKeyFile: root.appendingPathComponent(keyName).path
    )
}

let expectedSizes = RuntimeTransportABISizes(
    capabilities: 48,
    connectionOptions: 48,
    connectionValidation: 40,
    connectionConfig: 72,
    connectionApplyResult: 136,
    securityOptions: 72,
    securityValidation: 24,
    securityConfig: 40,
    securityIdentity: 248,
    securityInfo: 296,
    securityApplyResult: 344
)
try require(RuntimeTransportABI.sizes == expectedSizes, "transport ABI size drift: \(RuntimeTransportABI.sizes)")

let runtimeLibrary = ProcessInfo.processInfo.environment["COAKKA_RUNTIME_LIB"]
let capabilities = try RuntimeHost.readRuntimeCapabilities(runtimeLibPath: runtimeLibrary)
let mode: TcpConnectionMode = capabilities.supports(.tcpBoundedPool) ? .boundedPool : .perExchange

do {
    _ = try RuntimeHost.start(
        startSpec("unknown", connection: TcpConnectionStrategySpec(mode: .init(rawValue: 999))),
        runtimeLibPath: runtimeLibrary
    )
    throw RuntimeError.invalidArgument("unknown connection mode was accepted")
} catch RuntimeError.tcpConnectionApply(let result) {
    try require(result.status == .invalidArgument, "unknown mode status")
    try require(result.validationCode == .unknownMode, "unknown mode validation")
    try require(result.activeConfig.mode == .perExchange, "unknown mode changed active config")
}

do {
    _ = try RuntimeHost.start(
        startSpec(
            "plaintext-fields",
            security: TcpSecuritySpec(credentialGeneration: 1, credentialID: "must-not-be-ignored")
        ),
        runtimeLibPath: runtimeLibrary
    )
    throw RuntimeError.invalidArgument("plaintext credential fields were accepted")
} catch RuntimeError.tcpSecurityApply(let result) {
    try require(result.status == .invalidArgument, "plaintext field status")
    try require(result.validationCode == .fieldNotApplicable, "plaintext field validation")
    try require(result.activeSecurity.credentialGeneration == 0, "plaintext rejection changed active state")
}

do {
    _ = try RuntimeHost.start(
        startSpec("nul", security: TcpSecuritySpec(credentialID: "truncated\0credential")),
        runtimeLibPath: runtimeLibrary
    )
    throw RuntimeError.invalidArgument("NUL credential ID was accepted")
} catch RuntimeError.invalidArgument(let message) {
    try require(message.contains("must not contain NUL"), "unexpected NUL validation message")
}

do {
    let runtime = try RuntimeHost.start(
        startSpec(
            "startup",
            connection: TcpConnectionStrategySpec(mode: mode),
            security: TcpSecuritySpec()
        ),
        runtimeLibPath: runtimeLibrary
    )
    defer { runtime.close() }
    try require(try runtime.runtimeCapabilities() == capabilities, "host capabilities differ")
    try require(runtime.startupTcpConnectionResult()?.applied == true, "missing connection startup result")
    try require(runtime.startupTcpSecurityResult()?.applied == true, "missing security startup result")
    try require(try runtime.tcpConnectionConfig().mode == mode, "effective connection mode differs")

    let rejected = try runtime.applyTcpConnectionStrategy(TcpConnectionStrategySpec())
    try require(rejected.status == .badState, "post-start connection status")
    try require(!rejected.changed, "post-start connection apply changed state")
    try require(rejected.activeConfig.mode == mode, "post-start rejection lost active mode")
}

var tlsExecuted = false
if capabilities.supports(.tcpTLS),
   let fixturePath = ProcessInfo.processInfo.environment["COAKKA_TLS_FIXTURE_ROOT"] {
    let fixtureRoot = URL(fileURLWithPath: fixturePath, isDirectory: true)
    let runtime = try RuntimeHost.start(
        startSpec(
            "tls",
            security: tlsSpec(
                root: fixtureRoot,
                generation: 1,
                credentialID: "swift-generation-1",
                keyName: "server.key"
            )
        ),
        runtimeLibPath: runtimeLibrary
    )
    defer { runtime.close() }

    let startup = runtime.startupTcpSecurityResult()
    try require(startup?.applied == true, "TLS startup result missing")
    try require(startup?.activeSecurity.credentialGeneration == 1, "TLS startup generation")
    try require(startup?.activeSecurity.identityFingerprintSHA256.count == 64, "TLS fingerprint")
    let generationOneFingerprint = startup?.activeSecurity.identityFingerprintSHA256

    let rejected = try runtime.applyTcpSecurity(
        tlsSpec(
            root: fixtureRoot,
            generation: 2,
            credentialID: "swift-generation-2-bad",
            keyName: "client.key"
        )
    )
    try require(rejected.status == .invalidArgument, "bad TLS reload status")
    try require(!rejected.changed, "bad TLS reload changed state")
    try require(rejected.activeSecurity.credentialGeneration == 1, "bad TLS reload lost generation 1")
    try require(
        rejected.activeSecurity.identityFingerprintSHA256 == generationOneFingerprint,
        "bad TLS reload changed identity"
    )
    let afterRejection = try runtime.tcpSecurityInfo()
    try require(afterRejection.credentialGeneration == 1, "getter lost generation after rejection")
    try require(
        afterRejection.identityFingerprintSHA256 == generationOneFingerprint,
        "getter observed a changed identity after rejection"
    )

    let applied = try runtime.applyTcpSecurity(
        tlsSpec(
            root: fixtureRoot,
            generation: 2,
            credentialID: "swift-generation-2",
            keyName: "server.key"
        )
    )
    try require(applied.applied && applied.changed, "valid TLS reload was not applied")
    try require(applied.activeSecurity.credentialGeneration == 2, "valid TLS reload generation")

    let stale = try runtime.applyTcpSecurity(
        tlsSpec(
            root: fixtureRoot,
            generation: 1,
            credentialID: "swift-generation-1-stale",
            keyName: "server.key"
        )
    )
    try require(stale.status == .invalidArgument, "stale TLS reload status")
    try require(!stale.changed, "stale TLS reload changed state")
    try require(stale.activeSecurity.credentialGeneration == 2, "stale TLS reload lost generation 2")
    tlsExecuted = true
}

print("CoAkka Swift transport smoke ok")
print("capabilities=\(capabilities.effectiveCapabilities.rawValue) mode=\(mode.rawValue) tls_executed=\(tlsExecuted)")
