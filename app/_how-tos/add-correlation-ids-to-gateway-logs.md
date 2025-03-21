---
title: Add Correlation IDs to {{site.base_gateway}} logs
content_type: how_to
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
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
  - key-auth

entities: 
  - service
  - plugin
  - consumer

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a Consumer with {{site.base_gateway}}?
    a: Enable an authentication plugin and create a [Consumer](/gateway/entities/consumer/) with credentials, then enable the [Rate Limiting plugin](/plugins/rate-limiting/) on the new Consumer.

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

@todo

pull content from:
* https://docs.konghq.com/hub/kong-inc/correlation-id/#can-i-see-my-correlation-ids-in-my-kong-logs 
* https://support.konghq.com/support/s/article/Is-it-possible-to-use-a-custom-log-format-without-using-a-custom-nginx-template
