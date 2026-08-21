# Releasing The Swift Connector

Current source version is `2.5.3`, paired with native
generation `2.5.1+26f7944de4a4e0598845a54e4775f9463a9e33be`; publisher signing is absent.

The macOS ARM64 payload is rebuilt from exact native source snapshot
`26f7944de4a4e0598845a54e4775f9463a9e33be` with deployment target `13.0`.
Its SHA-256 is
`277d9ff36b017f2eef2e630ac82bb9ba68f112879297e8067521fe665f82368a`.
All five native payloads remain byte-identical to generation
`2.5.1+26f7944de4a4e0598845a54e4775f9463a9e33be`.

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

The package contains the exact macOS ARM64 dylib, both Linux shared objects,
and both Windows DLLs. All five digests are fixed in the
verifier. Package presence and source compilation are not Linux/Windows Swift
execution evidence.

`xcrun vtool -show-build` must report macOS `minos 13.0` for the bundled
dylib. Running the package on a newer macOS ARM64 host is not evidence that it
was executed on macOS 13.

The checks above build and consume a local SwiftPM archive. Package presence
and bridge compilation are reported separately from native connector execution
on each target.
