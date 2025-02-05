---
title: Enable Basic Auth for Kong Manager
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

tier: enterprise

products:
    - gateway

plugins:
  - basic-auth
  - request-transformer

works_on:
    - on-prem

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication

tldr:
    q: Placeholder
    a: Placeholder

tools:
    - deck

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@todo

Pull content from https://docs.konghq.com/gateway/latest/kong-manager/auth/basic/#main 

Should https://support.konghq.com/support/s/article/How-to-change-Kong-manager-password-from-database be added as a stub page link? Or part of a FAQ?