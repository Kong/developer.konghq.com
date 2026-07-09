---
title: "{{site.ai_gateway}} architecture"
content_type: reference
layout: reference
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/architecture/
breadcrumbs:
  - /ai-gateway/
description: |
  Understand the architecture of {{site.ai_gateway}}, including its control plane and data plane, how AI entities translate into data plane configuration, and its deployment and multi-tenancy topologies.
tools:
  - konnect-api
---

## How {{site.ai_gateway}} works

{{site.ai_gateway}} uses a hybrid deployment model, separating the control plane from the data plane.

* **Control plane (fully managed by {{site.konnect_short_name}})**: a centralized UI and API to configure AI entities (AI Providers, AI Models, AI Agents, AI MCP Servers, AI Policies, AI Consumers, and more). It distributes that configuration to registered data plane nodes, along with the mutual TLS (mTLS) certificates those nodes use to authenticate. As in {{site.base_gateway}} hybrid mode, the control plane stays out of the data path: by default it doesn't see the LLM, Model Context Protocol (MCP), or Agent-to-Agent (A2A) payloads passing through the data plane. A few opt-in settings can forward payload content to {{site.konnect_short_name}}. See [Node registration and synchronization](#node-registration-and-synchronization).

* **Data plane (self-managed)**: proxy nodes running in your own infrastructure. They receive AI traffic (LLM requests, MCP traffic, and A2A communication), evaluate it against the policies the control plane distributes, and forward allowed traffic to upstream services. Each node maintains a persistent connection to the control plane to stay in sync with configuration changes.

The following diagram illustrates the high-level architecture:

<!--vale off-->
{% mermaid %}

flowchart LR

subgraph Konnect["{{site.konnect_short_name}} (Kong-managed cloud)"]
  CP["{{site.ai_gateway}}<br/>control plane"]
end

LLMc["LLM client"] -->|chat / embeddings| DP
MCPc["MCP client"] -->|MCP protocol| DP
A2Ac["Agent<br/>A2A client"] -->|A2A protocol| DP

subgraph Customer["Self-managed"]
  DP["{{site.ai_gateway}}<br/>data plane node(s)"]
end

DP -->|LLM request| Provider["AI Provider"]
DP -->|MCP request| MCPs["Upstream MCP server"]
DP -->|A2A request| Agent["Upstream AI agent"]

CP -. "config pull + DP certificates" .-> DP
DP -. "telemetry: analytics, logs, health" .-> CP

style Konnect stroke-dasharray:3
style Customer stroke-dasharray:3

{% endmermaid %}
<!--vale on-->

**Figure 1**: Solid arrows show user data traffic: LLM, MCP, and A2A requests flowing through the data plane to upstream services. Dashed arrows show control-plane traffic: configuration and certificates pulled from {{site.konnect_short_name}}, and telemetry streamed back. The control plane is never in the path of user data traffic.

### {{site.ai_gateway}} and data plane node

An **{{site.ai_gateway}} instance** is the top-level resource you create in {{site.konnect_short_name}} to hold a set of AI entities. A **data plane node** is a single proxy running in your infrastructure. Each node registers to exactly one {{site.ai_gateway}} instance and receives its configuration from it (see [Multi-tenancy and isolation](#multi-tenancy-and-isolation)). For how nodes authenticate, stay in sync, and report telemetry, see [Node registration and synchronization](#node-registration-and-synchronization).

## {{site.ai_gateway}} entities

Each entity has a specific role and is scoped to a single {{site.ai_gateway}} instance. Two of them reuse existing {{site.base_gateway}} mechanisms rather than introducing new credential types: AI Vault wraps {{site.base_gateway}}'s vault references, and AI Data Plane Certificate wraps its hybrid-mode client certificates. The following table describes them:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
  - title: References
    key: references
rows:
  - entity: "[AI Provider](/ai-gateway/entities/ai-provider/)"
    description: |
      Stores the credentials and endpoint configuration for an upstream LLM service (OpenAI, Anthropic, Bedrock, etc.). It has no effect on its own and produces no data plane configuration until an AI Model references it.
    references: |
      [Schema](/ai-gateway/entities/ai-provider/#schema)
  - entity: "[AI Model](/ai-gateway/entities/ai-model/)"
    description: |
      The primary entry point for AI traffic. Declares which upstream AI Providers to route to and which capabilities to expose (such as chat completions, embeddings, and image, audio, video, and realtime generation). Handles load balancing, retries, and format conversion, and emits the usage and cost telemetry that attached logging policies record.
    references: |
      [Schema](/ai-gateway/entities/ai-model/#schema)
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    description: |
      Exposes upstream agent endpoints with optional Agent-to-Agent (A2A) protocol awareness and telemetry. Can be typed as `a2a` (protocol-aware) or `http` (generic proxy).
    references: |
      [Schema](/ai-gateway/entities/ai-agent/#schema)
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    description: |
      Exposes an MCP endpoint. It can convert REST APIs into MCP tools, proxy an upstream MCP server, or aggregate tools from multiple REST and MCP sources into a single endpoint. Each AI MCP Server does one of these at a time.
    references: |
      [Schema](/ai-gateway/entities/ai-mcp-server/#schema)
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    description: |
      Applies governance, security, transformation, and observability behavior (rate limiting, sanitization, authentication, logging) to Models, Agents, MCP Servers, Consumers, Consumer Groups, or globally. Each policy is independent.
    references: |
      [Schema](/ai-gateway/entities/ai-policy/#schema)
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    description: |
      Represents a downstream client identity for authentication and access control. Holds an API key credential, can be assigned to AI Consumer Groups, and can have policies attached. OAuth-based authentication is enforced through an AI Policy (such as OpenID Connect) rather than stored as a credential on the consumer.
    references: |
      [Schema](/ai-gateway/entities/ai-consumer/#schema)
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    description: |
      A logical grouping of AI Consumers for bulk policy attachment and ACL management. Used to control access to Models, Agents, and MCP Servers.
    references: |
      [Schema](/ai-gateway/entities/ai-consumer-group/#schema)
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    description: |
      A centralized place to store or reference secrets (API keys, tokens) used by other entities. Aside from the built-in {{site.konnect_short_name}} config store, an AI Vault registers an external secrets backend (AWS, GCP, Azure, HashiCorp Vault, and others) and resolves references at runtime.
    references: |
      [Schema](/ai-gateway/entities/ai-vault/#schema)
  - entity: "[AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/)"
    description: |
      X.509 credentials that authorize data plane nodes to connect to the {{site.ai_gateway}} and pull configuration. Nodes authenticate using these certificates via mTLS.
    references: |
      [Schema](/ai-gateway/entities/ai-data-plane-certificate/#schema)
{% endtable %}

## Three types of traffic

{{site.ai_gateway}} proxies three distinct types of traffic:

- **LLM traffic**: Client requests to [AI Models](/ai-gateway/entities/ai-model/), routed to upstream [AI Providers](/ai-gateway/entities/ai-provider/) (OpenAI, Anthropic, Bedrock, etc.). Supports chat completions and other text generation, embeddings, image generation, audio (speech and transcription), video generation, and realtime streaming. Handles format conversion, credential injection, load balancing, and cost/token tracking.

- **MCP traffic**: Model Context Protocol requests from MCP clients, handled by [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/). Each AI MCP Server operates in one mode: proxying an upstream MCP server, converting REST APIs into MCP tools, or aggregating tools from multiple sources into one endpoint. Includes session management and tool-level access control.

- **A2A traffic**: Agent-to-Agent protocol traffic handled by [AI Agents](/ai-gateway/entities/ai-agent/). AI Agents proxy upstream agent endpoints with optional A2A protocol awareness and emit structured telemetry tied to A2A semantics (tasks, messages, agents).

All three flow through the same data plane and use the same authentication, observability, and policy features.

## How entities become {{site.base_gateway}} configuration

AI entities are a high-level abstraction. When you save one, a dedicated conversion step lowers it into the same {{site.base_gateway}} building blocks classic {{site.base_gateway}} uses (Routes, Services, Plugins, Consumers), and that's what data plane nodes actually run.

The mapping isn't uniform. Some entities carry over almost directly: an AI Vault becomes a Kong Vault, and an AI Consumer or AI Consumer Group becomes a Kong Consumer or Consumer Group with its credentials and group membership. An AI Model fans out further: it becomes a Service, one or more Routes, and plugins such as `ai-model-selector` and `ai-proxy-advanced`. An AI Provider has no object of its own. It's folded into the `ai-proxy-advanced` target of every AI Model that references it. AI Policy is the most dynamic case: its `type` becomes the name of whichever {{site.base_gateway}} plugin implements it (for example `ai-prompt-guard` or `ai-rate-limiting-advanced`), applied globally or scoped to whatever the policy is attached to.

### Example: an AI Model becomes {{site.base_gateway}} configuration

An AI Model named `gpt-5-2` with one target routes to an AI Provider `openai-prod`:

```yaml
# AI entities, as configured in {{site.konnect_short_name}}
models:
  - name: gpt-5-2
    capabilities: [generate]
    formats: [{ type: openai }]
    config:
      route: { paths: [/ai] }
      model: { alias: "@openai/gpt-5.2" }
    targets:
      - name: gpt-5.2
        provider: openai-prod
        config: { type: openai, temperature: 1.0, max_tokens: 1024 }
providers:
  - name: openai-prod
    type: openai
    config:
      auth: { type: basic, headers: [{ name: Authorization, value: "{vault://ai/openai-token}" }] }
```

become these {{site.base_gateway}} objects on the data plane:

```yaml
services:
  - name: ai-gateway
    routes:
      - name: openai-chat
        paths: [/ai/chat/completions]
        methods: [POST]
plugins:
  - name: ai-model-selector
    route: { name: openai-chat }
    config: { source: body, body_path: model }
  - name: ai-proxy-advanced
    route: { name: openai-chat }
    model: { name: gpt-5-2 }
    config:
      llm_format: openai
      balancer: { algorithm: round-robin }
      targets:
        - model: { name: gpt-5.2, model_alias: "@openai/gpt-5.2", provider: openai,
                    options: { temperature: 1, max_tokens: 1024 } }
          auth: { header_name: Authorization, header_value: "{vault://ai/openai-token}" }
ai-models:
  - { name: gpt-5-2, alias: "@openai/gpt-5.2" }
```

The AI Provider has no object of its own. Its auth and type are folded directly into the `ai-proxy-advanced` target.

## Routing and load balancing

A request routes to a provider based on the AI Model it targets and that model's load-balancing strategy, set through `config.balancer.algorithm`: `round-robin` (the default), `consistent-hashing`, `least-connections`, `lowest-latency`, `lowest-usage` (by token count or cost), `semantic` (route by prompt similarity), or `priority` (weighted, ordered failover). Each provider target carries its own credentials: a static API key, AWS SigV4, Azure managed identity, or a GCP service account. The data plane applies these automatically on the upstream call.

On an upstream error or timeout, the data plane retries (5 times by default) and fails over to another target. An optional passive circuit breaker, off by default, can eject a target after repeated failures. There are no active health probes: target health is tracked only from real request outcomes. Connections to upstream providers are reused by default, and reuse is disabled automatically when a forward proxy is configured. See [Load balancing](/ai-gateway/load-balancing/) for strategy details and tuning options.

## Node registration and synchronization

Data plane nodes authenticate to the control plane with an **AI Data Plane Certificate** over mTLS. When a node starts, it presents its certificate, registers, and pulls the latest configuration.

Configuration changes are push-triggered: the control plane notifies connected nodes as soon as a change is available, and each node pulls the update, tracked by a `config_hash`. Nodes and the control plane exchange a 30-second keepalive ping to confirm the connection is alive. If the control plane doesn't hear from a node for 45 seconds (1.5× the ping interval), it marks the node disconnected, and the node reconnects with a randomized 5-10 second backoff. Nodes apply each configuration change as soon as they receive it.

Data plane nodes also stream telemetry (analytics, logs, health) back to {{site.konnect_short_name}}, which powers {{site.konnect_short_name}} Analytics (Explorer and Dashboards) and attached logging policies. By default, this telemetry includes only usage, cost, and latency metadata, not the LLM, MCP, or A2A request and response bodies. Two opt-in settings change that, and both are off by default:

- `log_payloads`, on [AI Models](/ai-gateway/entities/ai-model/), [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), and [AI Agents](/ai-gateway/entities/ai-agent/), includes full request and response bodies in what attached logging policies receive (including {{site.konnect_short_name}}-bound ones).
- `log_blocked_content`, on guardrail [AI Policies](/ai-gateway/entities/ai-policy/), forwards only the specific content that triggered a block.

## Multi-tenancy and isolation

An organization can create multiple {{site.ai_gateway}} instances. Each operates independently:

{% table %}
columns:
  - title: Isolation aspect
    key: aspect
  - title: Behavior
    key: behavior
rows:
  - aspect: Entity scope
    behavior: |
      AI Models, AI Providers, AI Policies created under one {{site.ai_gateway}} instance are not visible to another.
  - aspect: Telemetry
    behavior: |
      Each {{site.ai_gateway}} instance is assigned its own telemetry endpoint. Behind it, a shared {{site.konnect_short_name}} analytics pipeline attributes each record to the instance by the connecting node's authenticated identity.
  - aspect: Data plane pools
    behavior: |
      Data plane nodes register under a single {{site.ai_gateway}} instance and pull configuration from only that instance.
{% endtable %}

This gives you per-team, per-environment, or per-region isolation.

## Isolation from {{site.base_gateway}}

An {{site.ai_gateway}} instance is fully separate from {{site.base_gateway}} control planes: it doesn't share entities, data planes, credentials, consumers, or plugins with them. The two can run in the same {{site.konnect_short_name}} organization without interference.

{{site.ai_gateway}} and {{site.base_gateway}} can't share a {{site.konnect_short_name}} Workspace: a Workspace subdivides a single {{site.base_gateway}} control plane, so {{site.ai_gateway}} instances can't participate. Isolation between the two happens one level up, at the control-plane boundary: each is its own top-level resource in {{site.konnect_short_name}}.

## Deployment topologies

As of {{site.ai_gateway}} 2.0.X, {{site.ai_gateway}} runs in a single deployment mode: **hybrid**, with a {{site.konnect_short_name}}-managed control plane and self-managed data plane nodes. Configuration always originates in the {{site.konnect_short_name}} control plane and is distributed to data plane nodes from there.

{:.info}
> {{site.ai_gateway}} currently requires connectivity to {{site.konnect_short_name}}. There is no self-managed database-backed option, standalone DB-less mode, offline control plane, or fully self-hosted control plane. {{site.base_gateway}} already supports these deployment modes, and {{site.ai_gateway}} may add similar topologies in a future release.

Data plane nodes are stateless and run in your own infrastructure. Size the pool to your traffic and availability needs:

- **Single node**: one node per environment. Suitable for development, testing, or low-volume workloads.
- **Multi-node pool**: multiple nodes behind a load balancer, all serving the same configuration. Nodes run active-active with no leader, so you scale out and handle failover by adding or removing nodes. Run pools across availability zones or regions for locality and resilience.

If the control plane becomes unreachable, data plane nodes keep proxying traffic with their last known configuration. Only configuration updates pause until the connection is restored.

For hybrid-mode mechanics, certificate management, and disaster-recovery guidance shared with {{site.base_gateway}}, see [{{site.base_gateway}} deployment topologies](/gateway/deployment-topologies/).
