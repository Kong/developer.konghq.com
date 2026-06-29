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
      To accept a client-side alias, set [`config.model.alias`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-model-alias). Clients can then send the alias value in the request `model` field instead of the upstream AI Provider model name. See [Request routing by model alias](/ai-gateway/load-balancing/#request-routing-by-model-alias) for details and examples.

  - q: Can a client override `temperature`, `top_p`, or `top_k` from the request?
    a: |
      Yes. Values for `temperature`, `top_p`, and `top_k` in the request take precedence over the per-target configuration declared on [`targets[].config`](#schema-aigateway-model-targets).

  - q: Which algorithm does `lowest-latency` use to pick the fastest target?
    a: |
      Exponentially Weighted Moving Average (EWMA). EWMA continuously updates with every response, weighting recent observations more heavily, so older latencies decay over time but still contribute. There is no fixed learning-phase window.

  - q: Does the load balancer keep probing slower targets after picking a winner?
    a: |
      Yes. EWMA ensures every target continues to receive a small share of traffic (typically 0.1% to 5%, depending on the latency gap). This ongoing probing lets the load balancer adapt if a previously slower target becomes faster.

---

## What is an AI Model?

The AI Model entity lets you expose LLM endpoints through {{site.ai_gateway}} for clients to call. Use AI Models to expose multiple LLM providers under a single endpoint, load-balance traffic across them, add observability to model traffic, or attach policies for security and transformation.

An AI Model declares which capabilities it exposes (like `chat` or `embeddings`), which upstream AI Provider models it routes to, and how requests are distributed and logged. {{site.ai_gateway}} handles the routing and translation, so clients interact with a single unified endpoint.

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

At request time, the AI Model mediates traffic between clients and upstream AI Provider APIs:

1. Translates between the request and response format chosen for the AI Model and the upstream AI Provider's native format.
1. Resolves upstream connection coordinates (protocol, host, port, path, HTTP method) from the selected target and its [AI Provider](/ai-gateway/entities/ai-provider/), unless the target is a self-hosted model.
1. Authenticates to the upstream AI Provider using credentials stored on the AI Provider entity.
1. Decorates the upstream request with per-target configuration (such as temperature or token-limit overrides) declared on [`targets[].config`](#schema-aigateway-model-targets).
1. Records usage statistics (tokens, cost, latency) for attached log AI Policies, and optionally the full request and response when payload logging is enabled.
1. Fulfills requests to self-hosted models using the supported native format transformations.

A single AI Model can expose multiple upstream AI Providers behind a consistent client-facing format, so callers don't change their request shape when the underlying AI Provider changes.

## Model lifecycle

When you create or update an AI Model, {{site.ai_gateway}} provisions the necessary runtime resources and applies the configuration atomically. Credentials are sourced from the AI Provider entity that the AI Model's [`targets`](#schema-aigateway-model-targets) reference at model creation time. If you update the AI Provider's credentials later, those changes automatically propagate to all AI Models that use it.

An AI Model is a managed entity—{{site.ai_gateway}} owns its runtime configuration. Direct modifications through other APIs are not supported. To change an AI Model's configuration, update the AI Model entity directly.

## Capabilities

When you expose an AI Model, you choose which AI capabilities it provides through the [`capabilities`](#schema-aigateway-model-capabilities) field. The [`type`](#schema-aigateway-model-type) you select determines which capabilities are available:

* **`model` type**: for synchronous request/response workloads. Available capabilities: `generate`, `agentic`, `embeddings`, `audio/speech`, `audio/transcription`, `audio/translation`, `image`, `video`, `realtime`, `rerank`.
* **`api` type**: for asynchronous batch processing. Available capabilities: `batches`, `files`.

Not every AI Provider supports every capability. The set of capabilities you can declare on an AI Model depends on what the AI Provider in [`targets`](#schema-aigateway-model-targets) exposes. See [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for per-provider details.

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

By default, AI Models expose all endpoints using OpenAI-compatible format. {{site.ai_gateway}} provides a single, standardized interface across all providers, so you can swap providers (OpenAI, Anthropic, self-hosted, etc.) without changing client code or integration logic.

The [`formats`](#schema-aigateway-model-formats) array lets you control the request and response format. Each entry has a `type` that selects the format. The default `openai` format translates upstream provider responses into the OpenAI shape, so clients use one API format regardless of provider.

If you need the provider's native format instead, set [`formats[].type`](#schema-aigateway-model-formats-type) to a non-OpenAI value. The Model passes requests upstream without conversion, while {{site.ai_gateway}} continues to provide analytics, logging, and cost calculation. You can also customize the endpoint paths through [`config.route.paths`](#schema-aigateway-model-config-route-paths) if needed.

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

## Targets

An AI Model is a virtual model: it exposes one route ([`config.route`](#schema-aigateway-model-config-route)) and one set of capabilities, and routes requests to one or more concrete upstream models declared in its [`targets`](#schema-aigateway-model-targets) array. Each entry represents a single upstream model instance with one URL.

For each target, you provide the upstream model name (for example, `gpt-4o`) and reference the Provider to use by its `name`. Each target can also override settings such as [`temperature`](#schema-aigateway-target-config-temperature), [`max_tokens`](#schema-aigateway-target-config-max-tokens), [`input_cost`](#schema-aigateway-target-config-input-cost), and [`output_cost`](#schema-aigateway-target-config-output-cost).

There's no separate Target entity or endpoint. Targets are managed only as nested data inside an AI Model, through the same AI Model API surface used to create, update, and delete the parent. Adding, removing, or modifying a target is an update to the AI Model itself.

## Load balancing

An AI Model routes to a single target by default. You can add more than one target when you want redundancy, fallback between providers, or cost and latency optimization. When you have multiple targets, configure [`config.balancer`](#schema-aigateway-model-config-balancer) to distribute requests according to a load balancing algorithm.

When an AI Model has more than one target, the [load balancer](#schema-aigateway-model-config-balancer) sits between the virtual model and its targets, distributing requests according to `config.balancer`. For algorithm details, selection guidance, and tuning, see [Load balancing](/ai-gateway/load-balancing/).

### Algorithms

The [`algorithm`](#schema-aigateway-model-config-balancer-algorithm) field lets you choose how to distribute requests across target models based on your priorities. Select a strategy to optimize for cost, latency, even distribution, intelligent routing, or failover behavior.

{:.info}
> For detailed behavior, tuning guidance, and examples for each algorithm, see [Load balancing](/ai-gateway/load-balancing/).

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

To add redundancy and failover, the load balancer supports configurable retries, timeouts, and failover to different targets when one is unavailable. Fallback works across targets with any supported format, so you can mix providers freely (for example, OpenAI and Mistral). For configuration details, see [Retry and fallback configuration](/ai-gateway/load-balancing/#retry-and-fallback).

{:.info}
> Client errors don't trigger failover. To fail over on additional error types, set
> [`failover_criteria`](#schema-aigateway-model-config-balancer-failover-criteria) to include HTTP codes
> like `http_429` or `http_502`, and `non_idempotent` for POST requests.

### Health check and circuit breaker

To improve reliability under sustained failures, the load balancer includes a circuit breaker that When a target reaches the failure threshold set by [`max_fails`](#schema-aigateway-model-config-balancer-max-fails), the load balancer stops routing requests to it until the [`fail_timeout`](#schema-aigateway-model-config-balancer-fail-timeout) period elapses. For behavior examples and tuning, see [Circuit breaker](/ai-gateway/load-balancing/#health-check-and-circuit-breaker).

### Vector store

To route requests based on semantic similarity and keep similar requests on the same model instance, you can use a vector store. This is useful for caching consistency, routing to specialized model variants, or matching requests against historical patterns.

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

Configure an embedding model to enable semantic routing. This lets {{site.ai_gateway}} route requests based on meaning and content similarity rather than just cost or latency. For example, route domain-specific queries to specialized providers or keep similar requests on the same provider for consistency.

Set [`config.balancer.embeddings`](#schema-aigateway-model-config-balancer-embeddings) to reference a Provider and embedding model name. Supported provider types: `azure`, `bedrock`, `gemini`, `huggingface`. The embedding model also powers the `semantic` load balancing algorithm.

## Templating

The AI Model resolves runtime values from request data using placeholder substitution. This lets you select the target model dynamically per request, route to per-deployment Azure endpoints, or fan out to multiple providers from a single AI Model.

Substitution applies to the [`name`](#schema-aigateway-model-target-models-name) of each target model and to any per-target [`config`](#schema-aigateway-model-target-models-config) option. Three placeholders are available:

* `$(headers.header_name)`: the value of a request header.
* `$(uri_captures.path_parameter_name)`: the value of a captured URI path parameter.
* `$(query_params.query_parameter_name)`: the value of a query string parameter.

For examples of using templating, consult the {{site.ai_gateway}} documentation and API reference.

## Model aliasing

By default, applications or services making requests to the AI Model endpoint must specify the actual upstream model name (like `gpt-4o`) in the `model` field. If you want to allow them to use a different name—for abstraction, stability, or to hide implementation details—set [`config.model.alias`](#schema-aigateway-model-config-model-alias).

When an alias is set, clients can send that alias in the request `model` field instead of the upstream model name. This is useful when you want to decouple your client API from upstream provider changes. For example, you could expose an alias like `production-chat-model` while swapping the underlying upstream model from `gpt-4o` to `claude-3-sonnet` without your clients noticing.

## Access control

When you need to limit which teams or applications can call an AI Model—for example, restricting an expensive model to your internal team or blocking access to sensitive models—use the [`acls`](#schema-aigateway-model-acls) field to set either an allow list or a deny list (choose one). Reference [AI Consumers](/ai-gateway/entities/ai-consumer/) (individual applications), [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) (teams), or Authenticated Groups (all consumers authenticated via a specific OAuth2 scope or claim) by name. To control *how* consumers authenticate (API keys, OAuth2, etc.) rather than *who* can access, attach an authentication AI Policy to the model.

## Attach Policies

Attach an AI Policy to an AI Model to add security, observability, governance, rate limiting, and cost optimization to all requests through that model. For example, you can add guardrails ([AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/), [AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/)), enable [logging and metrics](/ai-gateway/policies/?category=logging), audit and [compliance controls](/ai-gateway/policies/ai-sanitizer/), cache responses, or [rate-limit](/ai-gateway/policies/ai-rate-limiting-advanced/) LLM traffic.

Reference AI Policies through the [`policies`](#schema-aigateway-model-policies) field, which accepts AI Policy names or IDs. You can attach multiple AI Policies to a single AI Model; each applies independently, and the same AI Policy type can be attached with different configurations. Not every AI Policy type supports Model attachment. AI Policies are not deleted when the Model is deleted—only the Model's reference is removed. For more details, see [AI Policy entity](/ai-gateway/entities/ai-policy/).

### AI Policy execution order

An AI Policy attached to an AI Model runs on the service of the Model's derived primitives. That AI Policy runs at the [priority](/gateway/entities/plugin/#plugin-priority) determined by its type, which affects when it executes relative to other AI Policies on the request.

Model routing executes at a specific point in the request pipeline. AI Policies have different priorities that determine when they run.  Higher priority AI Policy types may run before the Model routing is resolved. Authentication AI Policies (such as OpenID Connect) fall into this category. They gate access correctly because routing to the Model's generated Service already occurred, but model-level identity details (provider and target model) are not available until after Model resolution.

For AI Policies whose behavior depends on the resolved Model identity, use AI Policy types that run at or after Model resolution, or use [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering) to adjust execution order as needed.

## Upstream proxy configuration

When your data plane sits behind a corporate firewall or security boundary, configure a forward proxy to route all outbound AI provider requests through your organization's proxy. This is required when direct internet access is restricted and all external traffic must pass through a bastion host or inspection gateway.

Use the [`config.proxy`](#schema-aigateway-model-config-proxy) object to specify the proxy endpoint with [`http_proxy`](#schema-aigateway-model-config-proxy-http-proxy) or [`https_proxy`](#schema-aigateway-model-config-proxy-https-proxy), and optionally add [`auth`](#schema-aigateway-model-config-proxy-auth) credentials if the proxy requires authentication. Use [`no_proxy`](#schema-aigateway-model-config-proxy-no-proxy) to bypass the proxy for specific hosts that are already inside your trusted network.

## Logging and observability

Enable [`statistics`](#schema-aigateway-model-config-logging-statistics) logging to track token consumption, request latency, and per-provider costs. This data flows into {{site.konnect_short_name}} analytics and any attached logging policies, letting you monitor API spend, identify slow providers, and audit which AI Models drive the most usage.

Optionally enable [`payloads`](#schema-aigateway-model-config-logging-payloads) to capture full request and response bodies (truncated at [`max_payload_size`](#schema-aigateway-model-config-logging-max-payload_size) bytes, default 1 MB). This is useful for debugging model responses, auditing sensitive operations, or replaying requests.

{:.warning}
> Payload logging may expose sensitive data in your logging destination. Only enable when your logging pipeline is prepared to handle request and response bodies, and verify that logging destinations comply with your data residency and privacy policies.

For response streaming behavior, see [Streaming](/ai-gateway/streaming/).

## Set up a Model

The following example creates an OpenAI Model that exposes the `generate` capability, routed through a single OpenAI Provider, with token usage logging enabled.

{:.info}
> This model proxies client requests to `/ai/chat/completions`. The base path `/ai` comes from [`config.route.paths`](#schema-aigateway-model-config-route-paths), and `/chat/completions` is appended by the `generate` capability automatically.

{% entity_example %}
type: model
data:
  display_name: GPT-4o Production
  name: gpt-4o-production
  type: model
  capabilities:
    - generate
  formats:
    - type: openai
  acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  targets:
    - name: gpt-4o
      provider: my-openai-account
      weight: 100
      config:
        type: openai
        temperature: 0.7
        max_tokens: 4096
        input_cost: 0.0000025
        output_cost: 0.000010
  config:
    route:
      paths:
        - /ai
    logging:
      statistics: true
      payloads: false
    model:
      name_header: true
    balancer:
      algorithm: round-robin
{% endentity_example %}

## Schema

{% entity_schema %}
