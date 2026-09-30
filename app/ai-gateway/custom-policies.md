---
title: "Custom policies"
content_type: reference
layout: reference

description: "Custom AI Policies let you deploy your own plugin schema and handler in {{site.ai_gateway}}, either streamed from the control plane or installed directly on data planes."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl
  - konnect-api

min_version:
  ai-gateway: '2.2'

tags:
  - ai
  - custom-plugins

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Custom plugins
    url: /custom-plugins/
  - text: Streaming custom plugins
    url: /custom-plugins/streaming-plugins/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/

faqs:
  - q: How do I use a custom policy?
    a: Configure an [AI Policy](/ai-gateway/entities/ai-policy/) entity as normal and use the `name` of the custom policy as the `type`.
---

{{site.ai_gateway}} allows you to develop and deploy custom AI Policies.
A custom AI policy has two parts, a schema and a plugin handler that implements the custom functionality.

Plugins consist of Lua modules interacting with request and response objects or network streams to implement arbitrary logic.
Plugin development operates in the same way for both {{site.ai_gateway}} and {{site.base_gateway}}.
We provide a [Plugin Development Kit (PDK)](/gateway/pdk/reference/), a set of Lua functions that facilitate interactions between plugins, the {{site.base_gateway}} core, and other components.

A custom policy can be used in the same way as any other [AI Policy](/ai-gateway/entities/ai-policy/) and the `name` you set when creating the custom policy is the `type` used when creating an AI Policy entity.
The schema you provide is used for validation in the same way as a built-in AI Policy.

This page describes how to run a custom policy you have already developed and manage its lifecycle.

## Deploying custom policies

You can deploy custom policies in two ways:

- `streaming`: streamed from a single control plane
- `installed`: direct installation on each data plane

### Streamed policies

You can deploy a custom policy's schema and plugin handler by uploading both to a single control plane.
During configuration reconciliation, the control plane sends the plugin handler to the data plane in a payload.
You can then reference it as a `type` in any AI Policy configuration.
 
Data planes must be started with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` to accept custom policies from the control plane.

The same limitations as streaming {{site.base_gateway}} apply.
For more information, see [Streaming custom plugins](/custom-plugins/streaming-plugins/#streaming-plugin-limitations).

### Direct installation

First manually install the custom plugin handler on each data plane by following the [installation guide](/custom-plugins/installation-and-distribution/).

Next upload the policy's schema to the control plane.
You can then reference it as a `type` in any AI Policy configuration.

## Managing custom policies

You can manage the lifecycle of a custom policy using any of the following:

- {{site.konnect_short_name}} UI
- {{site.ai_gateway}} API with the `/v1/ai-gateways/{aiGatewayId}/custom-policies` endpoint
- [kongctl](/kongctl/)

### Custom policy configuration

A custom AI policy configuration is defined by the following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Notes
    key: notes
rows:
  - field: "`name`"
    type: string
    notes: Unique identifier. Immutable after creation. Creating a duplicate returns a `409` error.
  - field: "`type`"
    type: "`installed` or `streaming`"
    notes: Discriminator. Determines whether `handler` is required.
  - field: "`display_name`"
    type: string
    notes: 1-256 characters.
  - field: "`schema`"
    type: string
    notes: Lua schema, equivalent to a plugin's `schema.lua`.
  - field: "`handler`"
    type: string
    notes: "Lua handler, equivalent to a plugin's `handler.lua`. Required for `streaming`. Disallowed for `installed`."
  - field: "`id`, `created_at`, `updated_at`"
    type: "-"
    notes: Server-assigned.
{% endtable %}

### List custom policies

To get a paginated list of existing custom policies, use the `/v1/ai-gateways/{aiGatewayId}/custom-policies` endpoint:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies
status_code: 200
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}

### Get a custom policy

To fetch a custom policy by `name` or `id`, use the `/v1/ai-gateways/{aiGatewayId}/custom-policies/{name|id}` endpoint:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/my-streaming-custom-policy
status_code: 200
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}

### Create a custom policy

To create a custom policy in `streaming` mode:

{% entity_example %}
type: custom_policy
data:
  name: my-streaming-custom-policy
  type: streaming
  display_name: Custom Policy - Streaming plugin
  schema: ${schema}
  handler: ${handler}
variables:
  schema:
    value: $LUA_SCHEMA
    description: Your Lua schema
  handler:
    value: $LUA_HANDLER
    description: Your plugin handler.
{% endentity_example %}

To create a custom policy in `installed` mode:

{% entity_example %}
type: custom_policy
data:
  name: my-installed-custom-policy
  type: installed
  display_name: Custom Policy - Installed plugin
  schema: ${schema}
variables:
  schema:
    value: $LUA_SCHEMA
    description: Your Lua schema
{% endentity_example %}

{:.info}
> Including a `handler` in `installed` mode or omitting it in `streaming` mode results in an error.

### Update a custom policy

To update an existing custom policy, redeploy the `custom_policy` entity with the same `name`:

{% entity_example %}
type: custom_policy
data:
  name: my-streaming-custom-policy
  type: streaming
  display_name: Custom Policy - Streaming plugin (updated)
  schema: ${schema}
  handler: ${handler}
variables:
  schema:
    value: $LUA_SCHEMA
    description: Your Lua schema
  handler:
    value: $LUA_HANDLER
    description: Your plugin handler.
{% endentity_example %}

{:.info}
> The `name` field is immutable. You must include the current `name` when updating a custom policy.

### Delete a custom policy

To delete a custom policy by `name` or `id`, use the `/v1/ai-gateways/{aiGatewayId}/custom-policies/{name|id}` endpoint:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/my-streaming-custom-policy
status_code: 204
method: DELETE
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}