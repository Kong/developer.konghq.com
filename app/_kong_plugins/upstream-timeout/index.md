---
title: 'Upstream Timeout'
name: 'Upstream Timeout'

content_type: plugin

publisher: kong-inc
description: 'Set timeouts on Routes and override Gateway Service-level timeouts'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: upstream-timeout.png

categories:
  - traffic-control

search_aliases:
  - upstream-timeout
---

Use the Upstream Timeout plugin to configure Route-specific timeouts for the connection between {{site.base_gateway}} and an upstream service.
This plugin overrides any Gateway Service-level timeout settings.