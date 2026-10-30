# Swift Runtime Transport Configuration

The public CoAkka C ABI is the semantic authority. Swift preserves unknown
numeric status/mode values, exact presence bits, and copied structured results;
it does not infer features from the package or silently substitute a mode.

## Startup And Defaults

This private native-client candidate is not the historical Core26 package.
P399 uses Core `1522b4a9f30da1039ef8c7d198bbecfc749a2456`, ABI1 and its
byte-exact public SDK. All three qualified images report owned request/response
delivery; this is an inspected artifact fact, not an OS or connector default.
Optional CPU/connection/I/O/monitor groups are passed to Core construction.
Omission selects Core AUTO/MULTIPLEXING/OFF/OFF; it is not a Swift default table.
Security remains an actual pre-start atomic apply. Core validates all policy.

```swift
let host = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "orders",
        nodeID: "orders-1",
        routes: [.local("svc.orders")]
    )
)
```

Optional tuning fields are sent only when non-nil. Core owns defaults and
validates field applicability, capability, edition, network policy and lifecycle.
Swift only checks boundary type/UTF-8/NUL/span safety. Base numeric inputs are
forwarded unchanged; Core, not a mirrored Swift validator, decides zero/default
and invalid-generation behavior. A supplied connection group requires an explicit
`mode`; leave the group nil to request Core's default.

## Public Functions

| Function | Contract |
| --- | --- |
| `RuntimeHost.readRuntimeCapabilities(runtimeLibPath:)` | Resolves and synchronously loads one module; nil follows resolver order. The first canonical path remains loaded for process lifetime. All editions; throws load/ABI/native errors. |
| `capabilities.supports(_:)` | Pure owned-value check requiring every requested effective bit. No blocking or retained native memory. |
| `RuntimeTransportABI.sizes` | Reports Swift layout sizes for eleven C ABI blocks. Diagnostic only; it is not execution evidence for another OS. |
| `RuntimeHost.start(_:runtimeLibPath:)` | Creates independent hosts over one process-retained module. Core constructs accepted settings, exports handles and supplies opaque reader/client state. Credential loading may block. Fallible startup retires partial ownership. |
| `startupConfig()` / `deliveryConfig()` | Owned copies of Core's accepted settings/provenance and actual framed/owned selection. No OS probe, input reconstruction or descriptor inference. |
| `runtimeCapabilities()` | Synchronously copies capability truth; serialized with apply/close. Open host only; all editions. |
| `tcpConnectionConfig()` | Copies effective mode, tuning, and explicit/default provenance. Serialized, non-mutating, open host only. |
| `tcpSecurityInfo()` | Copies active non-secret security and certificate identity. Never returns paths, keys, PEM, or tokens. Serialized, open host only. |
| `startupTcpConnectionResult()` | Always nil for native construction: no apply occurred. Read Core startup/connection getters, never fabricate an apply result. |
| `startupTcpSecurityResult()` | Returns the owned non-secret startup result or nil when omitted. Non-blocking and valid after host close. |
| `applyTcpConnectionStrategy(_:)` | Synchronous atomic attempt. Connection mode is startup-only; a started host normally returns `badState`, `changed == false`, and unchanged active config. |
| `applyTcpSecurity(_:)` | Synchronous same-mode newer-generation TLS/mTLS reload. Strings are borrowed only for the call; file I/O may block. Failure keeps the previous active context. |
| `close()` | Throwing, retryable retirement. Seal admission, join/destroy reader before Core stop; retire client/handles/runtime only after every ask borrower exits. Failed1000ms join retains owners. Core owns descriptor close. Handler-reentrant close refuses before mutation. |

All structs returned by public transport functions own their Swift strings and
numeric data. Constructor refusal preserves Core's native status; an actual
security apply preserves its structured result. There is no partial constructor
instance whose active config may be invented. Pointer-only client construction
can report refusal without a causal code; Swift does not guess allocation or
lifecycle failure from it. Rich invalid text decoding returns nil, while text
ask/handler helpers throw; invalid text is never silently replaced with empty text.

Deadletters preserve the uint32 `reasonCode` and query the loaded Core for its
exact short `reason` label. Unknown codes remain unknown; inspection failure
throws instead of fabricating a name. The constant Core string is copied while
the module is process-retained, including completed replies projected after a
host session retires. Older registry long-label comparisons require migration.

## Connection Modes

- `.perExchange`: explicitly requested one connection per exchange.
- `.boundedPool`: bounded reusable connections; requires effective capability.
- `.persistentSingleFlight`: one retained serial connection per endpoint.
- `.multiplexing`: bounded concurrent exchanges on retained connections; Core's native constructor default.

Defaults and edition/tuning availability are canonical in
[Connection Strategies](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/reference/connection-strategies.md).

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

## Scheduling And Shutdown

Use blocking `ask`/`askPayload` only on a blocking-capable application thread.
`askPayloadAsync` offloads to eight lazy serial Dispatch wait lanes across the
process, with at most64 admitted jobs per host. Swift scheduling is not included
in Core's caller wait window; neither that wait nor task cancellation promises
remote rollback. Cancellation callbacks record intent only. The sole ticket
owner cancels/destroys before or after the original native await, never during it.

Handlers execute serially on the host request runner, without unbounded tasks.
They must return before close can finish. Failed close retains native owners and
can be retried; dropping the host requests eventual safe retirement. Runtime
and transport getters are fenced against destruction. Callback errors are
available as bounded managed dispatch diagnostics, not guessed native outcomes.

See the canonical [TLS/mTLS guide](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/reference/tls-and-mtls.md)
for Kubernetes ingress/service mesh, controlled networks, LAN/edge, Raspberry
Pi, BeagleBone, bare metal, industrial Android, and rotation guidance.

## Platforms And Signing

The package includes five admitted Core 3.0.0/1522b4a9/ABI1 native images:
macOS ARM64, Linux ARM64/x64, Windows x64 and Windows ARM64. Windows ARM64
is an evaluation preview without official support or a final3.0.0 matching-host
execution claim. Publisher signing is currently absent and documented
separately from package digests. Package presence does not replace native
execution evidence. Use [common troubleshooting](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/operations/troubleshooting.md)
for loader/CPU mismatch, dependencies, Gatekeeper, SmartScreen/Authenticode,
checksums, certificates, and signing status.

The source package's Swift product uses explicit dynamic linkage. Its module
is an app build output, not another dependency to install separately. Keep it
adjacent to the executable/resources when relocating an application; native
Core still owns runtime defaults, delivery selection and lifecycle semantics.
