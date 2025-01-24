---
title: Configure the Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault
  - text: Store certificates in Konnect Config Store
    url: /how-to/store-certificates-in-konnect-config-store/
  - text: Reference secrets stored in the Konnect Config Store
    url: /how-to/reference-secrets-from-konnect-config-store/
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
    q: How do I use a {{site.konnect_short_name}}-native Vault?
    a: |
      1. Use the {{site.konnect_short_name}} API to create a Config Store using the `config-stores` endpoint.
      2. Create a {{site.konnect_short_name}} Vault using the [`/vaults/` endpoint](/api/konnect/control-planes-config/v2/#/operations/create-vault).

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

Use some of the content from https://docs.konghq.com/konnect/gateway-manager/configuration/config-store/#main 

This is important I think because documenting that you have to enable it with the API before you use it is a pattern that a user won't be able to figure out on their own.