---
title: Enable rate limiting on a service with Kong Gateway
related_resources:
  - text: How to create rate limiting tiers with Kong Gateway
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: 3.4.x

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

tags:
    - rate-limiting

tldr:
    q: How do I rate limit a service with Kong Gateway?
    a: Install the Rate Limiting plugin and enable it on the service.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
---

## Steps

1. Enable the Rate Limiting plugin on a service:

{% capture step %}
{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        second: 5
        hour: 1000
        policy: local
{% endentity_examples %}
{% endcapture %}
{{ step | indent: 3 }}

1. Validate

   After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests than allowed in the configured time limit.
   ```bash
   for _ in {1..6}
   do
     curl http://localhost:8000/example-route/anything/
   done
   ```
   After the 5th request, you should receive the following `429` error:

   ```bash
   { "message": "API rate limit exceeded" }
   ```

1. Teardown

   Destroy the Kong Gateway container.

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
   ```