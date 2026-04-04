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
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

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

Partials allow you to reuse shared configuration across [plugins](/gateway/entities/plugin/).

Some plugins in {{site.base_gateway}} share common configuration settings that often need to be repeated. Partials allow you to extract those shared configurations into reusable entities that can be linked to multiple plugins. Without Partials, you would need to replicate this configuration across all plugins. If the settings change, you would need to update each plugin individually.

To ensure validation and consistency, Partials have defined types. {{site.base_gateway}} supports the following Partial types:

- `redis-ce`: A short and simple Redis configuration.
- `redis-ee`: A Redis configuration with support for Redis Sentinel or Redis Cluster connections.
- `vectordb` {% new_in 3.13 %}: Vector database connection and search settings, shared across AI plugins that perform semantic search.
- `embeddings` {% new_in 3.13 %}: Embeddings model provider and authentication, shared across AI plugins that generate vector embeddings.
- `model` {% new_in 3.13 %}: LLM provider, model name, authentication, and inference settings, shared across AI plugins that call language models.

Each plugin supports only the Partial types listed in its documentation.

{:.info}
> In {{site.konnect_short_name}}, Partials are only supported for bundled {{site.konnect_short_name}} plugins. Custom plugins don't support Partials.

## Redis Partials

Define a Redis Partial once and reference it across plugins to avoid repeating connection details, reduce configuration errors, and ensure consistent Redis behavior. The following plugins use Redis for storing counters, sessions, or cached data:

{% table %}
columns:
  - title: Plugin Name
    key: Name
  - title: Redis Usage (What’s Stored)
    key: Redis
  - title: Partial type
    key: Partial
  - title: Benefit of using a Partial
    key: Benefit
rows:
  - Name: "[ACME](/plugins/acme/)"
    Redis: "Certificate state (Let’s Encrypt ACME data)"
    Partial: "`redis-ce`"
    Benefit: "Keep certificate state storage consistent across environments by reusing one Redis config."
  - Name: "[GraphQL Proxy Caching Advanced](/plugins/graphql-proxy-cache-advanced/)"
    Redis: "Cached GraphQL responses"
    Partial: "`redis-ee`"
    Benefit: "Apply the same Redis configuration to multiple GraphQL caches for easier management."
  - Name: "[GraphQL Rate Limiting Advanced](/plugins/graphql-rate-limiting-advanced/)"
    Redis: "GraphQL request counters"
    Partial: "`redis-ee`"
    Benefit: "Standardise Redis-based GraphQL rate limiting across endpoints with one Partial."
  - Name: "[OpenID Connect](/plugins/openid-connect/)"
    Redis: "Sessions and tokens"
    Partial: "`redis-ee`"
    Benefit: "Reuse Redis settings for session storage, avoiding redundant configs across identity flows."
  - Name: "[Proxy Caching Advanced](/plugins/proxy-cache-advanced/)"
    Redis: "Cached API responses"
    Partial: "`redis-ee`"
    Benefit: "Reuse a single Redis definition to simplify and stabilise cache behaviour."
  - Name: "[Rate Limiting](/plugins/rate-limiting/)"
    Redis: "Request counters"
    Partial: "`redis-ce`"
    Benefit: "Apply the same Redis setup across multiple rate limiting policies without duplication."
  - Name: "[Rate Limiting Advanced](/plugins/rate-limiting-advanced/)"
    Redis: "Request counters (supports Sentinel/Cluster)"
    Partial: "`redis-ee`"
    Benefit: "Centralize complex Redis HA configuration so all services use it reliably."
  - Name: "[Response Rate Limiting](/plugins/response-ratelimiting/)"
    Redis: "Response counters"
    Partial: "`redis-ce`"
    Benefit: "Ensure consistent Redis-backed throttling rules across different services."
  - Name: "[SAML](/plugins/saml/)"
    Redis: "Session data"
    Partial: "`redis-ee`"
    Benefit: "Centralize session handling so all SAML flows share the same Redis configuration."
{% endtable %}

### Set up a Redis Partial

{% entity_example %}
type: partial
data:
  name: my-redis-config
  type: redis-ee
  config:
    host: host.docker.internal
    port: 6379
{% endentity_example %}

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

## AI plugin Partials {% new_in 3.13 %}

{{site.ai_gateway}} plugins often share the same vector database, embeddings model, or LLM configuration across multiple plugins. For example, you might run both the [AI Semantic Cache plugin](/plugins/ai-semantic-cache/) and the [AI RAG Injector plugin](/plugins/ai-rag-injector/) against the same pgvector database using the same OpenAI embeddings model. Without Partials, you would need to define this configuration in each plugin individually.

With AI Partials, define the shared configuration once and link it to any number of plugins.

{% table %}
columns:
  - title: Partial type
    key: type
  - title: Supported plugins
    key: plugins
rows:
  - type: "`vectordb`"
    plugins: "[AI Semantic Cache](/plugins/ai-semantic-cache/), [AI RAG Injector](/plugins/ai-rag-injector/), [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/), [AI Semantic Response Guard](/plugins/ai-semantic-response-guard/)"
  - type: "`embeddings`"
    plugins: "[AI Semantic Cache](/plugins/ai-semantic-cache/), [AI RAG Injector](/plugins/ai-rag-injector/), [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/), [AI Semantic Response Guard](/plugins/ai-semantic-response-guard/)"
  - type: "`model`"
    plugins: "[AI Proxy Advanced](/plugins/ai-proxy-advanced/), [AI Request Transformer](/plugins/ai-request-transformer/), [AI Response Transformer](/plugins/ai-response-transformer/), [AI LLM as Judge](/plugins/ai-llm-as-judge/)"
{% endtable %}

The [AI Proxy Advanced plugin](/plugins/ai-proxy-advanced/) supports all three AI Partial types. A `model` Partial applies to each entry in the `config.targets` array, so you can share one provider configuration across multiple targets.

### Set up AI Partials

{:.info}
> The following examples use OpenAI as the embeddings and model provider, and pgvector as the vector database.
> You'll need an [OpenAI API key](https://platform.openai.com/api-keys) and a running pgvector instance.

#### VectorDB Partial (pgvector)

Create a Partial with `type: vectordb`:

{% entity_example %}
type: partial
data:
  name: shared-vectordb
  type: vectordb
  config:
    strategy: pgvector
    dimensions: 1536
    distance_metric: cosine
    pgvector:
      host: ${pgvector_host}
      port: 5432
      database: kong-pgvector
      user: postgres
      password: ${pgvector_password}

variables:
  pgvector_host:
    value: $PGVECTOR_HOST
    description: The hostname of your pgvector database.
  pgvector_password:
    value: $PGVECTOR_PASSWORD
    description: The password for your pgvector database.
{% endentity_example %}

#### Embeddings Partial (OpenAI)

Create a Partial with `type: embeddings`:

{% entity_example %}
type: partial
data:
  name: shared-embeddings
  type: embeddings
  config:
    auth:
      header_name: Authorization
      header_value: Bearer ${openai_api_key}
    model:
      provider: openai
      name: text-embedding-3-small

variables:
  openai_api_key:
    value: $OPENAI_API_KEY
    description: Your OpenAI API key.
{% endentity_example %}

#### Model Partial (OpenAI GPT-4o)

Create a Partial with `type: model`:

{% entity_example %}
type: partial
data:
  name: shared-llm
  type: model
  config:
    route_type: llm/v1/chat
    auth:
      header_name: Authorization
      header_value: Bearer ${openai_api_key}
    model:
      provider: openai
      name: gpt-5.1

variables:
  openai_api_key:
    value: $OPENAI_API_KEY
    description: Your OpenAI API key.
{% endentity_example %}

### Link AI Partials to plugins

Once created, link AI Partials to plugins the same way as Redis Partials: pass the Partial ID in the `partials` array. See [Add a Partial to a plugin](#add-a-partial-to-a-plugin).

{:.info}
> You cannot provide inline configuration for the same fields that a linked Partial covers. Either define the settings directly in the plugin, or leave that block empty and use a Partial instead.

## Enable Partials support in custom plugins

Use the Partials feature in your [custom plugins](/custom-plugins/reference/) by adjusting the plugin schema.
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

## Schema

{% entity_schema %}