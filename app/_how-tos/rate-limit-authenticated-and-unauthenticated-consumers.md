---
title: Rate limit authenticated and unauthenticated Consumers
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

plugins:
  - basic-auth
  - rate-limiting

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication
    - rate-limiting

tldr:
    q: Placeholder
    a: Placeholder

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

This will need to be extrapolated from several sources. You can pull the anonymous access steps from https://docs.konghq.com/gateway/latest/kong-plugins/authentication/reference/#anonymous-access, and the rate limiting would be on the consumers, so you could use https://docs.konghq.com/hub/kong-inc/rate-limiting/how-to/basic-example/ 