---
title: 'Request Transformer Advanced'
name: 'Request Transformer Advanced'

content_type: plugin

publisher: kong-inc
description: 'Use powerful regular expressions, variables, and templates to transform API requests'
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
icon: request-transformer-advanced.png

categories:
  - transformations

tags:
  - transformations

search_aliases:
  - request-transformer-advanced

faqs:
  - q: Can I use the Request Transformer Advanced plugin to rename or replace XML in the request body?
    a: No, you can only rename or replace JSON in the request body.

related_resources:
  - text: Request Transformer plugin
    url: /plugins/request-transformer/
  - text: Transform a client request in {{site.base_gateway}}
    url: /how-to/transform-a-client-request/
  - text: AI Request Transformer
    url: /plugins/ai-request-transformer/

min_version:
  gateway: '1.0'
---

{% include plugins/request-response-transformer/request-transformer-description.md %}

The Response Transformer Advanced plugin provides features that aren't available in the [Response Transformer plugin](/plugins/response-transformer/), including the ability to limit the list of allowed parameters in the request body with the [config.allow.body](./reference/#schema--config-allow-body) parameter.

## Order of execution

{% include plugins/request-response-transformer/transformation-order.md %}

## Templates

{% include /plugins/request-response-transformer/templates.md %}

## Arrays and nested objects

{% include plugins/request-response-transformer/arrays-nested-objects.md %}