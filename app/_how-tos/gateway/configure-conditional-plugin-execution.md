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

tldr:
  q: How do I conditionally execute a plugin based on request attributes?
  a: |
    The `condition` field on a plugin lets you write a CEL expression that controls whether the plugin runs for a given request.
    Attach a condition to the Request Termination plugin so that it only triggers when a specific request header is present.

    While this guide uses a particular plugin, you can use conditions like this with any plugin that supports the `condition` field.

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
    gateway: '3.15'

related_resources:
  - text: Plugin expressions reference
    url: /gateway/plugins/expressions/

faqs:
  - q: Can I see the results of a condition check in the {{site.base_gateway}} logs?
    a: |
      If {{site.base_gateway}} is running with [debug logging enabled](/gateway/configuration/#log-level), you can confirm condition evaluation results in `error.log`.

      When the condition is not matched and the plugin is skipped:

      ```
      plugin condition not matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6): skipped
      ```
      {:.no-copy-code}

      When the condition is matched and the plugin executes:

      ```
      plugin condition matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6)
      ```
      {:.no-copy-code}
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
status_code: 201
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
> Header names are always normalized to lowercase with hyphens replaced by underscores.
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
