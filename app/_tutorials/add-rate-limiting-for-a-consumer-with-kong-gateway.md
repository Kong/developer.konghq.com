---
title: Enable rate limiting for a consumer with Kong Gateway
related_resources:
  - text: How to create rate limiting tiers with Kong Gateway
    url:  /tutorials/add-rate-limiting-tiers-with-kong-gateway/
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
  - consumer

tags:
    - rate-limiting

content_type: tutorial

tldr:
    q: How do I add Rate Limiting to a consumer with Kong Gateway?
    a: Install the Rate Limiting plugin and enable it for the consumer.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
    consumers:
        - key-auth-consumer
    plugins:
        - key-auth
---

## Steps

1. Enable the Rate Limiting Plugin for the consumer

{% capture plugin %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting
  consumer: jsmith
  config:
    second: 5
    hour: 1000
targets:
  - global
{% endentity_example %}
{% endcapture %}
{{ plugin | indent: 3 }}

2. Synchronize your configuration

    Check the differences in your files:
    ```bash
    deck gateway diff deck_files
    ```
    If everything looks right, synchronize them to update your Gateway configuration:
    ```bash
    deck gateway sync deck_files
    ```
3. Validate

    You can run the following command to test the rate limiting as the consumer:
    ```bash
    for _ in {1..6}; do curl -i http://localhost:8000/example_route -H 'apikey:example_key'; echo; done
    ```

    You should get a `429` error with the message `API rate limit exceeded`.

1. Teardown

   Destroy the Kong Gateway container.

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
   ```
