# CoAkka Runtime Swift Connector

[![CI](https://github.com/phuong-tran/coakka-runtime-swift/actions/workflows/swift-ci.yml/badge.svg)](https://github.com/phuong-tran/coakka-runtime-swift/actions/workflows/swift-ci.yml)
[![Version](https://img.shields.io/badge/version-v1.3.2-blue)](https://github.com/phuong-tran/coakka-runtime-swift/releases/tag/v1.3.2)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)
[![Funding](https://img.shields.io/badge/funding-Ko--fi-ff5f5f)](https://ko-fi.com/phuongnamtran)

SwiftPM connector package for the CoAkka runtime v2.

The current Swift runtime lane targets macOS ARM64. Mobile platforms are not
part of this release plan.

## New To CoAkka

CoAkka is a native-backed runtime and logger toolkit for application-owned
work. It helps an app route work by target name, handle request/reply,
deadletters, bounded queues, diagnostics, and native-backed logging without
turning every internal boundary into another hand-written HTTP endpoint.

Use these public repositories to orient first:

| Repository | Use it for | Link |
| --- | --- | --- |
| `coakka-samples` | Runnable examples and code you can inspect first. | https://github.com/phuong-tran/coakka-samples |
| `coakka-publish` | Released packages, native archives, manifests, checksums, compatibility matrix, and release notes. | https://github.com/phuong-tran/coakka-publish |

## First Run From Source

```sh
bash scripts/smoke-package.sh
```

The smoke stages the macOS ARM64 native runtime library, runs `swift test`, and
executes the package smoke binary.

Run a clean SwiftPM consumer smoke:

```sh
bash scripts/smoke-consumer.sh
```

Export the package into a public SwiftPM repository checkout:

```sh
bash scripts/export-module-repo.sh ../coakka-runtime-swift
```

## API Shape

```swift
import CoAkkaRuntime

let runtime = try RuntimeHost.start(
    ConnectorStartSpec(
        systemName: "swift-first-run",
        nodeID: "swift-first-run-node",
        routes: [.local("svc.echo")]
    )
)
defer {
    runtime.close()
}

try runtime.registerTextHandler("svc.echo") { request in
    "echo-\(request)"
}

let response = try runtime.askText(
    source: "swift-first-run",
    target: "svc.echo",
    payload: "hello",
    timeoutMs: 2_000,
    deliveryHint: .requireLocal
)

print(response)
```

The Swift API is intentionally small:

- `RuntimeHost.start(...)` owns one runtime instance in the current process
- `registerHandler(...)` and `registerTextHandler(...)` own local target work
- `ask(...)` and `askText(...)` drive request/reply by target name
- route misses surface as `RuntimeError.deadletter(...)`
- `runtimeInfo()`, `runtimeConfig()`, `health()`, and `stats()` expose the diagnostics needed for smoke and operations

## Gradual Adoption

You do not need to replace an existing app boundary all at once. Start with one
painful internal call path, give it a stable target name, and let CoAkka handle
local dispatch, bounded queues, request/reply, and deadletter evidence there.

That keeps legacy HTTP, queues, or in-process calls around the rest of the app
while the new boundary proves itself with a small blast radius.

## Native Payload

The package wraps the public runtime C ABI and bundles one macOS ARM64 native
runtime library staged from:

```text
coakka-runtime-native-v2 1.3.2+caff6d6d
```

The bundled resource is:

```text
Sources/CoAkkaRuntime/Resources/macos-aarch64/libcoakka_runtime_v2.dylib
```

There should be no Linux `.so` files or Windows `.dll` files in this Swift lane.
Verify that payload shape directly:

```sh
bash scripts/verify-native-payload.sh
```
