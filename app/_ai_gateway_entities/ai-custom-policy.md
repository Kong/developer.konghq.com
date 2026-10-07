---
title: AI Custom Policies
content_type: reference
entities:
  - ai-custom-policy
  - ai-policy
products:
  - ai-gateway
min_version:
  ai-gateway: '2.2'
permalink: /ai-gateway/entities/ai-custom-policy/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "AI Custom Policies let you run your own Lua plugin logic as an AI Policy type in {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayCustomPolicy
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl
tags:
  - ai
  - custom-plugins
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Custom plugins
    url: /custom-plugins/
  - text: Streaming custom plugins
    url: /custom-plugins/streaming-plugins/
faqs:
  - q: How do I use an AI Custom Policy?
    a: Create an [AI Policy](/ai-gateway/entities/ai-policy/) as normal and set its `type` to the `name` of the AI Custom Policy.
  - q: Which language can I write an AI Custom Policy in?
    a: |
      Lua. The [`schema`](#schema-aigateway-custom-policy-schema) and [`handler`](#schema-aigateway-custom-policy-handler) fields take Lua source, equivalent to a plugin's `schema.lua` and `handler.lua`.
  - q: Does {{site.konnect_short_name}} check my AI Policy `config` against the AI Custom Policy schema?
    a: |
      No. {{site.konnect_short_name}} validates the schema itself when you create or update the AI Custom Policy, but it accepts any `config` on an AI Policy that uses it. Make sure your AI Policy `config` matches your schema.
  - q: Can I rename an AI Custom Policy or switch its mode?
    a: |
      No. [`name`](#schema-aigateway-custom-policy-name) and [`type`](#schema-aigateway-custom-policy-type) are immutable. To change either, create a new AI Custom Policy, point your AI Policies at it, then delete the old one.
---

## What is an AI Custom Policy?

Create an AI Custom Policy when you need behavior that the built-in [AI Policies](/ai-gateway/policies/) don't provide. An AI Custom Policy registers your own plugin as a new [AI Policy](/ai-gateway/entities/ai-policy/) type.

An AI Custom Policy has two parts:
* A Lua schema that defines the configuration your policy accepts
* A Lua handler that implements the behavior, using the [Plugin Development Kit (PDK)](/gateway/pdk/reference/)

Plugin development works the same way for {{site.ai_gateway}} and {{site.base_gateway}}, so you can reuse custom plugins you've already written.

Once registered, the AI Custom Policy's [`name`](#schema-aigateway-custom-policy-name) becomes a valid AI Policy `type`. You then attach it like any other AI Policy. Built-in policies each support a fixed set of scopes, but an AI Custom Policy has no scope restriction, so you can attach it at any scope, including to AI Consumers and AI Consumer Groups.

## Manage AI Custom Policies

AI Custom Policies are managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/custom-policies`
* [kongctl](/kongctl/) 1.20.0 or later

For configuration examples and step-by-step setup instructions, see [Set up an AI Custom Policy](#set-up-an-ai-custom-policy).

## Deployment modes

Each AI Custom Policy uses one of two modes, set by its [`type`](#schema-aigateway-custom-policy-type) field:

* `streaming`: You upload both the schema and the handler. {{site.konnect_short_name}} sends the handler to your data planes as part of their configuration.
* `installed`: You install the plugin on each data plane yourself and upload only its schema. {{site.konnect_short_name}} doesn't send any plugin code to data planes.

### Streaming mode

Use `streaming` mode when you want {{site.konnect_short_name}} to distribute your plugin, with no changes to data plane images or file systems.

Data planes must be started with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on` to accept streamed policies.
The same limitations as streaming {{site.base_gateway}} plugins apply. For more information, see [Streaming custom plugins](/custom-plugins/streaming-plugins/#streaming-plugin-limitations).

### Installed mode

Use `installed` mode for plugins that need more than a single schema and handler module, or that you already ship with your data planes.

First install the plugin on each data plane by following the [installation guide](/custom-plugins/installation-and-distribution/). Then create the AI Custom Policy with the plugin's schema.

## Validation rules

{{site.konnect_short_name}} applies the following rules when you create or update an AI Custom Policy:

{% table %}
columns:
  - title: Field
    key: field
  - title: Rule
    key: rule
  - title: Error
    key: error
rows:
  - field: "`name`"
    rule: "Must match the `name` declared in the Lua schema. For example, if your schema returns `{ name = \"my-streaming-custom-policy\", ... }`, set `name: my-streaming-custom-policy`."
    error: "`400`"
  - field: "`handler`"
    rule: "Required in `streaming` mode. Not allowed in `installed` mode."
    error: "`400`"
  - field: "`schema`"
    rule: "Can't contain `custom_validator` or `custom_entity_check`, in either mode."
    error: "`400`"
{% endtable %}

{:.warning}
> You can't delete an AI Custom Policy while any AI Policy uses it as its `type`. The request returns a `400` error until you delete or change those AI Policies.

## Set up an AI Custom Policy

To try the examples, export a sample schema and handler:

{% raw %}
```sh
export LUA_SCHEMA="return{name='my-streaming-custom-policy',fields={{config={type='record',fields={}}}}}"
export LUA_HANDLER="return{PRIORITY=1000,VERSION='0.1.0',access=function(self,conf)kong.response.set_header('X-Custom-Policy','enabled')end}"
```
{% endraw %}

This handler adds an `X-Custom-Policy: enabled` header to responses for requests the policy runs on.

{:.info}
> When you pass Lua through environment variables to the {{site.konnect_short_name}} API, keep it on one line with no spaces or double quotes. Line breaks, spaces, and double quotes break the request body.

### Create a streaming AI Custom Policy

<!-- vale off -->
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
<!-- vale on -->

### Create an installed AI Custom Policy

Install the plugin on each data plane first. See [Installed mode](#installed-mode).
The [`schema`](#schema-aigateway-custom-policy-schema) you upload must be the installed plugin's `schema.lua`, so the `name` declared in it matches both the installed plugin and the AI Custom Policy's `name`.

For a plugin named `my-installed-custom-policy`, set `LUA_SCHEMA` like this:

{% raw %}
```sh
export LUA_SCHEMA="return{name='my-installed-custom-policy',fields={{config={type='record',fields={}}}}}"
```
{% endraw %}

{:.info}
> This sample only works if a plugin named `my-installed-custom-policy` with this schema is installed on your data planes. In `installed` mode, {{site.konnect_short_name}} doesn't send any plugin code to data planes, so the AI Custom Policy only runs if the plugin is already installed.

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

### Use the AI Custom Policy in an AI Policy

Create an AI Policy with `type` set to the AI Custom Policy's `name`. The following example applies the streaming AI Custom Policy globally:

{% entity_example %}
type: policy
data:
  display_name: Custom header - Global
  name: custom-header-global
  type: my-streaming-custom-policy
  enabled: true
  global: true
  config: {}
{% endentity_example %}

### Update an AI Custom Policy

Updates replace the whole definition, so send every required field:

{% navtabs "update-ai-custom-policy" %}
{% navtab "Konnect API" %}

Send a `PUT` request to the `/v1/ai-gateways/{aiGatewayId}/custom-policies/{name|id}` endpoint:

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
  schema: $LUA_SCHEMA
  handler: $LUA_HANDLER
{% endkonnect_api_request %}

{% endnavtab %}
{% navtab "kongctl" %}

Edit the AI Custom Policy in your declarative configuration and apply it:

{% entity_example %}
type: custom_policy
formats:
  - kongctl
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

{% endnavtab %}
{% endnavtabs %}

## Schema

{% entity_schema %}
