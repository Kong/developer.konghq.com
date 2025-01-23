---
title: Reference secrets stored in the Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management 
  - text: Vault entity
    url: /gateway/entities/vault
  - text: Store and use your Mistral API key as a secret in Konnect Config Store
    url: /how-to/store-and-use-your-mistral-api-key-as-a-secret-in-konnect-config-store
  - text: Configure the Konnect Config Store
    url: /how-to/configure-the-konnect-config-store

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
    q: How do I reference secrets stored in a {{site.konnect_short_name}}-native Vault?
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

Use some of the content from https://docs.konghq.com/konnect/gateway-manager/configuration/config-store/#main 

just check if the value stored can be referenced