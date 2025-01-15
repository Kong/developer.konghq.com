---
title: Integrate a Keyring with a Vault
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
    q: How do I integrate a Keyring with a Vault?
    a: Set the `kong_keyring_strategy` parameter to `vault` in your configuration and set the required `keyring_vault_*` parameters.
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---
@todo

based on https://docs.konghq.com/gateway/latest/kong-enterprise/db-encryption/#vault-integration