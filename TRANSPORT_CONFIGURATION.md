# Swift Runtime Transport Configuration

The public CoAkka C ABI is the semantic authority. Swift preserves unknown
numeric status/mode values, exact presence bits, and copied structured results;
it does not infer features from the package or silently substitute a mode.

## Startup And Defaults

`ConnectorStartSpec.connectionStrategy` and `.security` are optional. Nil
preserves core defaults. When present, policy is applied atomically while the
runtime is `CREATED`, before host handles are exported and before start.

```swift
let capabilities = try RuntimeHost.readRuntimeCapabilities()
let strategy = TcpConnectionStrategySpec(
    mode: capabilities.supports(.tcpBoundedPool) ? .boundedPool : .perExchange
)
let host = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "orders",
        nodeID: "orders-1",
        routes: [.local("svc.orders")],
        connectionStrategy: strategy,
        security: TcpSecuritySpec()
    )
)
```

Optional tuning fields are sent only when non-nil. Core owns defaults and
validates field applicability, capability, edition, and lifecycle. Invalid
queue capacity and generation are rejected rather than rewritten.

## Public Functions

| Function | Contract |
| --- | --- |
| `RuntimeHost.readRuntimeCapabilities(runtimeLibPath:)` | Resolves and synchronously loads one module; nil follows resolver order. The first canonical path remains loaded for process lifetime. All editions; throws load/ABI/native errors. |
| `capabilities.supports(_:)` | Pure owned-value check requiring every requested effective bit. No blocking or retained native memory. |
| `RuntimeTransportABI.sizes` | Reports Swift layout sizes for eleven C ABI blocks. Diagnostic only; it is not execution evidence for another OS. |
| `RuntimeHost.start(_:runtimeLibPath:)` | Owns one process-active host. Applies explicit transport policy, routes, exports handles, starts, and creates readers. Credential loading may block. Any failure releases runtime and fd ownership. |
| `runtimeCapabilities()` | Synchronously copies capability truth; serialized with apply/close. Open host only; all editions. |
| `tcpConnectionConfig()` | Copies effective mode, tuning, and explicit/default provenance. Serialized, non-mutating, open host only. |
| `tcpSecurityInfo()` | Copies active non-secret security and certificate identity. Never returns paths, keys, PEM, or tokens. Serialized, open host only. |
| `startupTcpConnectionResult()` | Returns the owned startup result or nil when omitted. Non-blocking and valid after host close. |
| `startupTcpSecurityResult()` | Returns the owned non-secret startup result or nil when omitted. Non-blocking and valid after host close. |
| `applyTcpConnectionStrategy(_:)` | Synchronous atomic attempt. Connection mode is startup-only; a started host normally returns `badState`, `changed == false`, and unchanged active config. |
| `applyTcpSecurity(_:)` | Synchronous same-mode newer-generation TLS/mTLS reload. Strings are borrowed only for the call; file I/O may block. Failure keeps the previous active context. |
| `close()` | Idempotently stops readers/client/runtime, closes each unique exported fd once, and destroys runtime state. Serialized against transport calls. |

All structs returned by public transport functions own their Swift strings and
numeric data. Startup rejection throws `RuntimeError.tcpConnectionApply` or
`.tcpSecurityApply`, retaining the structured active-state result.

## Connection Modes

- `.perExchange`: one connection per exchange; universal default.
- `.boundedPool`: bounded reusable connections; requires effective capability.
- `.persistentSingleFlight`: one retained serial connection per endpoint.
- `.multiplexing`: bounded concurrent exchanges on retained connections.

Defaults and edition/tuning availability are canonical in
[Connection Strategies](https://github.com/phuong-tran/coakka-samples/blob/main/docs/connection-strategies.md).

## TLS Reload

```swift
let result = try runtime.applyTcpSecurity(
    TcpSecuritySpec(
        mode: .tls,
        credentialGeneration: 2,
        credentialID: "orders-2026-08",
        caCertificateFile: "/run/secrets/coakka/ca.pem",
        identityCertificateFile: "/run/secrets/coakka/tls.pem",
        privateKeyFile: "/run/secrets/coakka/tls.key"
    )
)
```

The caller owns all secret files and their permissions/lifetime. The runtime
loads and validates them synchronously, then publishes a private immutable
context. Embedded NUL is rejected locally. A bad key, stale generation, mode
change, or validation failure returns the still-active prior generation.

See the canonical [TLS/mTLS guide](https://github.com/phuong-tran/coakka-samples/blob/main/docs/tls-and-mtls.md)
for Kubernetes ingress/service mesh, controlled networks, LAN/edge, Raspberry
Pi, BeagleBone, bare metal, industrial Android, and rotation guidance.

## Platforms And Signing

The package includes exact natives for macOS ARM64, Linux
ARM64, and Windows x86-64. Publisher signing is currently absent and documented
separately from package digests. Package presence does not replace native
execution evidence. Use [common troubleshooting](https://github.com/phuong-tran/coakka-samples/blob/main/docs/troubleshooting.md)
for loader/CPU mismatch, dependencies, Gatekeeper, SmartScreen/Authenticode,
checksums, certificates, and signing status.
