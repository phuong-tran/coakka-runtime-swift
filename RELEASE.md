# Swift 3 package release controls

Candidate SwiftPM version 3.0.0 uses native Core 3.0.0/1522b4a9/ABI1. Public2.5.3
and previous qualification packages remain immutable.

The bounded cold producer adopts all25 exact public SDK headers and five native
images from the admitted Runtime3.0.0 SDK for Core source
`1522b4a9f30da1039ef8c7d198bbecfc749a2456`/ABI1. Its normalized native
build input is not shipped as a separate dependency. Reject wrong versions, missing/extra/edited
SDK/native inputs, links and existing output before package creation.

Use a standard SwiftPM dynamic library with C11 and the declared Swift 6
language floor. Compile and execute coherent compiler/SDK profiles, strict
source regression, ARC/callback/failure controls, native memory/race diagnostics,
bounded fuzz, pressure and resource protocols. Qualify each advertised native
architecture and minimum OS separately; cross-compilation is not runtime proof.
Windows ARM64 is an evaluation preview without official support in this wave.
Its included payload has no final3.0.0 matching-host execution claim and is
outside the supported release qualification scope.

Execute actual whole-module/Osize/no-private-reflection/link-stripped consumers,
deployed with their application-relative resource bundle and Swift language
runtime closure. Inspect architecture, exports, dynamic imports, privacy,
legal material and the exact admitted Core 3.0.0 image identities. Keep private
maps/symbols apart. Historical qualification remains bound to its original
images and does not qualify these newer native identities.

Canonical guides, exact catalogs and samples must match the candidate. Freeze
one independently hashed seal before closeout. At a later authorized release,
verify it, prepare the reviewed public source commit/tag, establish the chosen
publisher trust and run fresh remote SwiftPM consumers before public selectors.

Private packaging does not push source, merge main, tag or publish. Signing
and notarization are absent unless separately established at release time.
