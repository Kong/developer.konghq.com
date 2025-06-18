---
title: Get started with Datakit
content_type: how_to
description: Learn how to configure the Datakit plugin.
products:
    - gateway

works_on:
    - on-prem

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
  skip_product: true
  inline:
    - title: "{{site.base_gateway}} license"
      include_content: prereqs/gateway-license
      icon_url: /assets/icons/gateway.svg

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

faqs:
  - q: How do I run Datakit in {{site.base_gateway}} 3.9 or 3.10?
    a: |
      Prior to 3.11, Datakit ran on the WASM engine. 
      If you are running {{site.base_gateway}} 3.9 or 3.10, set `wasm=on` in `kong.conf`, then reload your {{site.base_gateway}} instance before configuring the plugin.
---

## Create a Service and a Route

To be able to validate the configuration, we need to create a Gateway Service and a Route:

<!--vale off -->
{% entity_examples %}
entities:
  services:
    - name: example-service
      url: http://httpbin.konghq.com
  routes:
    - name: example-route
      paths:
        - /
      strip_path: true
      service: 
        name: example-service
{% endentity_examples %}
<!--vale on -->

## Enable Datakit

Test out Datakit by combining responses from two third-party API calls, then returning the result directly back to the client:

<!--vale off -->
{% entity_examples %}
entities:
  plugins:
    - name: datakit
      service: example-service
      config:
        debug: true
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
          - cat: CAT_FACT.body
          - dog: DOG_FACT.body
          jq: |
            {
              "cat_fact": $cat.fact,
              "dog_fact": $dog.facts[0]
            }
        - name: EXIT
          type: exit
          inputs:
          - body: JOIN
          status: 200
{% endentity_examples %}
<!--vale on -->

## Validate

Access the Service using the `/anything` path:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
{% endvalidation %}

You should get a `200` response with a random fact from each fact generator called in the config:

```json
{
    "cat_fact": "The longest living cat on record according to the Guinness Book belongs to the late Creme Puff of Austin, Texas who lived to the ripe old age of 38 years and 3 days!",
    "dog_fact": "Greyhounds can reach a speed of up to 45 miles per hour."
}
```
{:.no-copy-code}