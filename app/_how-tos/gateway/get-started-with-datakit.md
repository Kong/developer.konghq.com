---
title: Get started with Datakit
permalink: /how-to/get-started-with-datakit/
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

---

## Enable Datakit

Test out Datakit by combining responses from two third-party API calls, then returning the result directly back to the client:

<!-- vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: datakit
      service: example-service
      config:
        nodes:
        - name: AUTHOR
          type: call
          url: https://httpbin.konghq.com/json
        - name: UUID
          type: call
          url: https://httpbin.konghq.com/uuid
        - name: JOIN
          type: jq
          inputs:
            input1: AUTHOR.body
            input2: UUID.body
          jq: |
            {
              author: .input1.slideshow.author,
              uuid: .input2.uuid,
            }
        - name: EXIT
          type: exit
          inputs:
            body: JOIN
          status: 200
{% endentity_examples %}
<!--vale on-->

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

You should get a `200` response with a UUID and a slideshow author:
```json
{"uuid":"cfa1e3f8-6618-4d1f-89f0-da97490d7caa","author":"Yours Truly"}
```
{:.no-copy-code}
