---
title: Encrypt sensitive data in {{site.base_gateway}} with a Keyring
content_type: how_to
related_resources:
  - text: Keyring
    url: /gateway/entities/keyring

products:
    - gateway

works_on:
    - on-prem
    - konnect

tldr:
    q: How do I configure a Keyring to encrypt data?
    a: |
        Generate an RSA key pair, then set the following environment variables before starting your {{site.base_gateway}} instance:
        ```sh
        export KONG_KEYRING_ENABLED=on
        export KONG_KEYRING_STRATEGY=cluster
        export KONG_KEYRING_RECOVERY_PUBLIC_KEY=/path/to/generated/cert.pem
        ```


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---
@todo

based on https://docs.konghq.com/gateway/latest/kong-enterprise/db-encryption/#getting-started 