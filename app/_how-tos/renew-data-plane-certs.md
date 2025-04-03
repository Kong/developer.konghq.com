---
title: "Renew Data Plane certificates in {{site.konnect_short_name}}"
content_type: how_to
description: placeholder

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting-advanced
  - pre-function

entities:
  - service
  - route
  - plugin

tags:
  - rate-limiting
  - serverless

tldr:
  q: placeholder
  a: placeholder

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

pull content specifically from the "Advanced" section: https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/renew-certificates/#advanced-setup