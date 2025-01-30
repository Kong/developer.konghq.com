---
title: Verify signatures for signed {{site.base_gateway}} images
content_type: how_to

related_resources:
  - text: Verify build provenance for signed {{site.base_gateway}} images
    url: /how-to/verify-build-provenance-for-signed-images/

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

tier: enterprise

tldr:
    q: How do I verify {{site.ee_product_name}} Docker image signatures?
    a: |
      {{site.base_gateway}} Docker container images are signed using [`cosign`](https://github.com/sigstore/cosign), with signatures published to the Docker Hub repository `kong/notary`.

      Because Kong uses Github Actions to build and release, Kong also uses Github’s OIDC identity to sign images.
      You can verify these signatures using the `cosign verify` command.

---

## 1. Gather the digest information

Parse the manifest digest for the image using `regctl`, substituting the {{site.ee_product_name}} image you need to verify:

```sh
regctl manifest digest kong/kong-gateway:3.9.0.0
```

The command will output a `sha`:

```sh
sha256:cb838b4090cfbfb9186be6e95fbeceabc8fdbf604400eaaca1561b1f510128eb
```
{:.no-copy-code}


## 2. Verify image signature

Run the `cosign verify` command, substituting the `sha` and image name from the previous step:

```sh
cosign verify \
  'kong/kong-gateway:3.9.0.0@sha256:cb838b4090cfbfb9186be6e95fbeceabc8fdbf604400eaaca1561b1f510128eb' \
  --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \
  --certificate-identity-regexp='https://github.com/Kong/kong-ee/.github/workflows/release.yml' \
  -a repo='Kong/kong-ee' \
  -a workflow='Package & Release'
```

If verification is successful, the response will contain a summary of the checks that were performed:
```
Verification for index.docker.io/kong/kong-gateway@sha256:cb838b4090cfbfb9186be6e95fbeceabc8fdbf604400eaaca1561b1f510128eb --
The following checks were performed on each of these signatures:
  - The specified annotations were verified.
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
```
{:.no-copy-code}