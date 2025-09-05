---
title: 'Route Transformer Advanced'
name: 'Route Transformer Advanced'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Transform routing by changing the upstream server, port, or path'

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
icon: route-transformer-advanced.png

categories:
  - transformations

tags:
  - transformations

search_aliases:
  - route-transformer-advanced

min_version:
  gateway: '1.3'
---

This plugin transforms routing on the fly in {{site.base_gateway}}, changing the host, port, or path of the request. 
The substitutions can be configured via flexible templates.

## Templates

{% include /plugins/request-response-transformer/templates.md %}
