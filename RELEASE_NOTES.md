# Swift Connector Release Notes

## 1.4.0

- Exact Swift views for all eleven public transport ABI blocks.
- Capability-driven startup connection/security policy before handle export.
- Structured atomic apply results and same-mode TLS/mTLS credential reload.
- Failed key validation preserves the active TLS generation and fingerprint.
- Process-lifetime native module identity and exact exported-fd cleanup.
- Native loading for macOS, Linux, and Windows without POSIX-only bridge APIs.
- Function-level C bridge documentation for lifecycle, ownership, blocking,
  thread serialization, atomicity, and capability-gated errors.
- Exact three-platform payload with digest and binary-format gates.

Swift tests, request/reply, transport rejection, and TLS reload pass
on macOS ARM64. Linux ARM64 and Windows x86-64 package payloads are included;
this package receipt makes no Swift connector execution claim for those targets.

Publisher signing is absent and is explained in
[common troubleshooting](https://github.com/phuong-tran/coakka-publish/blob/main/docs/troubleshooting.md).

Contact: `gabrielgun1983@gmail.com` or the public issue tracker.
