---
title: Store certificates in Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Configure the Konnect Config Store
    url: /how-to/configure-the-konnect-config-store/
  - text: Store a Mistral API key as a secret in Konnect Config Store
    url: /how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I securely replace my {{site.base_gateway}} data plane node certificates with a secret reference instead?
    a: placeholder

prereqs:
  inline:
    - title: Konnect API
      include_content: prereqs/konnect-api-for-curl

tools:
  - konnect-api
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

@todo

Use content from https://docs.konghq.com/konnect/gateway-manager/configuration/vaults/how-to/ 