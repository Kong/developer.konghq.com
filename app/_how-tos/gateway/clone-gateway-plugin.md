---
title: Run multiple instances of a {{site.base_gateway}} plugin
permalink: /how-to/clone-gateway-plugin/
content_type: how_to
related_resources:
  - text: Plugin cloning reference
    url: /gateway/entities/plugin/#cloning-plugins

description: "Create a duplicate of an existing {{site.base_gateway}} plugin so that you can run multiple instances of the same plugin with different configurations or in different scopes."

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  gateway:
    - name: "KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on"
  konnect:
    - name: "KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on"

min_version:
  gateway: '3.15'

entities:
  - service
  - route
  - plugin

tldr:
  q: How do I apply a plugin multiple times with different configurations?
  a: |
    To apply a plugin multiple times with different configurations, clone the plugin using the `cloned_plugins` key, then configure the clone the same as any other plugin through `plugins`.

faqs:
  - q: Do all {{site.base_gateway}} plugins support cloning?
    a: |
      No, only a subset of plugins can be cloned. See the list of [supported plugins](/gateway/entities/plugin/#supported-plugins).
  - q: I'm running {{site.base_gateway}} in hybrid mode and I can't set up a cloned plugin.
    a: |
      If you're running {{site.base_gateway}} in hybrid mode, both the control plane and data plane need to be launched with the [`custom_plugin_streaming_enabled=on`](/gateway/configuration/#custom-plugin-streaming-enabled) setting.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

In this guide, you'll clone the [Request Transformer](/plugins/request-transformer/) plugin to run two independent instances with different configurations:

* A global clone that adds a header to every request passing through the gateway.
* The original plugin applied to a specific Route that adds a different header.

This lets two separate teams use the same plugin logic with independent configuration and precedence.

## Create a clone of the Request Transformer plugin

Use the `cloned_plugins` key to define a new plugin named `request-transformer-global` that is based on `request-transformer`:

{% entity_examples %}
entities:
  cloned_plugins:
    - name: request-transformer-global
      ref: request-transformer
      priority: 802
{% endentity_examples %}

Where:
* `cloned_plugins.name`: A unique name for the clone. This can be any name that doesn't conflict with an existing plugin.
* `cloned_plugins.ref`: The source plugin that this clone is based on.
* `cloned_plugins.priority`: The order in which the cloned plugin runs relative to other plugins. The base Request Transformer plugin has a priority of 801, so setting 802 makes the clone run first. This isn't required for this example since the clone runs globally, but it shows how you can control plugin ordering independently from the source plugin.

## Apply the cloned plugin globally

Configure the cloned plugin globally so it adds a header to every request:

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer-global
      config:
        add:
          headers:
            - "X-Global-Header:isSetGlobally"
{% endentity_examples %}

## Apply the source plugin to a Route

Configure the original Request Transformer plugin on `example-route` to add a Route-specific header. This runs as a separate, independent instance from the global clone:

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer
      route: example-route
      config:
        add:
          headers:
            - "X-Route-Header:isSetOnRoute"
{% endentity_examples %}

## Create a second route

Create a second Route on `example-service` to use in validation. Requests to this Route will only be handled by the global clone, not the route-scoped plugin:

{% entity_examples %}
entities:
  routes:
    - name: example-route-2
      service:
        name: example-service
      paths:
        - /global
      protocols:
        - http
        - https
{% endentity_examples %}

## Validate

First, send a request to `example-route`, which triggers both plugins.
The global clone adds `X-Global-Header` and the route-scoped plugin adds `X-Route-Header`:

{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}

In the response from `httpbin`, look for both headers in the `headers` object:

```json
{
  "headers": {
    "X-Global-Header": "isSetGlobally",
    "X-Route-Header": "isSetOnRoute"
  }
}
```
{:.no-copy-code}

Now send a request to `example-route-2`:

{% validation request-check %}
url: '/global'
status_code: 200
display_headers: true
{% endvalidation %}

Only the global clone should run, so you should only see `X-Global-Header`:

```json
{
  "headers": {
    "X-Global-Header": "isSetGlobally"
  }
}
```
{:.no-copy-code}

The global clone runs on both Routes, while `request-transformer` only runs on `example-route`, confirming that the two instances are fully independent.
