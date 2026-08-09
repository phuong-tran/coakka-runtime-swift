# CoAkka Runtime Swift Connector

<p align="center">
  <img src="https://raw.githubusercontent.com/phuong-tran/coakka-samples/main/docs/assets/brand/coakka-logo.png" alt="CoAkka" width="480">
</p>

**This is the Swift connector in the polyglot, multi-language, multi-platform
CoAkka Runtime ecosystem.** CoAkka is not a Swift-only runtime: this package
adapts Swift applications to the same native core, public C ABI, target,
request/reply, bounded-admission, and deadletter contract used by C++, the JVM,
Node.js, Python, Go, C#, Rust, and other connector lanes.

SwiftPM exposes
request/reply, local handlers, deadletters, diagnostics, capability discovery,
connection strategy, and atomic TLS/mTLS credential reload over the public C
ABI.

Current source version: `2.1.1`<br>
Bundled runtime: `2.1.0+60ddf70d`; publisher signing: absent.

## Ecosystem

CoAkka is a polyglot native runtime with connectors for
C++, JVM/Kotlin, Spring Boot, Quarkus, JavaScript/Node/Bun, Python, Go, C#,
Rust, and Swift. Connector availability and native execution evidence are
tracked separately so a package file is never presented as proof that its
target runtime executed.

Kubernetes is supported but not required. The same runtime contract applies to
standalone hosts, containers, VMs, bare metal, and architecture-matched edge
deployments. Use the public
[Ecosystem Overview](https://github.com/phuong-tran/coakka-publish/blob/main/docs/ecosystem-overview.md)
and [Compatibility Matrix](https://github.com/phuong-tran/coakka-publish/blob/main/docs/compatibility-matrix.md)
for exact package and native-platform evidence.
The [package and platform evidence ledger](https://github.com/phuong-tran/coakka-publish/blob/main/docs/runtime-package-platform-evidence.md)
separates payload presence, verification, matching-host execution, and known
release limitations.
Start with the [CoAkka Documentation](https://github.com/phuong-tran/coakka-samples/blob/main/docs/README.md)
for concepts, integration paths, operations, and runnable samples.

| Package target | Included native | Package evidence |
| --- | --- | --- |
| macOS ARM64 | `libcoakka_runtime_v2.dylib` | Swift tests, request/reply, transport, and TLS reload pass |
| Linux ARM64 | `libcoakka_runtime_v2.so` | Exact digest, ELF format, and strict C-bridge compilation pass; no Swift toolchain execution claim |
| Linux x86-64 | `libcoakka_runtime_v2.so` | Exact digest, ELF format, and strict C-bridge compilation pass; no Swift toolchain execution claim |
| Windows ARM64 | `libcoakka_runtime_v2.dll` | Exact digest and PE format pass; no Swift toolchain execution claim |
| Windows x86-64 | `libcoakka_runtime_v2.dll` | Exact digest and PE format pass; no Swift toolchain execution claim |

Linux remains the primary deployment target for the runtime ecosystem. The
Swift package includes both supported CPU architectures for Linux and Windows
alongside macOS ARM64; a
platform-specific execution result does not remove another platform from the
distribution.

## First Run

```sh
bash scripts/smoke-package.sh
```

The package resolver uses an explicit path first, then `COAKKA_RUNTIME_LIB`,
then the legacy `COAKKA_RUNTIME_NATIVE_PATH`, then the bundled native for the
current OS/architecture.

```swift
import CoAkkaRuntime

let capabilities = try RuntimeHost.readRuntimeCapabilities()
let mode: TcpConnectionMode = capabilities.supports(.tcpBoundedPool)
    ? .boundedPool
    : .perExchange

let runtime = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "orders",
        nodeID: "orders-swift-1",
        routes: [.local("svc.orders")],
        connectionStrategy: TcpConnectionStrategySpec(mode: mode),
        security: TcpSecuritySpec()
    )
)
defer { runtime.close() }

try runtime.registerTextHandler("svc.orders") { request in
    "accepted-\(request)"
}

let response = try runtime.askText(
    source: "orders-client",
    target: "svc.orders",
    payload: "order-42",
    deliveryHint: .requireLocal
)
print(response)
```

Connection strategy is startup-configured. TLS/mTLS may reload only a newer
credential generation in the same active security mode; a rejected reload
keeps the previous immutable TLS context active. See
[Swift transport configuration](TRANSPORT_CONFIGURATION.md).

## Package Gates

```sh
bash scripts/verify-native-payload.sh
swift test
swift run CoAkkaRuntimeSmoke
swift run CoAkkaRuntimeTransportSmoke
bash scripts/check-platform-bridge-source.sh
bash scripts/smoke-consumer.sh
bash scripts/check-package-readiness.sh
```

These checks verify source, all five exact native payloads, the macOS Swift
consumer path, and the cross-platform C bridge source boundary. They do not
turn bridge compilation on Linux or payload inspection on Windows into a Swift
execution claim.

## C Bridge Contract

The Swift package's public C boundary is documented at the declaration site in
[`coakka_runtime_bridge.h`](Sources/CoAkkaRuntimeC/include/coakka_runtime_bridge.h).
Every bridge function states its blocking behavior, borrowed and transferred
ownership, object lifetime, lifecycle restrictions, structured failure path,
and capability/edition behavior. The bridge performs no hidden serialization;
`RuntimeHost` supplies the Swift-side locks that keep close, transport apply,
ticket use, and frame-reader use from racing.

## Documentation And Support

- [Connection strategies](https://github.com/phuong-tran/coakka-publish/blob/main/docs/connection-strategies.md)
- [TLS/mTLS](https://github.com/phuong-tran/coakka-publish/blob/main/docs/tls-and-mtls.md)
- [Common troubleshooting](https://github.com/phuong-tran/coakka-publish/blob/main/docs/troubleshooting.md), including unsigned macOS/Windows artifacts and Linux loader checks
- [Contact and support](https://github.com/phuong-tran/coakka-publish/blob/main/docs/contact-and-support.md)
- Issues: https://github.com/phuong-tran/coakka-publish/issues
- Contact: `gabrielgun1983@gmail.com`

The connector source license is in [LICENSE](LICENSE). Native artifact terms
are described in [NATIVE-LICENSE.md](NATIVE-LICENSE.md).

## File Lane

`FileLane.open(...)` exposes the independent native bulk-transfer lane through
the C bridge. Native waits are blocking. See the shared
[file-lane contract](https://github.com/phuong-tran/coakka-publish/blob/main/docs/runtime-file-transfer.md)
for ownership and release requirements.
