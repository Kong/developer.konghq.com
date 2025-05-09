---
title: 'Standard Webhooks'
name: 'Standard Webhooks'

content_type: plugin

publisher: kong-inc
description: 'Validate that incoming webhooks adhere to the Standard Webhooks specification'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: standard-webhooks.png

related_resources:
  - text: 'Create a webhook with {{site.base_gateway}}'
    url: /how-to/create-a-webhook-with-kong-gateway/

categories:
  - traffic-control

tags:
  - webhook
  - traffic-control
  - validation

search_aliases:
  - standard webhooks
---

The Standard Webhooks plugin lets you validate incoming webhooks using the [Standard Webhooks](https://github.com/standard-webhooks/standard-webhooks) specification. 

This plugin only supports HMAC-SHA256 secrets for webhook validation.

The Standard Webhooks specification is a package of open source tools and guidelines for sending webhooks easily, securely, and reliably. Kong contributes to this specification.