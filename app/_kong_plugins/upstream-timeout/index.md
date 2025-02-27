---
title: 'Upstream Timeout'
name: 'Upstream Timeout'

content_type: plugin

publisher: kong-inc
description: 'Set custom timeouts on connections to upstream services to override Gateway Service-level timeouts'
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

The Upstream Timeout plugin allows you to configure specific timeouts for the connection between {{site.base_gateway}} and an upstream service.
This plugin overrides any [Gateway Service-level timeout settings](/gateway/entities/service/#schema).

The most common use case for this plugin is configuring custom timeouts for specific Routes - for example, you might want to increase the timeout for particularly slow Routes.

If applying this plugin to a Gateway Service, make sure to apply it to another entity as well, such as a Gateway Service and Consumer pair.