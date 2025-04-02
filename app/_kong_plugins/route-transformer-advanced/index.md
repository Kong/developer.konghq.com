---
title: 'Route Transformer Advanced'
name: 'Route Transformer Advanced'

content_type: plugin

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

search_aliases:
  - route-transformer-advanced
---

This plugin transforms routing on the fly in {{site.base_gateway}}, changing the host, port, or path of the request. 
The substitutions can be configured via flexible templates.

## Templates

{% include /plugins/request-response-transformer/templates.md %}
