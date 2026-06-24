---
title: AI Models
content_type: reference
entities:
  - ai-model
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-model/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Models registered with the {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: Load balancing
    url: /ai-gateway/load-balancing/
  - text: AI Provider entity
    url: /ai-gateway/entities/ai-provider/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
faqs:
  - q: What's the difference between an AI Model entity and the `model` field in an AI Policy configuration?
    a: |
      An AI Model entity is the first-class {{site.ai_gateway}} entity you declare through the {{site.konnect_short_name}} API and UI.
      It defines routing, capabilities, and load balancing. An AI Policy is a reusable configuration that adds behavior (like caching or guardrails) to an AI Model.
      You declare both separately and attach AI Policies to AI Models.


  - q: What happens when I update an AI Model?
    a: |
      {{site.ai_gateway}} deletes the AI Model's derived primitives and recreates them from the updated entity state, all within a single database transaction.
      On failure, the transaction rolls back and no partial state is written.

  - q: Can I apply the same configuration to multiple AI Models?
    a: |
      Yes, by attaching one AI Policy with that configuration to each AI Model.
      AI Policies are not shared between entities, each instance is independent.
      See [AI Policy entity](/ai-gateway/entities/ai-policy/).

  - q: How do I limit which AI Consumers can reach an AI Model?
    a: |
      Set the [`acls`](#schema-aigateway-model-acls) field on the AI Model with allow or deny lists.
      Each entry is a string that references an AI Consumer, AI Consumer Group, or Authenticated Group by name.

  - q: Does the AI Model entity store AI Provider credentials?
    a: |
      No. AI Provider credentials live on the [AI Provider entity](/ai-gateway/entities/ai-provider/) and are materialized into the underlying primitives at AI Model creation time.
      Updating an AI Provider propagates the credential change to all AI Models that reference it.

  - q: Can a client override the model name from the request body?
    a: |
      By default, no. The request `model` field must match the upstream model on one of the AI Model's targets, otherwise the runtime returns a `400` error.
      To accept a client-side alias, set [`config.target_models[].model.alias`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-model-alias) on each target. Clients can then send the alias value in the request `model` field instead of the upstream AI Provider model name. See [Request routing by model alias](/ai-gateway/load-balancing/#request-routing-by-model-alias) for details and examples.

  - q: Can a client override `temperature`, `top_p`, or `top_k` from the request?
    a: |
      Yes. Values for `temperature`, `top_p`, and `top_k` in the request take precedence over the per-target configuration declared on [`target_models[].config`](#schema-aigateway-model-target-models-config).

  - q: Which algorithm does `lowest-latency` use to pick the fastest target?
    a: |
      Exponentially Weighted Moving Average (EWMA). EWMA continuously updates with every response, weighting recent observations more heavily, so older latencies decay over time but still contribute. There is no fixed learning-phase window.

  - q: Does the load balancer keep probing slower targets after picking a winner?
    a: |
      Yes. EWMA ensures every target continues to receive a small share of traffic (typically 0.1% to 5%, depending on the latency gap). This ongoing probing lets the load balancer adapt if a previously slower target becomes faster.

---

## What is an AI Model?

An AI Model is a first-class {{site.ai_gateway}} entity that represents an AI model endpoint exposed through {{site.ai_gateway}}.

An AI Model declares which capabilities it exposes (such as `chat`, `responses`, or `embeddings`), which upstream AI Provider models it routes to, and how requests are load-balanced and logged. {{site.ai_gateway}} translates an AI Model into the underlying primitives that the runtime uses to serve traffic, so you don't need to assemble Services or Routes by hand.

AI Models can be created and managed through the {{site.konnect_short_name}} UI and the {{site.ai_gateway}} API:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/models
{% endtable %}

## How it works

When you configure an AI Model, you define what capabilities it exposes, which upstream AI Providers it routes to, and how requests are load-balanced and logged. At request time, the AI Model mediates traffic between clients and upstream AI Provider APIs:

1. Translates between the request and response format chosen for the AI Model and the upstream AI Provider's native format.
1. Resolves upstream connection coordinates (protocol, host, port, path, HTTP method) from the selected target and its [AI Provider](/ai-gateway/entities/ai-provider/), unless the target is a self-hosted model.
1. Authenticates to the upstream AI Provider using credentials stored on the AI Provider entity.
1. Decorates the upstream request with per-target configuration (such as temperature or token-limit overrides) declared on [`target_models[].config`](#schema-aigateway-model-target-models).
1. Records usage statistics (tokens, cost, latency) for attached log AI Policies, and optionally the full request and response when payload logging is enabled.
1. Fulfills requests to self-hosted models using the supported native format transformations.

A single AI Model can expose multiple upstream AI Providers behind a consistent client-facing format, so callers don't change their request shape when the underlying AI Provider changes.

## How an AI Model maps to runtime configuration

When you create or update an AI Model, {{site.ai_gateway}} generates a fixed set of primitives:

* One [Gateway Service](/gateway/entities/service/).
* One [Route](/gateway/entities/route/) per declared capability in the `capabilities` array.

AI Provider credentials are added into the generated runtime configuration at generation time, sourced from the AI Provider entity that the AI Model's [`target_models`](#schema-aigateway-model-target-models) reference. Updating the AI Provider propagates credential changes to every AI Model that uses it.

Generated primitives are protected. Direct PUT, PATCH, or DELETE calls against the underlying Service or Routes through the standard Admin API are rejected. To change anything about an AI Model's runtime footprint, update the AI Model entity. {{site.ai_gateway}} deletes and recreates the derived primitives within a single transaction.

{:.info}
> **Why a transaction instead of an in-place update?**
>
> An AI Model's structure (which capabilities exist, which providers it routes to) determines how many Routes are needed. A delete-and-recreate cycle is the simplest way to keep the entity and its derived primitives consistent, especially when capabilities are added or removed.

## Capabilities

The [`capabilities`](#schema-aigateway-model-capabilities) field tells {{site.ai_gateway}} which AI workflows the Model exposes. Each capability becomes one Route on the generated Service. A Model must declare at least one capability.

Model [`type`](#schema-aigateway-model-type) controls which capability set applies:

* `model`: synchronous request/response workloads. Supported capabilities are `generate`, `agentic`, `embeddings`, `audio/speech`, `audio/transcription`, `audio/translation`, `image`, `video`, `realtime`, and `rerank`.
* `api`: asynchronous workloads. Supported capabilities are `batches` and `files`.

Not every AI Provider supports every capability. The set of capabilities you can declare on an AI Model depends on what the AI Provider in [`target_models`](#schema-aigateway-model-target-models) exposes. See [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for per-provider details.

{:.info}
> **OpenAI-compatible format**
>
> By default, AI Models expose endpoints using OpenAI-compatible format at `/{model-name}/chat/completions`. Customize the endpoint paths through [`config.route.paths`](#schema-aigateway-model-config-route-paths) if needed.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Default OpenAI path
    key: path
  - title: Description
    key: description
rows:
  - capability: "`generate`"
    path: "`/chat/completions`, `/completions`, `/responses`"
    description: Text generation and conversational responses from generative models.
  - capability: "`agentic`"
    path: "`/assistants`"
    description: Persistent tool-using agents with state management and metadata.
  - capability: "`embeddings`"
    path: "`/embeddings`"
    description: Vector representations for semantic search and similarity matching.
  - capability: "`audio/speech`"
    path: "`/audio/speech`"
    description: Text-to-speech synthesis.
  - capability: "`audio/transcription`"
    path: "`/audio/transcriptions`"
    description: Speech-to-text conversion.
  - capability: "`audio/translation`"
    path: "`/audio/translations`"
    description: Audio translation between languages.
  - capability: "`image`"
    path: "`/images/generations`, `/images/edits`"
    description: Generate or edit images from text prompts.
  - capability: "`video`"
    path: "`/videos`"
    description: Generate videos from text prompts.
  - capability: "`realtime`"
    path: "`/realtime`"
    description: Bidirectional WebSocket streaming for low-latency interactive sessions.
  - capability: "`rerank`"
    path: "`/rerank`"
    description: Rank documents by relevance to a query.
  - capability: "`batches`"
    path: "`/batches`"
    description: Asynchronous bulk LLM requests for long workloads.
  - capability: "`files`"
    path: "`/files`"
    description: File uploads for long documents and structured input.
{% endtable %}
<!-- vale on -->

## Request and response formats

The [`formats`](#schema-aigateway-model-formats) array on a Model declares the request and response shapes the Model accepts. Each entry has a `type` that selects the format. The default `openai` format flattens upstream provider responses into the OpenAI shape, so clients can use a single request and response format across providers.

To preserve a provider's native request and response format instead, set [`formats[].type`](#schema-aigateway-model-formats-type) to a non-OpenAI value. The Model passes requests upstream without conversion, while {{site.ai_gateway}} continues to provide analytics, logging, and cost calculation.

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

When a native format is set, only the corresponding provider is supported with its specific APIs.

## Target models

An AI Model is a virtual model: it exposes one route ([`config.route`](#schema-aigateway-model-config-route)) and one set of capabilities, and routes requests to one or more concrete upstream models declared in its [`target_models`](#schema-aigateway-model-target-models) array. Each entry represents a single upstream model instance with one URL.

For each target, you provide the upstream model name (for example, `gpt-4o`) and reference the Provider to use by its `name`. Each target can also override settings such as [`temperature`](#schema-aigateway-model-target-models-config-temperature), [`max_tokens`](#schema-aigateway-model-target-models-config-max-tokens), [`input_cost`](#schema-aigateway-model-target-models-config-input-cost), and [`output_cost`](#schema-aigateway-model-target-models-config-output-cost).

There's no separate Target Model entity or endpoint. Target models are managed only as nested data inside an AI Model, through the same AI Model API surface used to create, update, and delete the parent. Adding, removing, or modifying a target is an update to the AI Model itself.

## Load balancing

An AI Model routes to a single target by default. Add more than one target when you want redundancy, fallback between providers, or cost and latency optimization. When you have multiple targets, configure [`config.balancer`](#schema-aigateway-model-config-balancer) to distribute requests according to a load balancing algorithm.

When an AI Model has more than one target, the [load balancer](#schema-aigateway-model-config-balancer) sits between the virtual model and its targets, distributing requests according to `config.balancer`. For algorithm details, selection guidance, and tuning, see [Load balancing](/ai-gateway/load-balancing/).

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
  - algorithm: "`round-robin`"
    behavior: Weighted traffic distribution across targets.
  - algorithm: "`consistent-hashing`"
    behavior: Sticky sessions based on header values.
  - algorithm: "`least-connections`"
    behavior: Route to backends with spare capacity.
  - algorithm: "`lowest-latency`"
    behavior: Route to the fastest-responding model.
  - algorithm: "`lowest-usage`"
    behavior: Route based on token counts or cost.
  - algorithm: "`semantic`"
    behavior: Route based on prompt-to-model similarity.
  - algorithm: "`priority`"
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

{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Connection details
    key: details
rows:
  - strategy: "`redis`"
    details: "Connects to Redis with Vector Similarity Search (VSS), AWS MemoryDB for Redis, or Valkey. {{site.ai_gateway}} auto-detects Valkey from the server name field and uses the Valkey-specific driver."
  - strategy: "`pgvector`"
    details: "Connects to PostgreSQL with the pgvector extension."
{% endtable %}

For deeper background on vector storage and similarity matching, see [Embedding-based similarity matching](/ai-gateway/semantic-similarity/).

### Embeddings

An embedding model converts request and response text into vector representations for the vector store. Set [`config.balancer.embeddings`](#schema-aigateway-model-config-balancer-embeddings) to reference a Provider and an embedding model name. Supported provider types are `azure`, `bedrock`, `gemini`, and `huggingface`. The same embedding model also powers the `lowest-usage` algorithm when usage is calculated against semantic content.

## Templating

The AI Model resolves runtime values from request data using placeholder substitution. This lets you select the target model dynamically per request, route to per-deployment Azure endpoints, or fan out to multiple providers from a single AI Model.

Substitution applies to the [`name`](#schema-aigateway-model-target-models-name) of each target model and to any per-target [`config`](#schema-aigateway-model-target-models-config) option. Three placeholders are available:

* `$(headers.header_name)`: the value of a request header.
* `$(uri_captures.path_parameter_name)`: the value of a captured URI path parameter.
* `$(query_params.query_parameter_name)`: the value of a query string parameter.

For examples of using templating, consult the {{site.ai_gateway}} documentation and API reference.

## Access control

An AI Model's [`acls`](#schema-aigateway-model-acls) field controls which identities are allowed to reach the AI Model. The field accepts `allow` and `deny` lists. Each entry is a string that references an AI Consumer, AI Consumer Group, or Authenticated Group by name. An **Authenticated Group** is a dynamic group representing all consumers that have authenticated via a specific OAuth2 scope or claim. Access is enforced at the Service level of the generated primitives.

For per-request authentication and identity, configure the appropriate authentication AI Policy globally or attach it to the AI Model.

## Attach Policies

AI Policies apply configuration and behavior to an AI Model. An AI Policy attached to an AI Model runs at the Service level of the AI Model's generated primitives, so it applies to every request routed through any of the AI Model's capabilities.

An AI Model declares the AI Policies it uses through its [`policies`](#schema-aigateway-model-policies) field. Each entry is a string that references an AI Policy by name or ID. {{site.konnect_short_name}} resolves these references against AI Policies created at `/v1/ai-gateways/{aiGatewayId}/policies`.

You can attach multiple AI Policies to a single AI Model. Each AI Policy is applied independently, so attaching the same AI Policy type twice with different configurations creates two separate instances.

Not every AI Policy type is valid as an AI Model attachment.

AI Policies attached to an AI Model are not deleted when the AI Model is deleted; only the AI Model's reference is removed.

For further information, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

### AI Policy execution order

An AI Policy attached to a Model runs on the Service of the Model's derived primitives. That AI Policy runs at the [priority](/gateway/entities/plugin/#plugin-priority) determined by its type, which affects when it executes relative to other AI Policies on the request.

Model routing executes at a specific point in the request pipeline. AI Policies have different priorities that determine when they run.  Higher priority AI Policy types may run before the Model routing is resolved. Authentication AI Policies (such as OpenID Connect) fall into this category. They gate access correctly because routing to the Model's generated Service already occurred, but model-level identity details (provider and target model) are not available until after Model resolution.

For AI Policies whose behavior depends on the resolved Model identity, use AI Policy types that run at or after Model resolution, or use [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering) to adjust execution order as needed.

## Upstream proxy configuration

The [`config.proxy`](#schema-aigateway-model-config-proxy) object configures HTTP or HTTPS proxies for outbound requests to upstream AI providers. Set `http_proxy` or `https_proxy` with the proxy host and port to route plaintext or TLS requests through a forward proxy. Optionally provide [`auth`](#schema-aigateway-model-config-proxy-auth) credentials (username and password) to authenticate to the proxy, and use `no_proxy` to list hosts that bypass the proxy.

Use this when your data plane sits behind a corporate forward proxy or needs to route through a bastion host.

## Logging and observability

The [`config.logging`](#schema-aigateway-model-config-logging) object configures request and response logging. Set [`statistics`](#schema-aigateway-model-config-logging-statistics) to true to record token counts, latency, and cost. Set [`payloads`](#schema-aigateway-model-config-logging-payloads) to true to also capture full request and response bodies, truncated at [`max_payload_size`](#schema-aigateway-model-config-logging-max-payload-size) bytes (default 1 MB).

{:.warning}
> Payload logging may expose sensitive data. Only enable when your logging pipeline is prepared to handle request and response bodies, and verify that logging destinations comply with your data residency and privacy policies.

For response streaming behavior, see [Streaming](/ai-gateway/streaming/).

## Set up a Model

The following example creates an OpenAI Model that exposes the `generate` capability, routed through a single OpenAI Provider, with token usage logging enabled.

{% entity_example %}
type: model
data:
  display_name: GPT-4o Production
  name: gpt-4o-production
  type: model
  enabled: true
  capabilities:
    - generate
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
