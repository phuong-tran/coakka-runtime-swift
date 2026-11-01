# Swift 3.0.0 Release Notes

Released 2026-10-30 through GitHub and SwiftPM as exact 3.0.0. Use product
CoAkkaRuntime. This is a new API baseline over Core 3.0.0/1522b4a9/ABI1:
migrate and recompile 2.x callers. Host close is throwing; preserve both an
operation failure and a cleanup failure. The dynamic library and its resource
bundle deploy together.

Core retains AUTO/MULTIPLEXED/monitor-off defaults, capabilities, delivery and
terminal decisions. Swift owns values, ARC/task/callback representation and
required boundary lifetimes. Application handlers remain application-owned.

The package includes five native images and their public headers without
redesigning Core's processing. Manifest/language floor is Swift 6.0; qualified
profiles use Apple Swift 6.2 on macOS and Swift 6.0.3 on Linux/Windows x64.
Windows ARM64 alone remains an evaluation preview. Swift itself is a released
package, and presence/cross-build output does not establish an additional OS
or toolchain profile.

See the [Runtime 3.0.0 changelog](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/CHANGELOG.md) and
[Swift publication receipt](https://github.com/phuong-tran/coakka-samples/blob/main/docs/coakka-runtime/releases/2026-10-30-swift-runtime-3.0.0-github.md).
Historical 2.x tags, the v3.0.0 tag and release assets remain unchanged; this
main-branch note corrects the earlier preparation wording.
