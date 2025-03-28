---
title: Use SDKs with AI Proxy Advanced
content_type: how_to

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.8'


plugins:
  - ai-proxy-advanced

entities: 
  - service
  - route
  - plugin

tags:
    - ai-gateway

tldr:
    q: ""
    a: ""

tools:
    - deck


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