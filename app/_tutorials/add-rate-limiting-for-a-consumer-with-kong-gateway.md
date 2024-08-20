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
    a: Make sure you have enabled an authentication plugin and created a consumer with credentials, then enable the <a href="/plugins/rate-limiting/reference">Rate Limiting plugin</a> for that consumer. 

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
    - title: Destroy the Kong Gateway container
      include_content: cleanup/products/gateway
---

## Steps

1. Add the following content to `kong.yaml` to enable the Key Authentication plugin. You need [authentication](/authentication/) to identify the consumer and apply rate limiting.

{% capture plugin %}
{% entity_example %}
type: plugin
data:
  name: key-auth
  config:
    key_names:
    - apikey
targets:
  - global
{% endentity_example %}
{% endcapture %}
{{ plugin | indent: 3 }}

1. Create a [consumer](/gateway/entities/consumer/) with a key.

{% capture consumer %}
{% entity_example %}
type: consumer
data:
  username: jsmith
  keyauth_credentials:
      - key: example-key
{% endentity_example %}
{% endcapture %}
{{ consumer | indent: 3 }}

1. Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the consumer. In this example, the limit is 5 requests per second and 1000 requests per hour.

{% capture plugin %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    second: 5
    hour: 1000
targets:
  - consumer 
variables:
    consumerName|Id: jsmith
{% endentity_example %}
{% endcapture %}
{{ plugin | indent: 3 }}

2. Synchronize your [decK](/deck/) configuration files:

    Check the differences in your files:
    ```bash
    deck gateway diff deck_files
    ```
    If everything looks right, synchronize them to update your Gateway configuration:
    ```bash
    deck gateway sync deck_files
    ```
3. Validate:

    You can run the following command to test the rate limiting as the consumer:
    ```bash
    for _ in {1..6}; do curl -i http://localhost:8000/example_route -H 'apikey:example_key'; echo; done
    ```

    This command sends six consecutive requests to the route. On the last one you should get a `429` error with the message `API rate limit exceeded`.