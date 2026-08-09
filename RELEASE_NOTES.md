# Swift Connector Release Notes

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
[common troubleshooting](https://github.com/phuong-tran/coakka-publish/blob/main/docs/troubleshooting.md).

Contact: `gabrielgun1983@gmail.com` or the public issue tracker.
