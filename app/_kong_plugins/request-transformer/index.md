---
title: 'Request Transformer'
name: 'Request Transformer'

content_type: plugin

publisher: kong-inc
description: 'Use regular expressions, variables, and templates to transform requests'


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
icon: request-transformer.png

categories:
  - transformations

search_aliases:
  - request-transformer

tags:
  - transformations

related_resources:
  - text: Request Transformer Advanced plugin
    url: /plugins/request-transformer-advanced/
  - text: AI Request Transformer
    url: /plugins/ai-request-transformer/

min_version:
  gateway: '1.2'
---

{% include plugins/request-response-transformer/request-transformer-description.md %}

For more advanced features, see the [Request Transformer Advanced plugin](/plugins/request-transformer-advanced/).

## Order of execution

{% include plugins/request-response-transformer/transformation-order.md %}

## Templates

{% include /plugins/request-response-transformer/templates.md %}
