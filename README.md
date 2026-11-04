# CoAkka Runtime Swift 3.2.1

![CoAkka](https://raw.githubusercontent.com/phuong-tran/coakka-samples/main/docs/common/assets/brand/coakka-logo.png)

CoAkka Runtime for Swift uses the same Core as the other connectors.
In 3.2.1, the first two numbers identify the bundled Core generation (3.2)
and the last identifies the Swift connector revision (1). The package includes
Core build `f9e5a632d` (ABI 1) and retains the public 3.0.0 Swift API.

## Install with Swift Package Manager

Add the exact dependency to your application's `Package.swift`:

```swift
.package(url: "https://github.com/phuong-tran/coakka-runtime-swift.git", exact: "3.2.1")
```

In the application target's dependencies, add:

```swift
.product(name: "CoAkkaRuntime", package: "coakka-runtime-swift")
```

Then `import CoAkkaRuntime` in your Swift source. SwiftPM builds the dynamic
library and copies the bundled Core resources. No separate Core install is
required.

The package requires Swift 6.0 or later. Tested profiles use Apple Swift 6.2
on macOS ARM64 and Swift 6.0.3 on Linux and Windows x64. Native targets are
macOS 13 ARM64, Linux ARM64 (glibc 2.35), Linux x64 (glibc 2.36) and Windows x64.
The included Windows ARM64 image is an evaluation preview; use a supported
target for production. See the
[platform evidence](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/reference/runtime-package-platform-evidence.md).

## Application ownership

Import CoAkkaRuntime, start a host with application identity/routes, register a
bounded handler and make typed requests. Follow the complete
[Swift sample](https://github.com/phuong-tran/coakka-samples/tree/main/coakka-runtime/swift/registry-basic)
for ordinary SwiftPM integration and throwing scoped cleanup.

Core owns configuration defaults, effective settings, capability probes,
request delivery, deadlines, cancellation, terminal causes and native shutdown.
Omission selects AUTO execution and MULTIPLEXED connections through Core.
Omitted queue intent forwards zero for Core normalization. Inspect accepted
Core facts rather than reporting input preferences as observed behavior.

Swift owns ARC, Swift task/callback scheduling and representation safety across
the C boundary. Borrowed native spans do not outlive their Core lease.
Callbacks retain their required owners until retirement. A failed throwing
close preserves owners for explicit retry; application cleanup must preserve
both the operation failure and a close failure.

The engine uses Core-owned delivery and doorbell wakeup intent. Legacy output
FD/pipe payload parsing is not the normal reader path. File and Stream share
the same typed status/ownership law; unknown numeric Core values remain unknown.

## Deployment

Deploy the app, dynamic CoAkkaRuntime module, its resource bundle and the
matching ordinary Swift language runtime closure together. The package resource
loader selects an owned OS/CPU image and uses application-relative bundle roots;
it does not rely on an absolute SwiftPM build-tree path. Native-path overrides
are development fixtures and are absent from installed-consumer qualification.

## Migration from 2.x

Recompile against 3.2.1. Host close is throwing; replace nonthrowing defer
cleanup with a scope that records both causal failures. Runtime values and
metadata now project the current typed Core contracts. Update names from the
current API/sample rather than copying another language's identifiers.

See [transport configuration](TRANSPORT_CONFIGURATION.md),
[release verification](RELEASE.md), [release notes](RELEASE_NOTES.md) and the
[shared documentation](https://github.com/phuong-tran/coakka-samples/blob/main/docs/README.md).

## License

Connector source uses [Apache License 2.0](LICENSE). The bundled Core uses
the [CoAkka Native Artifact License 1.2](NATIVE-LICENSE.md). See the
[package license map](PACKAGE-LICENSE.md) and [NOTICE](NOTICE).
