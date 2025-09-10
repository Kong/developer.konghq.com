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
Some entities in {{site.base_gateway}} share common configuration settings that often need to be repeated. For example, multiple [plugins](/gateway/entities/plugin/) that connect to Redis may require the same connection settings. Without Partials, you would need to replicate this configuration across all plugins. If the settings change, you would need to update each plugin individually.

Partials address this issue by allowing you to extract shared configurations into reusable entities that can be linked to multiple plugins. To ensure validation and consistency, Partials have defined types. 

{{site.base_gateway}} supports the following types of Partials; each plugin supports only one type:
- `redis-ce`: A shorter, simpler configuration.
- `redis-ee`: A configuration with support for Redis Sentinel or Redis Cluster connections.

Any plugin that supports Redis configuration can reference those settings using Partial entities, enabling shared configuration across plugin instances.

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

 By defining a Redis Partial once and then referencing it across these plugins, you avoid repeating connection details, reduce configuration errors, and ensure consistent Redis behaviour throughout your gateway. The following plugins use Redis for storing counters, sessions, or cached data:

{% table %}
columns:
  - title: Plugin Name
    key: Name
  - title: Redis Usage (What’s Stored)
    key: Redis
  - title: Benefit of using a Partial
    key: Benefit
rows:
  - Name: [ACME](/_kong_plugins/acme/index.md)
    Redis: Certificate state (Let’s Encrypt ACME data)
    Benefit: Keep certificate state storage consistent across environments by reusing one Redis config.
  - Name: [GraphQL Proxy Caching Advanced](/_kong_plugins/graphql-proxy-cache-advanced/index.md)
    Redis: Cached GraphQL responses
    Benefit: Apply the same Redis configuration to multiple GraphQL caches for easier management.
  - Name: [GraphQL Rate Limiting Advanced](/_kong_plugins/graphql-rate-limiting-advanced/index.md)
    Redis: GraphQL request counters
    Benefit: Standardise Redis-based GraphQL rate limiting across endpoints with one Partial.
  - Name: [OpenID Connect](/_kong_plugins/openid-connect/index.md)
    Redis: Sessions and tokens
    Benefit: Reuse Redis settings for session storage, avoiding redundant configs across identity flows.
  - Name: [Proxy Caching Advanced](/_kong_plugins/proxy-cache-advanced/index.md)
    Redis: Cached API responses
    Benefit: Reuse a single Redis definition to simplify and stabilise cache behaviour.
  - Name: [Rate Limiting](/_kong_plugins/rate-limiting/index.md)
    Redis: Request counters
    Benefit: Apply the same Redis setup across multiple rate-limiting policies without duplication.
  - Name: [Rate Limiting Advanced](/_kong_plugins/rate-limiting-advanced/index.md)
    Redis: Request counters (supports Sentinel/Cluster)
    Benefit: Centralise complex Redis HA configuration so all services use it reliably.
  - Name: [Response Rate Limiting](/_kong_plugins/response-ratelimiting/index.md)
    Redis: Response counters
    Benefit: Ensure consistent Redis-backed throttling rules across different services.
  - Name: [SAML](/_kong_plugins/saml/index.md)
    Redis: Session data
    Benefit: Centralise session handling so all SAML flows share the same Redis configuration.              
{% endtable %}

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