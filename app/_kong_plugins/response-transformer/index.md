---
title: 'Response Transformer'
name: 'Response Transformer'

content_type: plugin

publisher: kong-inc
description: 'Modify the upstream response before returning it to the client'


products:
    - gateway

works_on:
    - on-prem
    - konnect

tags: 
  - transformations

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: response-transformer.png

categories:
  - transformations

search_aliases:
  - response-transformer

related_resources:
  - text: Response Transformer Advanced plugin
    url: /plugins/response-transformer-advanced/
  - text: All transformation plugins
    url: /plugins/?category=transformations
  
min_version:
  gateway: '1.0'
---

{% include plugins/request-response-transformer/response-transformer-description.md %}

For more advanced features, see the [Response Transformer Advanced plugin](/plugins/response-transformer-advanced/).

## Order of execution

{% include plugins/request-response-transformer/transformation-order.md %}