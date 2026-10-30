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

## Choose a product and version

The [current package ledger](https://github.com/phuong-tran/coakka-samples/blob/main/docs/common/current-packages.md)
records actual published versions across npm, PyPI, NuGet, Maven, Go and SwiftPM.
Each product and language channel has its own release status; a package in one
channel does not publish another.

Start with [the ecosystem guide](https://github.com/phuong-tran/coakka-samples/blob/main/docs/common/ecosystem-overview.md),
then choose [Runtime](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/README.md),
[HTTP Runtime](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-http-runtime/README.md) or
[Logger](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-logger/README.md).
The examples and documentation are organized by product.

Runtime connects application-owned work across languages and processes.
HTTP Runtime brings a shared native-backed HTTP engine to language hosts.
Logger addresses logging cost and keeps its own package versions.
Each application owns its handlers and business rules.
