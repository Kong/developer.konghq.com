---
title: Store secrets in Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management 

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security

tldr:
    q: How do I 
    a: placeholder

tools:
    - deck
    # - konnect-api


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

Use content from https://docs.konghq.com/konnect/gateway-manager/configuration/config-store/#main 