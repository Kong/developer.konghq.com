---
title: Get started with Datakit
content_type: how_to
description: Learn how to configure the Datakit plugin.
products:
    - gateway

works_on:
    - on-prem

wasm: true

plugins:
  - datakit

entities: 
  - service
  - route
  - plugin

tags:
  - get-started
  - transformations

tldr: 
  q: What is Datakit, and how can I get started with it?
  a: |
    Datakit is a {{site.base_gateway}} plugin that allows you to interact with third-party APIs.
    In this guide, learn how to configure the plugin to combine responses from two third-party API calls and return directly to the client.

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
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.11'

related_resources:
  - text: Datakit plugin
    url: /plugins/datakit/

# temporary setting; will remove once the guide is reworked
automated_tests: false 
---

## Enable Datakit

Test out Datakit by combining responses from two third-party API calls, then returning the result directly back to the client:

<!--vale off -->
{% entity_examples %}
entities:
  plugins:
    - name: datakit
      service: example-service
      config:
        nodes:
        - name: CAT_FACT
          type: call
          url: https://catfact.ninja/fact
        - name: DOG_FACT
          type: call
          url: https://dogapi.dog/api/v1/facts
        - name: JOIN
          type: jq
          inputs:
            cat: CAT_FACT.body
            dog: DOG_FACT.body
          jq: |
            {
              cat_fact: .cat.fact,
              dog_fact: .dog.facts[0],
            }
        - name: EXIT
          type: exit
          inputs:
            body: JOIN
          status: 200
{% endentity_examples %}
<!--vale on -->

## Validate

Access the Service using the `/anything` path:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
{% endvalidation %}
<!-- vale on -->

You should get a `200` response with a random fact from each fact generator called in the config:

```json
{
    "cat_fact": "The longest living cat on record according to the Guinness Book belongs to the late Creme Puff of Austin, Texas who lived to the ripe old age of 38 years and 3 days!",
    "dog_fact": "Greyhounds can reach a speed of up to 45 miles per hour."
}
```
{:.no-copy-code}
