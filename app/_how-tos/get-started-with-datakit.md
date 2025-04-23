---
title: Get started with Datakit
content_type: how_to
tech_preview: true

products:
    - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - datakit

entities: 
  - service
  - route
  - plugin

tags:
  - get-started
  - transformations
  - tech-preview

tldr: 
  q: What is Datakit, and how can I get started with it?
  a: |
    Datakit is a {{site.base_gateway}} plugin that allows you to interact with third-party APIs.
    To enable it, start {{site.base_gateway}} with `wasm = on`. 
    Then, you can configure the plugin to combine responses from two third-party API calls and return directly to the client.

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
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.9'

related_resources:
  - text: Datakit plugin
    url: /plugins/datakit/
---

## 1. Start {{site.base_gateway}} with the WASM engine

Start the {{site.base_gateway}} container with the `KONG_WASM` variable:

```sh
curl -Ls https://get.konghq.com/quickstart | bash -s -- \
   -e KONG_LICENSE_DATA \
   -e KONG_WASM=on
```

## 2. Create a Service and a Route

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

## 3. Enable Datakit

Let's test out Datakit by combining responses from two third-party API calls, then returning directly to the client:

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

## 4. Validate

Access the Service via the `/anything` path to test Datakit:

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