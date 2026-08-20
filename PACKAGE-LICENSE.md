# CoAkka Connector Package Licensing

This distribution is a multi-license aggregate. Its licenses apply by file scope;
they are not alternative licenses for the complete package.

## Connector Material: Apache-2.0

Language-level connector source, generated language bindings, type declarations,
package/build metadata, examples, and package documentation are licensed under
the Apache License, Version 2.0. The full terms are in `LICENSE`.

## CoAkka Native Material

CoAkka native shared or static libraries, native C headers, symbol files, and
native-only provenance records are licensed under the CoAkka Public Artifact
License 1.1. The full terms are in `NATIVE-LICENSE.md`.

This scope includes CoAkka payloads below `native/`, `runtimes/*/native/`,
`META-INF/native/`, or another package-specific native payload directory, plus
files explicitly identified as CoAkka native artifacts. Copying or extracting a
native payload does not change its license.

## Third-Party Material

Third-party or vendored components retain their own license terms. Their notices
are included with those components or in the package's third-party notices.

If a file contains an explicit license notice, that notice controls for that
file. Otherwise, use the scope above.
