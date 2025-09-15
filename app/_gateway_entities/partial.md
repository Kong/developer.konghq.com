---
title: Partials
content_type: reference
entities:
  - partial

description: |
  Partials allow you to extract shared configurations into reusable entities that can be linked to multiple plugins

api_specs:
  - gateway/admin-ee

tools:
  - admin-api
  - kic
  - deck
  - terraform
  - konnect-api

schema:
  api: gateway/admin-ee
  path: /schemas/Partial

related_resources:
  - text: About plugins
    url: /gateway/entities/plugin/
  - text: Plugin Hub
    url: /plugins/

tags:
  - reuse

search_aliases:
  - configuration reuse
  - plugin reuse

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'
---

## What is a Partial?

Partials allow you to reuse shared Redis configurations across plugins.

Some [plugins](/gateway/entities/plugin/) in {{site.base_gateway}} share common Redis configuration settings that often need to be repeated. 
Partials allow you to extract those shared configurations into reusable entities that can be linked to multiple plugins.
Without Partials, you would need to replicate this configuration across all plugins. If the settings change, you would need to update each plugin individually.

To ensure validation and consistency, Partials have defined types.
{{site.base_gateway}} supports the following types of Partials, `redis-ce` and `redis-ee`. `redis-ce` has a shorter and simpler configuration, whereas `redis-ee` provides options for configuring Redis Sentinel or Redis Cluster connections. Each plugin that supports Partials only supports one of these types.

{:.info}
> In {{site.konnect_short_name}}, Partials are only supported for bundled {{site.konnect_short_name}} plugins. Custom plugins don't support Partials.

## Schema

{% entity_schema %}

## Set up a Partial

{% entity_example %}
type: partial
data:
  name: my-redis-config
  type: redis-ee
  config:
    host: host.docker.internal
    port: 6379
{% endentity_example %}

## Use Partials

The following examples describe how to use Partials with plugins.

### Add a Partial to a plugin

To use a Partial in a plugin, configure the `partials.id` parameter:
{% entity_example %}
type: plugin
data:
  name: ai-rate-limiting-advanced
  partials: 
    - id: 602317b0-9503-45c1-bcbf-c69f13155b49
  config:
    llm_providers:
    - name: openai
      limit:
      - 100
      window_size:
      - 60
{% endentity_example %}

### Remove a Partial from a plugin

To remove a Partial, remove the `partials` parameter. Make sure to configure the corresponding elements directly in your plugin configuration:
{% entity_example %}
type: plugin
data:
  name: ai-rate-limiting-advanced
  config:
    llm_providers:
    - name: openai
      limit:
      - 100
      window_size:
      - 60
    redis:
      host: localhost
      port: 6379
{% endentity_example %}

### Check Partial usage

To see which plugins use a specific Partial:
1. Use [`GET /partials/`](/api/gateway/admin-ee/#/operations/listPartials) to get the list of Partials, and get the ID of the Partial to check.
1. Use [`GET /partials/$PARTIAL_ID`](/api/gateway/admin-ee/#/operations/getPartial) to get a list of plugins that use this Partial.

## Enable Partials support in custom plugins

You can leverage the Partials feature in your [custom plugins](/custom-plugins/reference/) by adjusting the plugin schema.
To make custom plugins compatible with Partials, add the `supported_partials` key to the schema and specify
the appropriate Partial type.

Here is an example schema for a custom plugin using a Partial:
```lua
{
  name = "custom-plugin-with-redis",
  supported_partials = {
    ["redis-ee"] = { "config.redis" },
  },
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { some_other_config_key = { type = "string", required = true }},
          { redis = redis.config_schema }
        },
      },
    },
  },
}
```

{:.warning} 
> **Using DAO in custom plugins**
> 
> Be aware that when using a Partial, the configuration belonging to the Partial is no longer stored alongside
> the plugin. If your code relies on {{site.base_gateway}}'s DAO and expects entities to contain Redis information,
> this data won't be retrieved when using `kong.db.plugins:select(plugin_id)`.
> Such a call will only fetch data stored in the plugin itself.
>
> To include the Partial's data within the plugin configuration, you must pass a special option parameter,
> such as: `kong.db.plugins:select(plugin_id, { expand_partials = true })`.
