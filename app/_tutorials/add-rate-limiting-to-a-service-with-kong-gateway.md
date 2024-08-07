---
title: Enable rate limiting on a service with Kong Gateway
related_resources:
  - text: How to create rate limiting tiers with Kong Gateway
    url:  /tutorials/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/

products:
    - gateway

platform:
    - on-prem
    - konnect

min_version:
  gateway: 3.4.x

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

tiers:
    - oss

tags:
    - rate-limiting

content_type: tutorial

tldr:
    q: How do I rate limit a service with Kong Gateway?
    a: Install the Rate Limiting plugin and enable it on the service.

tools:
    - deck

prereqs:
  - type: kong-quickstart
  - type: service
    data:
      name: example_service
  - type: route
    data:
      name: example_route
      service:
        name: example_service
---

## Steps

1. Enable the Rate Limiting Plugin on the service by adding the following to your `kong.yaml` file:

{% capture step %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    second: 5
    hour: 1000
    policy: local
targets:
  - service
variables: 
    serviceName|Id: example_service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}


1. Apply the changes:

  ```bash
  deck gateway sync kong.yaml
  ```

1. Verify that the Rate Limiting plugin was configured correctly by sending more requests then allowed in the configured time limit:

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