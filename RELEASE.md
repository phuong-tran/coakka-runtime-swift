# Releasing The Swift Connector

Current source version is `1.4.0`, paired with native
generation `1.4.0+2cee86bf`; publisher signing is absent.

## Package Verification

```sh
swift test
swift run CoAkkaRuntimeSmoke
swift run CoAkkaRuntimeTransportSmoke
bash scripts/verify-native-payload.sh
bash scripts/check-platform-bridge-source.sh
bash scripts/smoke-consumer.sh
bash scripts/check-package-readiness.sh
```

The package contains the exact macOS ARM64 dylib, Linux
ARM64 shared object, and Windows x86-64 DLL. All three digests are fixed in the
verifier. Package presence and source compilation are not Linux/Windows Swift
execution evidence.

The checks above build and consume a local SwiftPM archive. Package presence
and bridge compilation are reported separately from native connector execution
on each target.
