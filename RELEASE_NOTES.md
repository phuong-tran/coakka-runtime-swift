# Swift Release Notes

## 3.2.1

This version uses Runtime Core 3.2, commit `f9e5a632d2d046a5b4e89d5ce0c9042aee5c7b45`,
and ABI 1. The existing connector API and package coordinate carry
forward from 3.0.0. Core 3.2 retains native address validation and interruptible Windows
shutdown under host-pipe pressure. Windows ARM64 remains an evaluation
preview.

## 3.0.0 — 2026-10-30

Released 2026-10-30 through GitHub and SwiftPM as version 3.0.0. Use product
CoAkkaRuntime and rebuild older applications against the current APIs.
Host close can throw; handle cleanup failures as well as operation failures.
Deploy the application's dynamic library and resource bundle together.

AUTO, MULTIPLEXED and monitoring-off remain the defaults. Application handlers
and business rules remain application-owned.

The package includes macOS ARM64, Linux ARM64/x64 and Windows ARM64/x64.
Swift 6.0 is the minimum; tested profiles use Apple Swift 6.2 on macOS and
Swift 6.0.3 on Linux/Windows x64. Windows ARM64 alone remains an evaluation
preview. Swift itself is a released package.

See the [Runtime 3.0.0 changelog](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/CHANGELOG.md) and
[Swift publication receipt](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/releases/2026-10-30-swift-runtime-3.0.0-github.md)
for migration, deployment guidance and platform scope. This main-branch
documentation correction does not change existing tags or release downloads.
