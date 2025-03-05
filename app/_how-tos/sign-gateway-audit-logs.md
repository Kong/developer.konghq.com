---
title: Sign {{site.base_gateway}} audit logs with an RSA key
content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

products:
    - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - logging

tldr:
    q: How do I 
    a: placeholder

tools:
    - deck


cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@todo

Use content from https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/#digital-signatures