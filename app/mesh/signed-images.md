---
title: "Verify signatures for signed {{site.mesh_product_name}} images"
description: "Learn how to verify signed {{site.mesh_product_name}} Docker images using Cosign and GitHub OIDC identity for increased trust."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - security
  - docker
search_aliases:
  - Docker

min_version:
  mesh: '2.7.4'


related_resources:
  - text: Verify build provenance for signed {{site.mesh_product_name}} images
    url: /mesh/provenance-verification-images/
  - text: Verify build provenance for {{site.mesh_product_name}} binaries
    url: /mesh/provenance-verification-binaries/
  - text: Red Hat Universal Base Images
    url: /mesh/ubi-images/
---



Docker container images are now signed using `cosign` with signatures published to a Docker Hub repository.

This guide provides steps to verify signatures for signed {{site.mesh_product_name}} Docker container images with an example used to verify an image leveraging optional annotations for increased trust.

Because Kong uses GitHub Actions to build and release, Kong also uses GitHub's OIDC identity to sign images, which is why many of these details are GitHub-related.

## Prerequisites

* [`Cosign`](https://docs.sigstore.dev/system_config/installation/) is installed

* [`regctl`](https://github.com/regclient/regclient/blob/main/docs/install.md) is installed

* Collect the necessary image details

* The GitHub owner is case-sensitive (`Kong/kong-mesh` vs `kong/kong-mesh`)

### Image signature verification with `kong/kuma-cp`

The {{site.mesh_product_name}} image signature can be verified using `cosign`:

1. Set the `COSIGN_REPOSITORY` environment variable:

   ```sh
   export COSIGN_REPOSITORY=kong/notary
   ```

2. Parse the image manifest using `regctl`

   ```sh
   IMAGE_DIGEST=$(regctl manifest digest kong/kuma-cp:{{site.data.mesh_latest.version}})
   ```

3. Run the `cosign verify` command:

   ```sh
   cosign verify \
      kong/kuma-cp:{{site.data.mesh_latest.version}}@$IMAGE_DIGEST \
      --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
      --certificate-identity-regexp='https://github.com/Kong/kong-mesh/.github/workflows/kuma-_build_publish.yaml' \
      -a repo='Kong/kong-mesh' \
      -a workflow='build-test-distribute'
   ```