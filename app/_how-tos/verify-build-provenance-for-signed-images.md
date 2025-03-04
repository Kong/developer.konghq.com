---
title: Verify build provenance for signed {{site.base_gateway}} images
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
      {{site.base_gateway}} Docker container images are signed using [`cosign`](https://github.com/sigstore/cosign), with signatures published to the Docker Hub repository `kong/notary`.

      Because Kong uses Github Actions to build and release, Kong also uses Github’s OIDC identity to sign images.
      You can verify these signatures using the `cosign verify` command.


---

@todo