---
title: AI Models
content_type: reference
entities:
  - ai-model
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
toc_depth: 2
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Models registered with the {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: Load balancing with AI Proxy Advanced
    url: /ai-gateway/load-balancing/
  - text: Provider entity
    url: /ai-gateway/entities/provider/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: Consumer Group entity
    url: /ai-gateway/entities/consumer-group/
faqs:
  - q: What's the difference between a Model entity and a `model` field inside a plugin configuration?
    a: |
      A Model entity is the first-class {{site.ai_gateway}} entity you declare through the `/ai/models` API or {{site.konnect_short_name}}.
      {{site.ai_gateway}} derives the underlying plugin and its `model` configuration from the entity.
      You don't configure the underlying plugin directly.

  - q: Can I edit the Service, Routes, or plugins that {{site.ai_gateway}} generates from a Model?
    a: |
      No. Generated primitives are protected from direct modification through the standard Admin API.
      Update the Model entity instead, and {{site.ai_gateway}} recreates the underlying primitives within a single transaction.

  - q: What happens when I update a Model?
    a: |
      {{site.ai_gateway}} deletes the Model's derived primitives and recreates them from the updated entity state, all within a single database transaction.
      On failure, the transaction rolls back and no partial state is written.

  - q: What happens when I delete a Model?
    a: |
      The Model and all its derived primitives (Service, Routes, plugin instances) are deleted within a single transaction.

  - q: Can I apply the same configuration to multiple Models?
    a: |
      Yes, by attaching one Policy with that configuration to each Model.
      Policies are not shared between entities, each instance is independent.
      See [Policy entity](/ai-gateway/entities/policy/).

  - q: How do I limit which consumers can reach a Model?
    a: |
      Set the `acls` field on the Model with allow or deny lists.
      Each entry is a string that references a Consumer, Consumer Group, or Authenticated Group by name.

  - q: Does the Model entity store provider credentials?
    a: |
      No. Provider credentials live on the [Provider entity](/ai-gateway/entities/provider/) and are materialized into the underlying primitives at Model creation time.
      Updating a Provider propagates the credential change to all Models that reference it.

  - q: Can a client override the model name from the request body?
    a: |
      By default, no. The request `model` field must match the upstream model on one of the Model's targets, otherwise the runtime returns a `400` error.
      To accept a client-side alias, set `config.model.alias` on the Model and clients can send the alias value in the request `model` field instead of the upstream provider model name.

  - q: Can a client override `temperature`, `top_p`, or `top_k` from the request?
    a: |
      Yes. Values for `temperature`, `top_p`, and `top_k` in the request take precedence over the per-target configuration declared on `target_models[].config`.

  - q: Which algorithm does `lowest-latency` use to pick the fastest target?
    a: |
      Exponentially Weighted Moving Average (EWMA). EWMA continuously updates with every response, weighting recent observations more heavily, so older latencies decay over time but still contribute. There is no fixed learning-phase window.

  - q: Does the load balancer keep probing slower targets after picking a winner?
    a: |
      Yes. EWMA ensures every target continues to receive a small share of traffic (typically 0.1% to 5%, depending on the latency gap). This ongoing probing lets the load balancer adapt if a previously slower target becomes faster.

  - q: Are on-prem and {{site.konnect_short_name}} Model entities the same?
    a: |
      The schemas are intentionally aligned at the field level. The same Model definition works in both modes.
      On-prem omits a few {{site.konnect_short_name}}-specific path segments and concepts that don't apply in a single-deployment context, such as the `ai-gateways/{id}` container and Data Plane certificate or node management. The Model entity itself is identical.
---

## What is a Model?

A Model is a first-class {{site.ai_gateway}} entity that represents an AI model endpoint exposed through {{site.ai_gateway}}.

A Model declares which capabilities it exposes (such as `chat`, `responses`, or `embeddings`), which upstream provider models it routes to, and how requests are load-balanced and logged. {{site.ai_gateway}} translates a Model into the underlying primitives that the runtime uses to serve traffic, so you don't need to assemble Services, Routes, or plugin entries by hand.

Models are managed through the {{site.ai_gateway}} entity surface in both deployment modes:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/models
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/models
{% endtable %}

## How it works

At request time, the Model mediates traffic between clients and upstream provider APIs:

1. Translates between the request and response format chosen for the Model and the upstream provider's native format.
1. Resolves upstream connection coordinates (protocol, host, port, path, HTTP method) from the selected target and its [Provider](/ai-gateway/entities/provider/), unless the target is a self-hosted model.
1. Authenticates to the upstream provider using credentials stored on the Provider entity.
1. Decorates the upstream request with per-target configuration (such as temperature or token-limit overrides) declared on `target_models[].config`.
1. Records usage statistics (tokens, cost, latency) for attached log Policies, and optionally the full request and response when payload logging is enabled.
1. Fulfills requests to self-hosted models using the supported native format transformations.

A single Model can expose multiple upstream providers behind a consistent client-facing format, so callers don't change their request shape when the underlying Provider changes.

## How a Model maps to runtime configuration

When you create or update a Model, {{site.ai_gateway}} generates a fixed set of primitives:

* One [Gateway Service](/gateway/entities/service/).
* One [Route](/gateway/entities/route/) per declared capability in the `capabilities` array.
* One [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin per generated Route.

Provider credentials are added into the AI Proxy Advanced plugin configuration at generation time, sourced from the Provider entity that the Model's `target_models` reference. Updating the Provider propagates credential changes to every Model that uses it.

Generated primitives are protected. Direct PUT, PATCH, or DELETE calls against the underlying Service, Routes, or plugin entries through the standard Admin API are rejected. To change anything about a Model's runtime footprint, update the Model entity. {{site.ai_gateway}} deletes and recreates the derived primitives within a single transaction.

{:.info}
> **Why a transaction instead of an in-place update?**
>
> A Model's structure (which capabilities exist, which providers it routes to) determines how many Routes and plugin entries are needed. A delete-and-recreate cycle is the simplest way to keep the entity and its derived primitives consistent, especially when capabilities are added or removed.

## Capabilities

The [`capabilities`](#schema-aigateway-model-capabilities) field defines which APIs the Model exposes. Each capability becomes one generated Route on the Model Service. A Model must declare at least one capability.

Model [`type`](#schema-aigateway-model-type) limits which capabilities you can declare:

* `model`: synchronous request/response workloads through generative APIs.
* `api`: asynchronous workloads through files and batches APIs.

Provider support varies by capability. See [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific coverage.

The following table maps each capability to its route type, OpenAI API reference, and generative AI category. See the [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) reference pages for provider-specific details.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Route type
    key: route
  - title: OpenAI API reference
    key: reference
  - title: Gen AI category
    key: category
rows:
  - capability: "`chat`"
    route: "`llm/v1/chat`"
    reference: "[Chat completions](https://platform.openai.com/docs/api-reference/chat/create)"
    category: "`text/generation`"
  - capability: "`embeddings`"
    route: "`llm/v1/embeddings`"
    reference: "[Embeddings](https://platform.openai.com/docs/api-reference/embeddings)"
    category: "`text/embeddings`"
  - capability: "`assistants`"
    route: "`llm/v1/assistants`"
    reference: "[Assistants](https://platform.openai.com/docs/api-reference/assistants)"
    category: "`text/generation`"
  - capability: "`responses`"
    route: "`llm/v1/responses`"
    reference: "[Responses](https://platform.openai.com/docs/api-reference/responses)"
    category: "`text/generation`"
  - capability: "`audio-transcriptions`"
    route: "`audio/v1/audio/transcriptions`"
    reference: "[Create transcription](https://platform.openai.com/docs/api-reference/audio/createTranscription)"
    category: "`audio/transcription`"
  - capability: "`audio-translations`"
    route: "`audio/v1/audio/translations`"
    reference: "[Create translation](https://platform.openai.com/docs/api-reference/audio/createTranslation)"
    category: "`audio/transcription`"
  - capability: "`image-generation`"
    route: "`image/v1/images/generations`"
    reference: "[Create image](https://platform.openai.com/docs/api-reference/images)"
    category: "`image/generation`"
  - capability: "`image-edits`"
    route: "`image/v1/images/edits`"
    reference: "[Create image edit](https://platform.openai.com/docs/api-reference/images/createEdit)"
    category: "`image/generation`"
  - capability: "`video-generations`"
    route: "`video/v1/videos/generations`"
    reference: "[Create video](https://platform.openai.com/docs/api-reference/videos/create)"
    category: "`video/generation`"
  - capability: "`realtime`"
    route: "`realtime/v1/realtime`"
    reference: "[Realtime](https://platform.openai.com/docs/api-reference/realtime)"
    category: "`realtime/generation`"
  - capability: "`batches`"
    route: "`llm/v1/batches`"
    reference: "[Batch](https://platform.openai.com/docs/api-reference/batch)"
    category: "N/A"
  - capability: "`files`"
    route: "`llm/v1/files`"
    reference: "[Files](https://platform.openai.com/docs/api-reference/files)"
    category: "N/A"
{% endtable %}
<!-- vale on -->

## Request and response formats

The [`formats`](#schema-aigateway-model-formats) array on a Model declares the request and response shapes the Model accepts. Each entry has a `type` that selects the format. The default `openai` format flattens upstream provider responses into the OpenAI shape, so clients can use a single request and response format across providers.

To preserve a provider's native request and response format instead, set `formats[].type` to a non-OpenAI value. The Model passes requests upstream without conversion, while {{site.ai_gateway}} continues to provide analytics, logging, and cost calculation.

<!-- vale off -->
{% table %}
columns:
  - title: Format
    key: format
  - title: Provider
    key: provider
  - title: Native capabilities
    key: capabilities
rows:
  - format: "`openai`"
    provider: All supported providers (default)
    capabilities: Translates between OpenAI request and response shapes and the upstream provider format.
  - format: "`anthropic`"
    provider: "[Anthropic](/ai-gateway/ai-providers/anthropic/#supported-native-llm-formats-for-anthropic)"
    capabilities: Messages, batch processing.
  - format: "`bedrock`"
    provider: "[Amazon Bedrock](/ai-gateway/ai-providers/bedrock/#supported-native-llm-formats-for-amazon-bedrock)"
    capabilities: Converse, RAG (RetrieveAndGenerate), reranking, async invocation.
  - format: "`cohere`"
    provider: "[Cohere](/ai-gateway/ai-providers/cohere/#supported-native-llm-formats-for-cohere)"
    capabilities: Reranking.
  - format: "`gemini`"
    provider: "[Gemini](/ai-gateway/ai-providers/gemini/#supported-native-llm-formats-for-gemini), [Vertex AI](/ai-gateway/ai-providers/vertex/#supported-native-llm-formats-for-gemini-vertex)"
    capabilities: Content generation, embeddings, batches, file uploads, reranking, long-running predictions.
  - format: "`huggingface`"
    provider: "[Hugging Face](/ai-gateway/ai-providers/huggingface/#supported-native-llm-formats-for-hugging-face)"
    capabilities: Text generation, streaming.
{% endtable %}
<!-- vale on -->

When a native format is set, only the corresponding provider is supported with its specific APIs. For format-specific behavior and limitations, see the [AI Proxy plugin reference](/plugins/ai-proxy/#supported-native-llm-formats).

## Target models

A Model is a virtual model: it exposes one route ([`config.route`](#schema-aigateway-model-config-route)) and one set of capabilities, and routes requests to one or more concrete upstream models declared in its [`target_models`](#schema-aigateway-model-target-models) array. Each entry represents a single upstream model instance with one URL.

For each target, you provide the upstream model name (for example, `gpt-4o`) and reference the Provider to use by its `name`. Each target can also override settings such as `temperature`, `max_tokens`, `input_cost`, and `output_cost`.

There's no separate Target Model entity or endpoint. Target models are managed only as nested data inside a Model, through the same Model API surface used to create, update, and delete the parent. Adding, removing, or modifying a target is an update to the Model itself.

## Load balancing

When a Model has more than one target, the [load balancer](#schema-aigateway-model-config-balancer) sits between the virtual model and its targets, distributing requests according to `config.balancer`. For algorithm details, selection guidance, and tuning, see [Load balancing with AI Proxy Advanced](/ai-gateway/load-balancing/).

### Algorithms

The [`algorithm`](#schema-aigateway-model-config-balancer-algorithm) field selects one of seven load balancing strategies for distributing requests across target models. For detailed guidance focused on Model entities, see [Load balancing algorithms for Model entities](/ai-gateway/load-balancing/#load-balancing-algorithms-for-model-entities).

<!-- vale off -->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Behavior
    key: behavior
rows:
  - algorithm: "[`round-robin`](/plugins/ai-proxy-advanced/examples/round-robin/)"
    behavior: Weighted traffic distribution across targets.
  - algorithm: "[`consistent-hashing`](/plugins/ai-proxy-advanced/examples/consistent-hashing/)"
    behavior: Sticky sessions based on header values.
  - algorithm: "[`least-connections`](/plugins/ai-proxy-advanced/examples/least-connections/)"
    behavior: Route to backends with spare capacity.
  - algorithm: "[`lowest-latency`](/plugins/ai-proxy-advanced/examples/lowest-latency/)"
    behavior: Route to the fastest-responding model.
  - algorithm: "[`lowest-usage`](/plugins/ai-proxy-advanced/examples/lowest-usage/)"
    behavior: Route based on token counts or cost.
  - algorithm: "[`semantic`](/plugins/ai-proxy-advanced/examples/semantic/)"
    behavior: Route based on prompt-to-model similarity.
  - algorithm: "[`priority`](/plugins/ai-proxy-advanced/examples/priority/)"
    behavior: Tiered failover across model groups.
{% endtable %}
<!-- vale on -->

### Algorithm examples

{% navtabs "model-entity-balancer-algorithm" %}
{% navtab "Round-robin" %}
{% entity_example %}
type: model
data:
  name: gpt-router-round-robin
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      provider:
        name: openai-prod
      weight: 70
    - name: gpt-4o-mini
      provider:
        name: openai-prod
      weight: 30
  config:
    balancer:
      algorithm: round-robin
{% endentity_example %}
{% endnavtab %}

{% navtab "Consistent-hashing" %}
{% entity_example %}
type: model
data:
  name: gpt-router-consistent-hashing
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      provider:
        name: openai-prod
    - name: gpt-4o-mini
      provider:
        name: openai-prod
  config:
    balancer:
      algorithm: consistent-hashing
      hash_on_header: X-User-ID
{% endentity_example %}
{% endnavtab %}

{% navtab "Least-connections" %}
{% entity_example %}
type: model
data:
  name: gpt-router-least-connections
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      provider:
        name: openai-prod
      weight: 70
    - name: gpt-4o-mini
      provider:
        name: openai-prod
      weight: 30
  config:
    balancer:
      algorithm: least-connections
{% endentity_example %}
{% endnavtab %}

{% navtab "Lowest-usage" %}
{% entity_example %}
type: model
data:
  name: gpt-router-lowest-usage
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      provider:
        name: openai-prod
    - name: gpt-4o-mini
      provider:
        name: openai-prod
  config:
    balancer:
      algorithm: lowest-usage
      tokens_count_strategy: cost
{% endentity_example %}
{% endnavtab %}

{% navtab "Lowest-latency" %}
{% entity_example %}
type: model
data:
  name: gpt-router-lowest-latency
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      provider:
        name: openai-prod
    - name: gpt-4o-mini
      provider:
        name: openai-prod
  config:
    balancer:
      algorithm: lowest-latency
      latency_strategy: e2e
{% endentity_example %}
{% endnavtab %}

{% navtab "Semantic" %}
{% entity_example %}
type: model
data:
  name: gpt-router-semantic
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o
      description: General-purpose assistant
      provider:
        name: openai-prod
    - name: claude-3-5-sonnet
      description: Long-form reasoning assistant
      provider:
        name: anthropic-prod
  config:
    balancer:
      algorithm: semantic
      vectordb:
        strategy: redis
        redis:
          host: redis.internal
          port: 6379
      embeddings:
        provider:
          name: openai-prod
        model: text-embedding-3-small
{% endentity_example %}
{% endnavtab %}

{% navtab "Priority" %}
{% entity_example %}
type: model
data:
  name: gpt-router-priority
  type: model
  enabled: true
  capabilities:
    - chat
  formats:
    - type: openai
  target_models:
    - name: gpt-4o-mini
      provider:
        name: openai-prod
      priority: 1
      weight: 100
    - name: gpt-4o
      provider:
        name: openai-prod
      priority: 2
      weight: 100
  config:
    balancer:
      algorithm: priority
{% endentity_example %}
{% endnavtab %}
{% endnavtabs %}

### Retry and fallback

The load balancer supports configurable retries, timeouts, and failover to different targets when one is unavailable. Fallback works across targets with any supported format, so you can mix providers freely (for example, OpenAI and Mistral). For configuration details, see [Retry and fallback configuration](/ai-gateway/load-balancing/#retry-and-fallback).

{:.info}
> Client errors don't trigger failover. To fail over on additional error types, set
> [`failover_criteria`](#schema-aigateway-model-config-balancer-failover-criteria) to include HTTP codes
> like `http_429` or `http_502`, and `non_idempotent` for POST requests.

### Health check and circuit breaker

The load balancer includes a circuit breaker that improves reliability under sustained failures. When a target reaches the failure threshold set by [`max_fails`](#schema-aigateway-model-config-balancer-max-fails), the load balancer stops routing requests to it until the [`fail_timeout`](#schema-aigateway-model-config-balancer-fail-timeout) period elapses. For behavior examples and tuning, see [Circuit breaker](/ai-gateway/load-balancing/#health-check-and-circuit-breaker).

### Vector store

A vector store powers the [`semantic`](#schema-aigateway-model-config-balancer-algorithm) balancer algorithm and other similarity-matching workflows on a Model. Configure it through [`config.balancer.vectordb`](#schema-aigateway-model-config-balancer-vectordb).

{% include plugins/ai-vector-db.md name="Model entity" %}


### Embeddings

An embedding model converts request and response text into vector representations for the vector store. Set [`config.balancer.embeddings`](#schema-aigateway-model-config-balancer-embeddings) to reference a Provider and an embedding model name. Supported provider types are `azure`, `bedrock`, `gemini`, and `huggingface`. The same embedding model also powers the `lowest-usage` algorithm when usage is calculated against semantic content.

## Templating

The Model resolves runtime values from request data using placeholder substitution. This lets you select the target model dynamically per request, route to per-deployment Azure endpoints, or fan out to multiple providers from a single Model.

Substitution applies to the [`name`](#schema-aigateway-model-target-models-name) of each target model and to any per-target [`config`](#schema-aigateway-model-target-models-config) option. Three placeholders are available:

* `$(headers.header_name)`: the value of a request header.
* `$(uri_captures.path_parameter_name)`: the value of a captured URI path parameter.
* `$(query_params.query_parameter_name)`: the value of a query string parameter.

For end-to-end examples, see [dynamic model selection](/plugins/ai-proxy/examples/sdk-dynamic-model-selection/), [Azure deployment routing](/plugins/ai-proxy/examples/sdk-azure-deployment/), and [proxying multiple models in one Azure instance](/plugins/ai-proxy/examples/sdk-multiple-providers/) on the AI Proxy plugin page.

## Access control

A Model's `acls` field controls which identities are allowed to reach the Model. The field accepts `allow` and `deny` lists. Each entry is a string that references a Consumer, Consumer Group, or Authenticated Group by name. Access is enforced at the Service level of the generated primitives.

For per-request authentication and identity, configure the appropriate authentication plugin globally or as a Policy on the Model.

## Attach Policies

Policies are how plugin configurations apply to a Model. A Policy attached to a Model runs at the Service level of the Model's generated primitives, so it applies to every request routed through any of the Model's capabilities.

A Model declares the Policies it uses through its `policies` field. Each entry is a string that references a Policy by name or ID. {{site.konnect_short_name}} resolves these references against Policies created at `/v1/ai-gateways/{aiGatewayId}/policies`. On-prem also supports the nested endpoint `/ai/models/{modelId}/policies`, which creates and attaches a Policy in one call.

You can attach multiple Policies to a single Model. Each Policy has an independent plugin instance, so attaching the same plugin type twice with different configurations creates two separate plugin entries.

{:.warning}
> Model Policy compatibility is based on Policy scope support, not on whether the Policy configuration includes a `model` field.
> If you try to attach a Policy type that doesn't support Model Policy scope, Model create or update fails with a validation error.

Policies created through the nested on-prem endpoint (`POST /ai/models/{modelId}/policies`) are deleted when the Model is deleted. Policies created independently (for example, at `/v1/ai-gateways/{aiGatewayId}/policies` or `/ai/policies`) are not deleted when the Model is deleted; only the Model's reference is removed.

{:.info}
> For further information, see the [Policy entity](/ai-gateway/entities/policy/) reference.

### Plugin priority and Policy execution order

A Policy attached to a Model creates one plugin entry on the Service of the Model's derived primitives. That plugin runs at the [priority](/gateway/entities/plugin/#plugin-priority) of its underlying plugin type, which determines when it executes relative to other plugins on the request.

The AI Proxy Advanced plugin runs at priority `770` and parses the request body to resolve the model name. Any Policy whose underlying plugin type has a priority higher than `770` runs before that resolution. Authentication plugin types (such as OpenID Connect) fall into this category. They still gate access correctly because routing to the Model's generated Service already occurred, but model-level identity details (provider and target model) are not available yet.

For Policies whose runtime behavior depends on the resolved Model identity, attach plugin types that run at priority `770` or lower, or use [dynamic plugin ordering](/gateway/entities/plugin/) to push their execution later.

## Set up a Model

The following example creates an OpenAI Model that exposes both `chat` and `responses` capabilities, routed through a single OpenAI Provider, with token usage logging enabled.

{% entity_example %}
type: model
data:
  display_name: GPT-4o Production
  name: gpt-4o-production
  type: model
  enabled: true
  capabilities:
    - chat
    - responses
  formats:
    - type: openai
  acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  target_models:
    - name: gpt-4o
      provider:
        name: my-openai-account
      config:
        temperature: 0.7
        max_tokens: 4096
        input_cost: 0.0000025
        output_cost: 0.000010
  config:
    logging:
      statistics: true
      payloads: false
    response_streaming: allow
    max_request_body_size: 1048576
    model:
      name_header: true
    balancer:
      algorithm: round-robin
      retries: 3
      connect_timeout: 60000
      read_timeout: 60000
      write_timeout: 60000
{% endentity_example %}

## Schema

{% entity_schema %}
