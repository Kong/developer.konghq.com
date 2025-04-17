---
title: "Verify Build Provenance for {{site.mesh_product_name}} Binaries"
description: "Verify the build provenance of signed {{site.mesh_product_name}} binary artifacts."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - slsa
  - provenance
  - binaries
  - supply-chain
  - security

works_on:
  - on-prem

related_resources:
  - text: "Verify signatures for signed {{site.mesh_product_name}} images"
    url: /mesh/signed-images/
  - text: "Verify build provenance for signed {{site.mesh_product_name}} images"
    url: /mesh/provenance-verification-images/
  - text: "Software Bill of Materials"
    url: /mesh/sbom/
---


Starting with 2.8.0, {{site.mesh_product_name}} produces build provenance for binary artifacts, which can be verified using `slsa-verifier` with attestations published to a Docker Hub repository.

This guide provides steps to verify build provenance for signed {{site.mesh_product_name}} binary artifacts with an example leveraging optional annotations for increased trust.

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to generate build provenance for binary artifacts, which is why many of these details are GitHub-related.

## Prerequisites

* [`slsa-verifier`](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#installation) is installed.

* [Download security assets](https://packages.konghq.com/public/kong-mesh-binaries-release/raw/names/security-assets/versions/{{page.version}}/security-assets.tar.gz) for the required version of {{site.mesh_product_name}} binaries

* Extract the downloaded `security-assets.tar.gz` to access the provenance file `kong-mesh.intoto.jsonl`

   ```sh
   tar -xvzf security-assets.tar.gz
   ```

* [Download compressed binaries](https://cloudsmith.io/~kong/repos/kong-mesh-binaries-release/packages/?q=name%3Akong-mesh-*+version%3A{{page.version}}) for the required version  of {{site.mesh_product_name}}

* The GitHub owner is case-sensitive (`Kong/kong-mesh` vs `kong/kong-mesh`).

## Example


1. Change to directory where the `security-assets.tar.gz` and compressed binaries are downloaded

2. Run the `slsa-verifier verify-artifact ...` command:

   ```sh
   slsa-verifier verify-artifact \
      --print-provenance \
      --provenance-path 'kong-mesh.intoto.jsonl' \
      --source-uri 'github.com/Kong/kong-mesh' \
      --source-tag '{{page.version}}' \
      kong-mesh-{{page.version}}-*-*.tar.gz
   ```

