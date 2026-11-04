# Verifying Swift connector 3.2.1

The GitHub tag `v3.2.1` identifies the SwiftPM package with bundled Core 3.2,
build `f9e5a632d2d046a5b4e89d5ce0c9042aee5c7b45`, ABI 1. Resolve the
exact version with `swift package resolve` and check the tag's commit against
the revision in `Package.resolved`.

From the tagged checkout or extracted GitHub release archive, run
`shasum -a 256 -c SHA256SUMS` to verify the file inventory. The GitHub release
also supplies a SHA-256 sidecar for the attached archive.

The archive checksum verifies the download bytes. This release does not
add publisher signing or notarization. See the [README](README.md) for
installation and deployment requirements.
