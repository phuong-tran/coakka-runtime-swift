# Swift 3.0.0 candidate notes

New API baseline over native Core 3.0.0/1522b4a9/ABI1; public 2.5.3 is unchanged.
Host close is now throwing. Recompile and preserve operation/cleanup failures
together using the current sample's scoped ownership pattern.

Core resolves omitted startup/queue intent. AUTO/MULTIPLEXED defaults,
capabilities, delivery, terminal causes and native lifecycle remain Core-owned.
Swift retains ARC/task/callback and FFI representation responsibilities.

The source package now adopts the exact25-header/five-image native family.
Its C bridge projects the current public Core member names; its resource loader
adds Linux x64 and Windows ARM64 image selection without probing Core policy.
Connector packaging copies the admitted Core 3.0.0 images without rebuilding or
patching them. Their version/build identities differ from the historical P489
images; Core ABI, processing and hot-path algorithms remain unchanged.
Windows ARM64 is preview without official support or a final3.0.0 matching-host
execution claim.

Actual source, optimized installed, ARC/resource and platform evidence governs
the selected target/profile support. Presence or cross-build output alone is
not matching execution. Packaging does not authorize publication or signing.
