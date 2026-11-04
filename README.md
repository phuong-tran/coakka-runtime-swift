# CoAkka Runtime Swift 3.2.1

The Swift connector embeds the same CoAkka native runtime used by the other
language connectors. The package uses SwiftPM version 3.2.1 over native
Core 3.2/f9e5a632d/ABI1. It retains the public 3.0.0 API.

## Package and build requirements

The product is the dynamic SwiftPM library CoAkkaRuntime, backed by a small
C11 representation bridge and exact packaged native images. No application
installs a separate Core/provider library or message-codec dependency.

Use the admitted local package through a SwiftPM path dependency during
preflight. Use the exact version when installing from GitHub.

```swift
.package(url: "https://github.com/phuong-tran/coakka-runtime-swift.git", exact: "3.2.1")
```

The manifest/language floor is Swift6.0. Coherent qualification profiles are
Apple Swift6.2 on macOS, Swift6.0.3 on Linux/Windows x64, and Swift6.4.1 with
SwiftPM's native build system on Windows ARM64. These are distinct compiler/SDK profiles; one platform's
toolchain execution does not prove another. Native targets are macOS13 ARM64,
Linux ARM64 glibc2.35, Linux x64 glibc2.36, Windows10 x64 and Windows11 ARM64.
Consult the package qualification record for matching-host and minimum-OS results.

Windows ARM64 is a preview target for this 3.2.1 wave and has no official
support claim. Its native payload remains included for evaluation. Use the
qualified macOS, Linux or Windows x64 profiles for the supported release scope.

## Application ownership

Import CoAkkaRuntime, start a host with application identity/routes, register a
bounded handler and make typed requests. Follow the complete
[Swift sample](https://github.com/phuong-tran/coakka-samples/tree/main/coakka-runtime/swift)
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

The qualification uses whole-module size optimization, disabled private
reflection metadata and linker dead stripping. Required public Swift/C lookup
names remain available. Private debug/symbol companions stay outside consumer
packages. Optimized installed apps must execute after moving away from sources.

## Migration from2.x

Recompile against 3.2.1. Host close is throwing; replace nonthrowing defer
cleanup with a scope that records both causal failures. Runtime values and
metadata now project the current typed Core contracts. Update names from the
current API/sample rather than copying another language's identifiers.

See [transport configuration](TRANSPORT_CONFIGURATION.md),
[release controls](RELEASE.md), [release notes](RELEASE_NOTES.md) and the
[shared documentation](https://github.com/phuong-tran/coakka-samples/blob/main/docs/README.md).

## License

Connector source uses Apache2.0; bundled native images use the file-scoped
CoAkka Native Artifact License1.2. Preserve LICENSE, NOTICE, NATIVE-LICENSE.md
and PACKAGE-LICENSE.md. Publisher signing is absent.
