---
title: How to create RBAC Admins using the Admin API
content_type: how_to
related_resources:
  - text: RBAC
    url: /gateway/entities/rbac/
  - text: Admins
    url:  /gateway/entities/admins/
products:
    - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.4'


entities: 
  - admin
  - rbac
  - group
  - workspace



tags:
    - security
tldr:
    q: placeholder
    a: Enable an authentication plugin and create a <a href="/gateway/entities/consumer/">Consumer</a> with credentials, then enable the <a href="/plugins/rate-limiting/">Rate Limiting plugin</a> on the new Consumer.


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## @TODO
