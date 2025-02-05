---
title: Authenticate on the upstream service with Basic Auth and Request Transformer plugins
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

plugins:
  - basic-auth
  - request-transformer

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

pull content from https://github.com/Kong/kong/issues/5899