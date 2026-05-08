---
title: AI Models
content_type: reference
entities:
  - ai-model
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
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
    url: /gateway/entities/consumer-group/
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

The [`capabilities`](#schema-aigateway-model-capabilities) field tells {{site.ai_gateway}} which AI workflows the Model exposes. Each capability becomes one Route on the generated Service. A Model must declare at least one capability.

Model [`type`](#schema-aigateway-model-type) controls which capability set applies:

* `model`: synchronous request/response workloads through generative APIs. Supported capabilities are `chat`, `embeddings`, `assistants`, `responses`, `audio-transcriptions`, `audio-translations`, `image-generation`, `image-edits`, `video-generations`, and `realtime`.
* `api`: asynchronous workloads through the files and batches APIs. Supported capabilities are `batches` and `files`.

Not every provider supports every capability. The set of capabilities you can declare on a Model depends on what the provider in `target_models` exposes. See [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for per-provider details.

The following table maps each capability to an OpenAI API reference and the corresponding [AI Proxy plugin](/plugins/ai-proxy/) example.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Description
    key: description
  - title: Example route
    key: example
rows:
  - capability: "`chat`"
    description: Conversational responses from a sequence of messages.
    example: "[`llm/v1/chat`](/plugins/ai-proxy/examples/openai-chat-route/)"
  - capability: "`embeddings`"
    description: Vector representations for semantic search and similarity matching.
    example: "[`llm/v1/embeddings`](/plugins/ai-proxy/examples/embeddings-route-type/)"
  - capability: "`assistants`"
    description: Persistent tool-using agents with metadata for debugging and evaluation.
    example: "[`llm/v1/assistants`](/plugins/ai-proxy/examples/assistants-route-type/)"
  - capability: "`responses`"
    description: REST-based full-text responses.
    example: "[`llm/v1/responses`](/plugins/ai-proxy/examples/responses-route-type/)"
  - capability: "`audio-transcriptions`"
    description: Speech-to-text.
    example: "[`audio/v1/audio/transcriptions`](/plugins/ai-proxy/examples/audio-transcription-openai/)"
  - capability: "`audio-translations`"
    description: Audio translation between languages.
    example: "[`audio/v1/audio/translations`](/plugins/ai-proxy/examples/audio-translation-openai/)"
  - capability: "`image-generation`"
    description: Generate images from text prompts.
    example: "[`image/v1/images/generations`](/plugins/ai-proxy/examples/image-generation-openai/)"
  - capability: "`image-edits`"
    description: Modify images from text prompts.
    example: "[`image/v1/images/edits`](/plugins/ai-proxy/examples/image-edits-openai/)"
  - capability: "`video-generations`"
    description: Generate videos from text prompts.
    example: "[`video/v1/videos/generations`](/plugins/ai-proxy/examples/video-generation-openai/)"
  - capability: "`realtime`"
    description: Bidirectional WebSocket streaming for low-latency, interactive voice and text.
    example: "[`realtime/v1/realtime`](/plugins/ai-proxy-advanced/examples/realtime-route-openai/)"
  - capability: "`batches`"
    description: Asynchronous bulk LLM requests for long workloads.
    example: "[`llm/v1/batches`](/plugins/ai-proxy/examples/batches-route-type/)"
  - capability: "`files`"
    description: File uploads for long documents and structured input.
    example: "[`llm/v1/files`](/plugins/ai-proxy/examples/files-route-type/)"
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

The [`algorithm`](#schema-aigateway-model-config-balancer-algorithm) field selects one of seven load balancing strategies for distributing requests across target models.

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

### Retry and fallback

The load balancer supports configurable retries, timeouts, and failover to different targets when one is unavailable. Fallback works across targets with any supported format, so you can mix providers freely (for example, OpenAI and Mistral). For configuration details, see [Retry and fallback configuration](/ai-gateway/load-balancing/#retry-and-fallback).

{:.info}
> Client errors don't trigger failover. To fail over on additional error types, set
> [`failover_criteria`](#schema-aigateway-model-config-balancer-failover-criteria) to include HTTP codes
> like `http_429` or `http_502`, and `non_idempotent` for POST requests.

### Health check and circuit breaker

The load balancer includes a circuit breaker that improves reliability under sustained failures. When a target reaches the failure threshold set by [`max_fails`](#schema-aigateway-model-config-balancer-max-fails), the load balancer stops routing requests to it until the [`fail_timeout`](#schema-aigateway-model-config-balancer-fail-timeout) period elapses. For behavior examples and tuning, see [Circuit breaker](/ai-gateway/load-balancing/#health-check-and-circuit-breaker).

### Vector store

A vector store holds numerical representations (embeddings) of requests and responses so the runtime can match new requests against stored vectors. It powers the [`semantic`](#schema-aigateway-model-config-balancer-algorithm) algorithm and any similarity-matching workflow on the Model. Configure storage through [`config.balancer.vectordb`](#schema-aigateway-model-config-balancer-vectordb) by selecting a `strategy`:

* `redis`: connects to Redis with Vector Similarity Search (VSS), AWS MemoryDB for Redis, or Valkey. {{site.ai_gateway}} auto-detects Valkey from the server name field and uses the Valkey-specific driver.
* `pgvector`: connects to PostgreSQL with the pgvector extension.

For deeper background on vector storage and similarity matching, see [Embedding-based similarity matching](/ai-gateway/semantic-similarity/).

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

Policies are the way you apply plugin configurations to a Model. A Policy attached to a Model runs at the Service level of the Model's generated primitives, so it applies to every request routed through any of the Model's capabilities.

A Model declares the Policies it uses through its `policies` field. Each entry is a string that references a Policy by name or ID. {{site.konnect_short_name}} resolves these references against Policies created at `/v1/ai-gateways/{aiGatewayId}/policies`. On-prem also supports the nested endpoint `/ai/models/{modelId}/policies`, which creates and attaches a Policy in one call.

You can attach multiple Policies to a single Model. Each Policy has an independent plugin instance, so attaching the same plugin type twice with different configurations creates two separate plugin entries.

Not every plugin type is valid as a Model Policy.

Policies attached to a Model are deleted when the Model is deleted.

For further information see the [Policy entity](/ai-gateway/entities/policy/) reference.

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
