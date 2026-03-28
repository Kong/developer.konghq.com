---
title: Configure conditional plugin execution in {{site.base_gateway}}
permalink: /gateway/configure-conditional-plugin-execution/
content_type: how_to
description: Learn how to control when a {{site.base_gateway}} plugin executes based on request attributes.
products:
    - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - request-termination

beta: true

tldr:
  q: How do I conditionally execute a plugin based on request attributes?
  a: |
    The `condition` field on a plugin lets you write an ATC expression that controls whether the plugin runs for a given request. 
    In this guide, learn how to attach a condition to the Request Termination plugin so that it only triggers when a specific request header is present.

    While this guide uses a particular plugin, you can use conditions like this with any plugin that contains a `condition` field.

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
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.14'

related_resources:
  - text: Plugin expressions reference
    url: /gateway/plugins/expressions/

faqs:
  - q: Can I see the results of a condition check in the {{site.base_gateway}} logs?
    a: |
      If {{site.base_gateway}} is running with debug logging enabled, you can confirm the condition evaluation
      result in `error.log`:

      ```
      [kong] plugin_condition.lua:234 plugin condition evaluated for plugin
      'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6):
      expression="http.headers.x_block == "true"", result=false
      ```
      {:.no-copy-code}

      The log line shows the plugin name, its ID, the expression that was evaluated, and the result.
      When `result=false`, the plugin was skipped for that request.
---

## Add a plugin with a condition

Add the Request Termination plugin to your Route with a `condition` expression. 
In this example, the plugin only triggers when the request includes the header `x-block: true`, and blocks the request. 
Requests without this header are proxied to the upstream service.

<!-- decK doesn't support this yet -->
<!-- {% entity_examples %}
entities:
  plugins:
    - name: request-termination
      route: example-route
      config:
        status_code: 403
        message: "Forbidden by condition"
      condition: 'http.headers.x_block == "true"'
{% endentity_examples %} -->

<!--vale off-->
{% control_plane_request %}
url: /routes/example-route/plugins
method: POST
status_code: 200
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
  name: request-termination
  config:
    status_code: 403
    message: "Forbidden by condition"
  condition: "http.headers.x_block == \"true\""
{% endcontrol_plane_request %}
<!--vale on-->

{:.info}
> **Note:** In ATC expressions, hyphens (`-`) in header names must be replaced with underscores (`_`).
> For example, `x-block` becomes `http.headers.x_block`.

## Validate

Let's check that the plugin gets accurately applied based on the condition.

First, send a request with the `x-block: true` header:

{% validation request-check %}
url: /anything
method: GET
headers:
  - "x-block: true"
status_code: 403
{% endvalidation %}

The header satisfies the condition and triggers the Request Termination plugin, so you should receive a `403 Forbidden` response:

```json
{"message":"Forbidden by condition"}
```
{:.no-copy-code}


Next, send a request without the header:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
{% endvalidation %}

You should receive a `200 OK` response from the upstream service, because the condition evaluated to `false` and the plugin was skipped.
