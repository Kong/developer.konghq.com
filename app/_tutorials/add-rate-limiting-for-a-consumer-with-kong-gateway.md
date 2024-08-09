---
title: Enable rate limiting for a consumer with Kong Gateway
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
  - consumer

tiers:
    - oss

tags:
    - rate-limiting

content_type: tutorial

tldr:
    q: How do I add Rate Limiting to a consumer with Kong Gateway?
    a: Install the Rate Limiting plugin and enable it for the consumer.

tools:
    - deck
---

## Steps

1. Start Kong Gateway

    Run Kong Gateway with the quickstart script:
    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s
    ```

    Once the Kong Gateway is ready, you will see the following message:

    ```bash
    Kong Gateway Ready 
    ```

1. Create a service and a route

{% capture service_route %}
{% entity_example %}
type: service
data:
  name: example_service
  host: example.com
  routes:
  - name: example_route
    paths:
    - /example_route
{% endentity_example %}
{% endcapture %}
{{ service_route | indent: 3 }}

{% capture sync %}
1. Synchronize your configuration
{% endcapture %}

{{ sync }}
    Check the differences in your file:
    ```bash
    deck gateway diff kong.yaml
    ```
    If everything looks right, synchronize it to update your Gateway configuration:
    ```bash
    deck gateway sync kong.yaml
    ```
    You can then check that the services and route were created:
    ```bash
    curl -i -X GET http://localhost:8001/services
    ```


1. Create a consumer 

{% capture consumer %}
{% entity_example %}
type: consumer
data:
  username: jsmith
{% endentity_example %}
{% endcapture %}
{{ consumer | indent: 3 }}

{{ sync }}
    You can then check that the consumer was created:
    ```bash
    curl -i -X GET http://localhost:8001/consumer
    ```


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

{{ sync }}
    You can then check that the plugin was enabled:
    ```bash
    curl -i -X GET http://localhost:8001/plugins
    ```

1. Optional: If you want to test the rate limiting, you can set up authentication for this consumer and call the service with its credentials.
{% capture auth %}
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

{% capture key %}
{% entity_example %}
type: consumer
data:
  username: jsmith
  keyauth_credentials:
  - key: example_key
{% endentity_example %}
{% endcapture %}

    Enable the Key Authentication plugin:
    {{ auth | indent: 3 }}


    Update the consumer configuration to add an API key:
    {{ key | indent: 3 }}

    Synchronize your configuration, and run the following command to test the rate limiting:
    ```bash
    for _ in {1..6}; do curl -i http://localhost:8000/example_route -H 'apikey:example_key'; echo; done
    ```

    You should get an `429` error with the message `API rate limit exceeded`.

1. Teardown

   Destroy the Kong Gateway container.

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
   ```
