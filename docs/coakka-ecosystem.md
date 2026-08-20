# CoAkka Ecosystem

CoAkka is an ecosystem of native-backed runtime, logger, tooling, and sample
packages. The package you are reading is one entrypoint into that ecosystem,
not the whole product surface.

## Public Repositories

| Repository | Role |
| --- | --- |
| [`coakka-samples`](https://github.com/phuong-tran/coakka-samples) | Runnable examples, scenarios, screenshots, videos, and sample commands. Start here when you want to see behavior before choosing a package. |
| [`coakka-publish`](https://github.com/phuong-tran/coakka-publish) | Public artifact mirror, release notes, compatibility matrix, package-manager status, checksums, and tool downloads. |
| [`coakka-runtime-go`](https://github.com/phuong-tran/coakka-runtime-go) | Go module for CoAkka Runtime. |
| [`coakka-logger-go`](https://github.com/phuong-tran/coakka-logger-go) | Go module for CoAkka Logger. |
| [`coakka-runtime-swift`](https://github.com/phuong-tran/coakka-runtime-swift) | SwiftPM package for CoAkka Runtime. |
| [`coakka-logger-swift`](https://github.com/phuong-tran/coakka-logger-swift) | SwiftPM package for CoAkka Logger on macOS ARM64. |

## Package-Manager Surfaces

| Channel | Runtime entrypoint | Logger entrypoint |
| --- | --- | --- |
| Maven Central | [`coakka.runtime` 2.4.1](https://central.sonatype.com/artifact/io.github.phuong-tran.coakka/runtime/2.4.1) | [`coakka.logger` 1.2.2](https://central.sonatype.com/artifact/io.github.phuong-tran.coakka/logger/1.2.2) |
| NuGet | [`CoAkka.Runtime` 2.5.0](https://www.nuget.org/packages/CoAkka.Runtime/2.5.0) | [`CoAkka.Logger` 1.2.3](https://www.nuget.org/packages/CoAkka.Logger/1.2.3) |
| npm | [`coakka-v2-connector-node` 2.5.0](https://www.npmjs.com/package/coakka-v2-connector-node/v/2.5.0) | [`coakka-logger-node` 1.2.7](https://www.npmjs.com/package/coakka-logger-node/v/1.2.7) |
| npm (Bun) | [`coakka-v2-connector-bun` 2.5.0](https://www.npmjs.com/package/coakka-v2-connector-bun/v/2.5.0) | [`coakka-logger-bun` 1.2.7](https://www.npmjs.com/package/coakka-logger-bun/v/1.2.7) |
| npm (Electron) | [`coakka-v2-connector-electron` 2.5.0](https://www.npmjs.com/package/coakka-v2-connector-electron/v/2.5.0) | [`coakka-logger-electron` 1.2.7](https://www.npmjs.com/package/coakka-logger-electron/v/1.2.7) |
| PyPI | [`coakka-v2-connector` 2.5.0](https://pypi.org/project/coakka-v2-connector/2.5.0/) | [`coakka-logger` 1.2.2](https://pypi.org/project/coakka-logger/1.2.2/) |
| Go modules | [`coakka-runtime-go` v1.8.1](https://pkg.go.dev/github.com/phuong-tran/coakka-runtime-go@v1.8.1) | [`coakka-logger-go` v1.2.6](https://pkg.go.dev/github.com/phuong-tran/coakka-logger-go@v1.2.6) |
| SwiftPM | [`coakka-runtime-swift` v2.5.1](https://github.com/phuong-tran/coakka-runtime-swift/tree/v2.5.1) | [`coakka-logger-swift` v1.2.2](https://github.com/phuong-tran/coakka-logger-swift/releases/tag/v1.2.2) |
| Maven-style tree | JVM runtime, logger, Spring Boot starter, and Quarkus extension artifacts. |
| GitHub artifact mirror | Native archives, language package mirrors, CLI tools, inspect tools, manifests, and checksums. |

Rust crates and apt/deb are planned separately. A package-manager lane is only
current after the package coordinate, public samples, release notes, and
compatibility matrix agree.

## What The Pieces Do

CoAkka Runtime gives application code a target-based delivery boundary:

```text
caller -> target name -> handler -> reply, timeout, or deadletter
```

CoAkka Logger gives application code a bounded native logging boundary:

```text
app log event -> bounded native logger -> drain, counters, and pressure evidence
```

The runtime and logger can be used independently. They are also meant to fit
together: runtime explains where work went, while logger explains what the host
emitted and what happened under pressure.

## How To Navigate

Use [`coakka-samples`](https://github.com/phuong-tran/coakka-samples) when
you want runnable proof. Use
[`coakka-publish`](https://github.com/phuong-tran/coakka-publish) when you
need exact versions, checksums, compatibility, release history, or tool
downloads. Use a language package repo when you already know the host language
you want to embed.

Important docs:

- [AI-Assisted Integration](https://github.com/phuong-tran/coakka-samples/blob/main/docs/ai-assisted-integration.md)
- [New To CoAkka](https://github.com/phuong-tran/coakka-samples/blob/main/docs/new-to-coakka.md)
- [How It Works](https://github.com/phuong-tran/coakka-samples/blob/main/docs/how-it-works.md)
- [Incremental Adoption](https://github.com/phuong-tran/coakka-samples/blob/main/docs/incremental-adoption.md)
- [Compatibility Matrix](https://github.com/phuong-tran/coakka-publish/blob/main/docs/compatibility-matrix.md)
- [Package Manager Roadmap](https://github.com/phuong-tran/coakka-publish/blob/main/docs/package-manager-roadmap.md)
