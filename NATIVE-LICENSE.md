# CoAkka Public Artifact License 1.1

Effective: 2026-08-03

This repository is the public binary artifact surface for CoAkka. It contains
headers, native libraries, connector packages, Maven artifacts, checksums, and
artifact metadata. It is not a source-build repository.

Unless a specific artifact includes explicitly different license terms, the
Licensor makes the Artifacts available under this license. Version 1.1 replaces
version 1.0 for all Artifacts currently distributed from this repository or an
official release page, including Artifacts first published before the effective
date. An embedded copy of CoAkka Public Artifact License 1.0 is superseded by
this version and is not an explicitly different artifact-specific license.

This is a public-use artifact license, not an OSI-approved open source license.
The separate `coakka-samples` repository may use a permissive open source
license for sample code and documentation; that sample license does not change
the terms for the Artifacts.

## Definitions

`Licensor` means the copyright owner or entity authorized to distribute the
Artifacts under this license.

`Artifacts` means the CoAkka binaries, headers, libraries, connector packages,
Maven artifacts, container-bundle files, checksums, manifests, and release
metadata distributed from this repository or an official release page.

`Application` means a product or service that uses the Artifacts as an internal
component to provide functionality independent from CoAkka. CoAkka is not the
primary product offered to the application's users, and those users are not
given a hosted CoAkka runtime or substantially equivalent CoAkka service.

`Managed CoAkka Service` means a product or service offered to third parties
whose primary or substantial value is providing hosted access to CoAkka's
runtime, connector, routing, delivery, management, or substantially equivalent
functionality. This includes a hosted CoAkka runtime, a CoAkka control plane, a
service through which customers deploy or operate workloads directly against
CoAkka, and an appliance or cloud image whose primary purpose is to provide
CoAkka functionality.

## License Grant And Allowed Use

Subject to this license, the Licensor grants you a non-exclusive, worldwide,
royalty-free license to download, copy, and use the Artifacts, and to
redistribute unmodified Artifacts as part of an Application.

You may, without a separate agreement:

- use every capability included in an Artifact in development, test, CI,
  evaluation, proof-of-concept, and production environments
- use the Artifacts for internal business operations and commercial workloads
- build, operate, sell, and distribute Applications that use or bundle
  unmodified Artifacts
- operate a SaaS, hosted application, or customer-facing service that uses the
  Artifacts as an internal component, provided the offering is not a Managed
  CoAkka Service
- reproduce and cache unmodified Artifacts inside your organization and its
  controlled build, deployment, and support environments
- run and internally cache official CoAkka sample images
- provide integration, consulting, and support services for Applications that
  use CoAkka, provided those services do not offer a Managed CoAkka Service

These permissions apply equally to individuals and organizations regardless of
their size or industry. A cloud provider or other infrastructure company may
use CoAkka internally and in its independent Applications on the same terms as
any other user. The restriction below is based on what is offered to third
parties, not on the identity of the user.

When redistributing an Artifact with an Application, you must preserve the
applicable copyright, license, trademark, checksum, and provenance notices and
make a copy of this license available with the redistributed Artifact.

## Reserved Uses

The following uses require a separate written agreement with the Licensor:

- selling, hosting, or offering a Managed CoAkka Service
- selling, licensing, renting, or redistributing the Artifacts as a standalone
  product or where the Artifacts provide the primary or substantial value of
  the offering
- publishing an appliance, container image, cloud image, runtime platform, or
  marketplace offering whose primary purpose is to provide CoAkka functionality
- presenting modified, repackaged, or third-party Artifacts as official CoAkka
  Artifacts

You may not:

- remove or obscure copyright, license, trademark, checksum, or provenance
  notices
- reverse engineer or modify the Artifacts except where that restriction is
  prohibited by applicable law
- use the CoAkka name, package names, artifact names, image names, or other
  project identifiers in a way that implies endorsement of an unofficial fork,
  hosted service, or product

## No Runtime Activation Gate

This license states legal permissions and restrictions; it is not a runtime
activation mechanism. Publisher signing, platform trust, checksums, release
receipts, capability introspection, and runtime license-status fields do not
create an additional feature or production-use fee for an Artifact distributed
under this license. Local operating-system or organization security policy may
still require its own signing, integrity, or admission checks.

## No Warranty

The Artifacts are provided as-is, without warranties or conditions of any kind,
to the maximum extent permitted by applicable law.

## Limitation Of Liability

To the maximum extent permitted by applicable law, the project contributors and
artifact publishers are not liable for any direct, indirect, incidental,
special, consequential, exemplary, or other damages arising from use of the
Artifacts.

## No Patent Or Trademark Grant

These terms do not grant patent rights, trademark ownership, or rights to use
the CoAkka name beyond truthful reference to the project, compatible
integrations, and unmodified official Artifacts. Trademark use is governed by
`TRADEMARKS.md`.

## Questions

For questions about whether an offering is a Managed CoAkka Service or requires
a separate agreement, use the contact path in `SUPPORT.md`.

## Legal Notice

This file is not legal advice. If intended use depends on legal interpretation
of these terms, consult qualified counsel or request a separate written
agreement.
