# Swift Connector Release Notes

## 2.5.2

- Adds `Codable` File and Stream Lane owner grants with public control-plane
  construction, exact-owner endpoint pinning, and live owner-aware tests.
- Documents transfer-scoped File grants and single-admission Stream grants.
- Keeps all five payloads at native generation
  `2.5.0+4b65d0b2256037bf7fc180bfa6df8c41efc1dd6a`.

## 2.5.1

- Corrects public documentation and adopts the file-scoped Apache-2.0 and
  CoAkka Native Artifact License 1.2 package map.
- Keeps Swift APIs, native ABI, and all five native payloads unchanged.

## 2.5.0

- Adds File Lane and Stream Lane to the Swift source package.
- Embeds all five payloads from exact native generation
  `2.5.0+4b65d0b2256037bf7fc180bfa6df8c41efc1dd6a`.

## 2.4.1

- Rebuilt the bundled macOS ARM64 runtime dylib from exact native snapshot
  `c2f53117f991f67f809a0bf46bac2ce26091eb78` with deployment target `13.0`.
- Pinned the corrected dylib SHA-256 and rejected higher Mach-O minimum OS
  versions during package verification.
- Kept Swift tools `6.0`, the Swift API, native ABI and generation
  `2.4.0+c2f53117`, and the Linux and Windows payloads unchanged.

## 2.4.0

- Added explicit embedded, outbound-only, and network-node startup modes.
- Embedded and outbound-only runtimes do not listen and report local port `0`.
- Embedded exact native generation `2.4.0+c2f53117` for all five supported
  platforms.

## 2.3.0

- Added Stream Lane with C-bridge callback ownership, copied public
  projections, credit and pressure snapshots, and condition-serialized close.
- Embedded exact native generation `2.3.0+a83ab412` for all five supported
  platforms.

## 2.1.0

- Added `FileLane` with typed sender/receiver configuration, SHA-256, receive
  preparation, send submission, blocking progress waits, cancellation,
  terminal-record cleanup, stats, and explicit close.
- Embedded exact native generation `2.1.0+60ddf70d` for Linux ARM64/x86-64,
  macOS ARM64, and Windows ARM64/x86-64.
- Verified Swift build, package payloads, clean macOS consumer execution, and a
  multi-quantum macOS ARM64 file transfer with SHA-256 equality.
- Kept paths, authorization tokens, and TLS credential material out of copied
  transfer snapshots.

## 1.4.1

- Exact Swift views for all eleven public transport ABI blocks.
- Capability-driven startup connection/security policy before handle export.
- Structured atomic apply results and same-mode TLS/mTLS credential reload.
- Failed key validation preserves the active TLS generation and fingerprint.
- Process-lifetime native module identity and exact exported-fd cleanup.
- Native loading for macOS, Linux, and Windows without POSIX-only bridge APIs.
- Function-level C bridge documentation for lifecycle, ownership, blocking,
  thread serialization, atomicity, and capability-gated errors.
- Exact five-platform payload with digest and binary-format gates.

Swift tests, request/reply, transport rejection, and TLS reload pass
on macOS ARM64. Linux ARM64 and Windows x86-64 package payloads are included;
this package receipt makes no Swift connector execution claim for those targets.

Publisher signing is absent and is explained in
[common troubleshooting](https://github.com/phuong-tran/coakka-samples/blob/main/docs/troubleshooting.md).

Contact: `gabrielgun1983@gmail.com` or the public issue tracker.
