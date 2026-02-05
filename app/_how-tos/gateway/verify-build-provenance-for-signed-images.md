---
title: Verify build provenance for signed {{site.base_gateway}} images
permalink: /how-to/verify-build-provenance-for-signed-images/
description: Use Cosign and regctl to verify build provenance for signed {{site.base_gateway}} images.
content_type: how_to
related_resources:
  - text: Verify signatures for signed {{site.base_gateway}} images
    url: /how-to/verify-signatures-for-signed-images/

prereqs:
  skip_product: true
  inline:
  - title: Cosign
    include_content: prereqs/cosign
    icon_url: /assets/icons/cosign.svg
  - title: regctl
    include_content: prereqs/regctl
    icon_url: /assets/icons/code.svg

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.5'

tags:
    - docker

tldr:
    q: How do I verify {{site.ee_product_name}} Docker build provenance?
    a: |
      Use `regctl` to gather the digest information for the image, then use `cosign verify-attestation` to verify build provenance.

automated_tests: false
---

## Gather the digest information

{% include how-tos/steps/manifest-digest.md %}

## Verify the build provenance

Run the `cosign verify-attestation` command, substituting the `SHA-256` digest and image name from the previous step:

```sh
cosign verify-attestation \
  kong/kong-gateway:3.10.0.0@sha256:ad58cd7175a0571b1e7c226f88ade0164e5fd50b12f4da8d373e0acc82547495 \
  --type='slsaprovenance' \
  --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
  --certificate-identity-regexp='^https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v[0-9]+.[0-9]+.[0-9]+$'
```

Make sure that you've set the `COSIGN_REPOSITORY` in the [prerequisites](#prerequisites), or Cosign won't be able to find the image signature.

If verification is successful, the response will contain a summary of the checks that were performed:
```
Verification for kong/kong-gateway:3.10.0.0@sha256:ad58cd7175a0571b1e7c226f88ade0164e5fd50b12f4da8d373e0acc82547495 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
```
{:.no-copy-code}

