---
title: Enable rate limiting on a service
related_resources:
  - text: How to create rate limiting tiers
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

content_type: tutorial

tools:
    - deck
---

## Prerequisites 

place holder for prerendered prereq instructions that contains: 

* Docker: Docker is used to run a temporary Kong Gateway and database to allow you to run this tutorial
* curl: curl is used to send requests to Kong Gateway . 
* Kong Gateway


1. Get Kong

    Run Kong Gateway with the quickstart script:
    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s
    ```

    Once the Kong Gateway is ready, you will see the following message:

    ```bash
    Kong Gateway Ready 
    ```

1. Create a service 

{% capture step %}
{% entity_example %}
 type: service
 data:
   name: example_service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3}}

1. Create a route 

{% capture step %}
{% entity_example %}
type: route
data:
  name: example_route
  service:
    name: example_service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Enable the Rate Limiting Plugin on the Service

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

1. Validate

   After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests then allowed in the configured time limit.
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
