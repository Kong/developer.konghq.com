---
title: Verify signatures for signed {{site.base_gateway}} images
content_type: how_to
related_resources:
  - text: Verify build provenance for signed {{site.base_gateway}} images
    url: /how-to/verify-build-provenance-for-signed-images/

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
    q: How do I verify {{site.ee_product_name}} Docker image signatures?
    a: |
      {{site.base_gateway}} Docker container images are signed using [`cosign`](https://github.com/sigstore/cosign), with signatures published to the Docker Hub repository `kong/notary`.

      Because Kong uses Github Actions to build and release, Kong also uses Github’s OIDC identity to sign images.
      You can verify these signatures using the `cosign verify` command.

tools:
    - deck

prereqs:
  inline:
  - title: Cosign
    include_content: prereqs/cosign
    icon_url: /assets/icons/cosign.svg
  - title: regctl
    include_content: prereqs/regctl
    icon_url: /assets/icons/code.svg
---


## 1. Gather the digest information

Parse the manifest digest for the image using `regctl`:

```sh
regctl manifest digest kong/kong-gateway:{{page.release}}
```

The command will output a `sha`:

```sh
sha256:cb838b4090cfbfb9186be6e95fbeceabc8fdbf604400eaaca1561b1f510128eb
```

## 2. 