---
title: Allow clients to choose their authentication method with multiple authentication
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

products:
    - gateway

plugins:
  - basic-auth
  - key-auth

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

pull content from https://docs.konghq.com/gateway/latest/kong-plugins/authentication/allowing-multiple-authentication-methods/

Add a bit about "Prevent anonymous access with the Request Termination plugin" (Information will need to be extrapolated from https://docs.konghq.com/gateway/latest/kong-plugins/authentication/reference/#multiple-authentication (in particular, look at the note))- maybe as an FAQ?