---
title: Rate limit a Gateway Service with {{site.base_gateway}}
permalink: /how-to/add-rate-limiting-to-a-service-with-kong-gateway/
content_type: how_to
description: Learn how to configure rate limiting for a Gateway Service.
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a Gateway Service with {{site.base_gateway}}?
    a: Install the [Rate Limiting plugin](/plugins/rate-limiting/) and enable it on the [Service](/gateway/entities/service/).

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable rate limiting

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Service. 
In this example, the limit is 5 requests per minute and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        minute: 5
        hour: 1000
{% endentity_examples %}

## Validate

After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests than allowed in the configured time limit.

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
{% endvalidation %}
