---
title: "Verify build provenance for signed {{site.mesh_product_name}} images"
description: "Learn how to verify build provenance for signed {{site.mesh_product_name}} Docker container images using Cosign or slsa-verifier."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.8'

tags:
  - provenance

works_on:
  - on-prem
  - konnect

related_resources:
  - text: "Verify signatures for signed {{site.mesh_product_name}} images"
    url: /mesh/signed-images/
  - text: "FIPS Support"
    url: /mesh/enterprise/#fips-140-2-support
  - text: Verify build provenance for {{site.mesh_product_name}} binaries
    url: /mesh/provenance-verification-binaries/
  - text: "Red Hat Universal Base Images"
    url: /mesh/ubi-images/
---

{{site.mesh_product_name}} produces build provenance for Docker container images, which can be verified using `cosign` / `slsa-verifier` with attestations published to a Docker Hub repository.

This guide provides steps to verify build provenance for signed {{site.mesh_product_name}} Docker container images with an example to verify an image provenance leveraging any optional annotations for increased trust.

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to generate build provenance for container images, which is why many of these details are GitHub-related.

## Prerequisites

* [`Cosign`](https://docs.sigstore.dev/system_config/installation/) / [`slsa-verifier`](https://github.com/slsa-framework/slsa-verifier?tab=readme-ov-file#installation) is installed

* [`regctl`](https://github.com/regclient/regclient/blob/main/docs/install.md) is installed

* Collect the necessary image details.

* The GitHub owner is case-sensitive (`Kong/kong-mesh` vs `kong/kong-mesh`).

## Image provenance example with kong/kuma-cp

{{site.mesh_product_name}} image provenance can be verified using `cosign` or `slsa-verifier`:

{% navtabs "example" %}
{% navtab "cosign" %}

1. Set the `COSIGN_REPOSITORY` environment variable:

   ```sh
   export COSIGN_REPOSITORY=kong/notary
   ```

2. Parse the image manifest using `regctl`:

   ```sh
   export IMAGE_DIGEST=$(regctl manifest digest kong/kuma-cp:{{site.data.mesh_latest.version}})
   ```

3. Run the `cosign verify-attestation ...` command:

   ```sh
   cosign verify-attestation \
      kong/kuma-cp:{{site.data.mesh_latest.version}}@$IMAGE_DIGEST \
      --type='slsaprovenance' \
      --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
      --certificate-identity-regexp='^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$' \
      --certificate-github-workflow-repository='Kong/kong-mesh' \
      --certificate-github-workflow-name='build-test-distribute' \
      --certificate-github-workflow-trigger='push'
   ```

{% endnavtab %}

{% navtab "slsa-verifier" %}

1. Parse the image manifest using `regctl`

   ```sh
   export IMAGE_DIGEST=$(regctl manifest digest kong/kuma-cp:{{site.data.mesh_latest.version}})
   ```

2. Run the `slsa-verifier verify-image ...` command:

   ```sh
   slsa-verifier verify-image \
      kong/kuma-cp:{{site.data.mesh_latest.version}}@$IMAGE_DIGEST \
      --print-provenance \
      --provenance-repository 'kong/notary' \
      --source-uri 'github.com/Kong/kong-mesh' \
      --source-tag '{{site.data.mesh_latest.version}}'
   ```

{% endnavtab %}
{% endnavtabs %}