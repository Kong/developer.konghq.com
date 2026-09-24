---
title: "Custom policies"
content_type: reference
layout: reference

description: "Learn how to deploy a custom policy in {{site.ai_gateway}}"

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
  ai-gateway: '2.0'

tags:
  - ai

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Custom plugins
    url: /custom-plugins/
  - text: Streaming custom plugins
    url: /custom-plugins/streaming-plugins/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

{{site.ai_gateway}} allows you to develop and deploy custom AI Policies. A custom AI policy has two parts, a schema and a plugin handler that implements the custom functionality.

Plugins consist of Lua modules interacting with request and response objects or network streams to implement arbitrary logic. Plugin development operates in the same way for both {{site.ai_gateway}} and {{site.base_gateway}}. Kong provides a  [Plugin Development Kit (PDK)](/gateway/pdk/reference/) which is a set of Lua functions that are used to facilitate interactions between plugins, the {{site.base_gateway}} core, and other components.

This page describes how to run a custom policy you have already developed and manage its lifecycle.

## Deploying custom policies

You can deploy custom policies in two ways:

- `streaming`: streamed from a single control plane
- `installed`: direct installation on each data plane

### Streamed policies

You can deploy a custom policy's schema and plugin handler by uploading both to a single control plane. During configuration reconciliation, the plugin handler is sent to the data plane in a payload. You can then reference it as a `type` in any AI Policy configuration.
 
Data planes must be started with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` to accept custom policies from the control plane.

The same limitations as streaming {{site.base_gateway}} apply. For more information, see [Streaming custom plugins](/custom-plugins/streaming-plugins/#streaming-plugin-limitations).

### Direct installation

First manually install the custom plugin handler on each data plane by following the [installation guide](/custom-plugins/installation-and-distribution/). 

Next upload the policy's schema to the control plane. You can then reference it as a `type` in any AI Policy configuration.

## Manage custom policies

You can mangae the lifecycle of a custom plugin using any of the following:

- {{site.konnect_short_name}} UI
- {{site.ai_gateway}} API with the `/v1/ai-gateways/{aiGatewayId}/custom-policies` endpoint
- [kongctl](/kongctl/)

Fields:

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
    notes: Unique identifier. Immutable after creation.
  - field: "`type`"
    type: "`installed` or `streaming`"
    notes: Discriminator. Determines whether `handler` is allowed/required.
  - field: "`display_name`"
    type: string
    notes: 1-256 characters.
  - field: "`schema`"
    type: string
    notes: Lua schema, equivalent to a plugin's `schema.lua`.
  - field: "`handler`"
    type: string
    notes: "Lua handler, equivalent to a plugin's `handler.lua`. Required for `streaming`, not allowed for `installed`."
  - field: "`id`, `created_at`, `updated_at`"
    type: "-"
    notes: Server-assigned.
{% endtable %}

### Create a custom policy

- `POST /v1/ai-gateways/{aiGatewayId}/custom-policies`
- `installed` request: `name`, `type`, `display_name`, `schema`
- `streaming` request: `name`, `type`, `display_name`, `schema`, `handler`
- `additionalProperties: false` on both: including `handler` on an `installed` request (or omitting it on a `streaming` request) is rejected

To create a custom policy in `installed` mode:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: my-installed-custom-policy
  type: installed
  display_name: Custom Policy - Installed plugin
  schema: <lua_schema>
{% endkonnect_api_request %}

To create a custom policy in `streamed` mode:

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: my-streaming-custom-policy
  type: streaming
  display_name: Custom Policy - Streaming plugin
  schema: <lua_schema>
  handler: <lua_handler>
{% endkonnect_api_request %}

Note that duplicate names are not allowed and will return a `409` error.

### List custom policies

- `GET /v1/ai-gateways/{aiGatewayId}/custom-policies`
- Paginated: `page[size]`, `page[after]`

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies
status_code: 200
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}

### Get a custom policy

- `GET /v1/ai-gateways/{aiGatewayId}/custom-policies/{customPolicyIdOrName}`
- `{customPolicyIdOrName}`: `id` or `name`

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/my-streaming-custom-policy
status_code: 200
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}

### Update a custom policy

- `PUT /v1/ai-gateways/{aiGatewayId}/custom-policies/{customPolicyIdOrName}`
- `name` is immutable. Include the current `name` in the request; it can't be changed to a different value.
- Same per-type field rules as create (`handler` required for `streaming`, disallowed for `installed`)

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/my-streaming-custom-policy
status_code: 200
method: PUT
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: my-streaming-custom-policy
  type: streaming
  display_name: Custom Policy - Streaming plugin (updated)
  schema: <lua_schema>
  handler: <lua_handler>
{% endkonnect_api_request %}

### Delete a custom policy

- `DELETE /v1/ai-gateways/{aiGatewayId}/custom-policies/{customPolicyIdOrName}`
- `204` on success

{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/custom-policies/my-streaming-custom-policy
status_code: 204
method: DELETE
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}