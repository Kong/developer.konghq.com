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
  Understand the architecture of {{site.ai_gateway}}, including its control plane and data plane, how AI entities map to {{site.base_gateway}} configuration, and its deployment and multi-tenancy topologies.
tools:
  - konnect-api
---

## How {{site.ai_gateway}} works

{{site.ai_gateway}} uses a hybrid deployment model, separating the control plane from the data plane.

* **Control plane (fully managed by {{site.konnect_short_name}}, Kong's cloud platform)**: a centralized UI and API to configure AI entities (AI Providers, AI Models, AI Agents, AI MCP Servers, AI Policies, AI Consumers, and more). It distributes that configuration to registered data plane nodes, along with the mutual TLS (mTLS) certificates those nodes use to authenticate. As in {{site.base_gateway}} hybrid mode, the control plane stays out of the data path: by default it doesn't see the LLM, Model Context Protocol (MCP), or Agent-to-Agent (A2A) payloads passing through the data plane. A few opt-in settings can forward payload content to {{site.konnect_short_name}} — see [Node registration and synchronization](#node-registration-and-synchronization).

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

**Figure 1**: **Solid arrows** are **user data traffic** — LLM, MCP, and A2A requests flowing through the data plane to upstream services. **Dashed arrows** are **control-plane** traffic — configuration and certificates pulled from {{site.konnect_short_name}}, and telemetry streamed back to it.

### {{site.ai_gateway}} and Data Plane Node

An **{{site.ai_gateway}} instance** is the top-level resource you create in {{site.konnect_short_name}} to hold a set of AI entities. A **data plane node** is a single proxy: a {{site.base_gateway}} (Kong's general-purpose API gateway) instance running in {{site.ai_gateway}} mode. Each node registers to exactly one {{site.ai_gateway}} instance and receives its configuration from it (see [Multi-tenancy and isolation](#multi-tenancy-and-isolation)). For how nodes authenticate, stay in sync, and report telemetry, see [Node registration and synchronization](#node-registration-and-synchronization).

## {{site.ai_gateway}} entities

Each entity has a specific role, and every entity is scoped to a single {{site.ai_gateway}} instance. The following table describes them:

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
      TBA
  - entity: "[AI Model](/ai-gateway/entities/ai-model/)"
    description: |
      The primary entry point for AI traffic. Declares which upstream AI Providers to route to and which capabilities to expose (such as chat completions, embeddings, and image, audio, video, and realtime generation). Handles load balancing, retries, and format conversion, and emits the usage and cost telemetry that attached logging policies record.
    references: |
      TBA
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    description: |
      Exposes upstream agent endpoints with optional Agent-to-Agent (A2A) protocol awareness and telemetry. Can be typed as `a2a` (protocol-aware) or `http` (generic proxy).
    references: |
      TBA
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    description: |
      Exposes an MCP endpoint. It can convert REST APIs into MCP tools, proxy an upstream MCP server, or aggregate tools from multiple REST and MCP sources into a single endpoint. Each AI MCP Server does one of these at a time.
    references: |
      TBA
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    description: |
      Applies governance, security, transformation, and observability behavior (rate limiting, sanitization, authentication, logging) to Models, Agents, MCP Servers, Consumers, Consumer Groups, or globally. Each policy is independent.
    references: |
      TBA
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    description: |
      Represents a downstream client identity for authentication and access control. Holds an API key credential, can be assigned to AI Consumer Groups, and can have policies attached. OAuth-based authentication is enforced through an AI Policy (such as OpenID Connect) rather than stored as a credential on the consumer.
    references: |
      TBA
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    description: |
      A logical grouping of AI Consumers for bulk policy attachment and ACL management. Used to control access to Models, Agents, and MCP Servers.
    references: |
      TBA
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    description: |
      A centralized place to store or reference secrets (API keys, tokens) used by other entities. Aside from the built-in {{site.konnect_short_name}} config store, an AI Vault registers an external secrets backend (AWS, GCP, Azure, HashiCorp Vault, and others) and resolves references at runtime.
    references: |
      TBA
  - entity: "[AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/)"
    description: |
      X.509 credentials that authorize data plane nodes to connect to the {{site.ai_gateway}} and pull configuration. Nodes authenticate using these certificates via mTLS.
    references: |
      TBA
{% endtable %}

## Three types of traffic

{{site.ai_gateway}} proxies three distinct types of traffic:

- **LLM traffic**: Client requests to AI Models — chat completions and other text generation, embeddings, and additional modalities such as image generation, audio (speech and transcription), video generation, and realtime streaming — routed to upstream AI Providers (OpenAI, Anthropic, Bedrock, etc.). Handles format conversion, credential injection, load balancing, and cost/token tracking.

- **MCP traffic**: Model Context Protocol requests from MCP clients. AI MCP Servers act as MCP endpoints — proxying an upstream MCP server, converting REST APIs into MCP tools, or aggregating tools from multiple sources into one endpoint — with session management and tool-level access control.

- **A2A traffic**: Agent-to-Agent protocol traffic between AI Agents. AI Agents act as proxies with optional A2A protocol awareness, emitting structured telemetry tied to A2A semantics (tasks, messages, agents).

All three flow through the same data plane and use the same authentication, observability, and policy features.

## How entities become {{site.base_gateway}} configuration

You configure {{site.ai_gateway}} through AI entities in {{site.konnect_short_name}}; you don't manage the underlying proxy configuration directly. When you save an entity, the control plane compiles it into the configuration your data plane nodes run and distributes it to them. If you already use {{site.base_gateway}}, that configuration is standard Routes, Services, and Plugins (such as `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy`) — {{site.ai_gateway}} builds on the same proxy engine.

## Routing and load balancing

A request routes to a provider based on the AI Model it targets and that model's load-balancing strategy. Each provider target carries its own credentials — a static API key, AWS SigV4, Azure managed identity, or a GCP service account — which the data plane applies automatically on the upstream call.

When a model has multiple targets, the data plane load-balances across them (round-robin by default, plus latency-, usage-, and similarity-based strategies) and automatically routes around failing targets. See [Load balancing](/ai-gateway/load-balancing/) for the full list of strategies and tuning options.

## Node registration and synchronization

Data plane nodes authenticate to the control plane with an **AI Data Plane Certificate** over mTLS. When a node starts, it presents its certificate, registers, and pulls the latest configuration.

Configuration changes are push-triggered: the control plane notifies connected nodes as soon as a change is available, and each node pulls the update, tracked by a `config_hash`. Nodes and the control plane exchange a 30-second keepalive ping to confirm the connection is alive; if the control plane doesn't hear from a node for 45 seconds (1.5× the ping interval), it marks the node disconnected, and the node reconnects with a randomized 5-10 second backoff. Nodes apply each configuration change as soon as they receive it.

Data plane nodes also stream telemetry (analytics, logs, health) back to {{site.konnect_short_name}}, which powers {{site.konnect_short_name}} Analytics (Explorer and Dashboards) and attached logging policies. By default, this telemetry includes only usage, cost, and latency metadata — not the LLM, MCP, or A2A request and response bodies. Two opt-in settings change that, and both are off by default:

- `log_payloads`, on the AI Proxy Advanced, AI MCP Proxy, and AI A2A Proxy plugins, includes full request and response bodies in what attached logging policies receive (including {{site.konnect_short_name}}-bound ones).
- `log_blocked_content`, on AI Policy guardrails, forwards only the specific content that triggered a block.

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

{{site.ai_gateway}} and {{site.base_gateway}} can't share a {{site.konnect_short_name}} Workspace: a Workspace subdivides a single {{site.base_gateway}} control plane, so {{site.ai_gateway}} instances can't participate. Isolation between the two happens one level up, at the control-plane boundary — each is its own top-level resource.

## Deployment topologies

Data plane nodes are stateless and run in your own infrastructure. Size the pool to your traffic and availability needs:

- **Single node**: one node per environment. Suitable for development, testing, or low-volume workloads.
- **Multi-node pool**: multiple nodes behind a load balancer, all serving the same configuration. Nodes run active-active with no leader, so you scale out and handle failover by adding or removing nodes. Run pools across availability zones or regions for locality and resilience.

If the control plane becomes unreachable, data plane nodes keep proxying traffic with their last known configuration; only configuration updates pause until the connection is restored.

For hybrid-mode mechanics, certificate management, and disaster-recovery guidance shared with {{site.base_gateway}}, see [{{site.base_gateway}} deployment topologies](/gateway/deployment-topologies/).
