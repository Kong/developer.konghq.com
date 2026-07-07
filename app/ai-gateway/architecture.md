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

* **Control plane (fully managed by {{site.konnect_short_name}}, Kong's cloud platform)**: provides a centralized UI and API to configure AI entities (AI Providers, AI Models, AI Agents, AI MCP Servers, AI Policies, AI Consumers, and more), and distributes that configuration — along with the mutual TLS (mTLS) certificates data plane nodes use to authenticate — to registered nodes. As in {{site.base_gateway}} hybrid mode, the control plane is never in the data path: by default it doesn't see the LLM, Model Context Protocol (MCP), or Agent-to-Agent (A2A) request/response payloads flowing through the data plane. See [Node registration and synchronization](#node-registration-and-synchronization) for the opt-in settings that can forward payload content to {{site.konnect_short_name}}.

* **Data plane (self-managed)**: proxy nodes running in your own infrastructure that intercept AI traffic (LLM requests, MCP traffic, and A2A communication), evaluate it against policies distributed from the control plane, and proxy allowed traffic to upstream services.

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

subgraph Customer["Self-managed<br/>(on-prem or cloud)"]
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

**Figure 1**: **Solid arrows** are **user data traffic** — LLM, MCP, and A2A requests flowing through the data plane to upstream services. **Dashed arrows** are **control-plane** traffic — configuration and certificates pulled from {{site.konnect_short_name}}, and telemetry streamed back to it. The control plane never sits in the path of user data traffic.

### AI Gateway and Data Plane Node

An **{{site.ai_gateway}} instance** is the top-level resource you create in {{site.konnect_short_name}} to hold a set of AI entities. Each proxy running in the data plane is a data plane node: a {{site.base_gateway}} (Kong's general-purpose API gateway) runtime instance running in AI Gateway mode, registered to exactly one {{site.ai_gateway}} instance to receive its configuration (see [Multi-tenancy and isolation](#multi-tenancy-and-isolation)). See [Node registration and synchronization](#node-registration-and-synchronization) for how nodes authenticate, stay in sync, and report telemetry.

## {{site.ai_gateway}} entities

The {{site.ai_gateway}} control plane is organized around a set of entities, each with a specific role. All entities are scoped to a single {{site.ai_gateway}} instance, which stores configuration metadata and endpoints for data plane nodes to connect to. An organization can run multiple {{site.ai_gateway}} instances for per-team, per-environment, or per-region isolation. The {{site.ai_gateway}} instance itself and its data plane nodes — introduced above — describe deployment topology rather than a configurable resource, so they aren't listed as rows below. AI Vault and AI Data Plane Certificate expose {{site.base_gateway}}'s existing vault-reference and hybrid-mode client-certificate mechanisms, scoped to an {{site.ai_gateway}} instance, rather than new underlying credential types.

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
      Stores upstream LLM service credentials and endpoint configuration (OpenAI, Anthropic, Bedrock, etc.). Does not generate runtime primitives on its own; becomes actionable only when an AI Model references it.
    references: |
      TBA
  - entity: "[AI Model](/ai-gateway/entities/ai-model/)"
    description: |
      Declares which upstream AI Providers to route to and which capabilities to expose — chat completions, embeddings, image, audio, video, and realtime. Handles load balancing, retry logic, and format conversion, and emits the usage and cost telemetry that attached AI Policy logging plugins consume. The primary entry point for AI traffic.
    references: |
      TBA
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    description: |
      Exposes upstream agent endpoints with optional Agent-to-Agent (A2A) protocol awareness and telemetry. Can be typed as `a2a` (protocol-aware) or `http` (generic proxy).
    references: |
      TBA
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    description: |
      Exposes an MCP endpoint. Its `type` field selects one of several modes, which broadly cover converting REST APIs into MCP tools, proxying an upstream MCP server, or aggregating tools from multiple REST and MCP sources into a single endpoint. Each AI MCP Server operates in one mode at a time.
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

- **MCP traffic**: Model Context Protocol requests from MCP clients. AI MCP Servers act as MCP endpoints — proxying an upstream MCP server's full protocol, converting REST APIs into MCP tools, or aggregating tools from multiple sources into one endpoint — with session management and tool-level access control.

- **A2A traffic**: Agent-to-Agent protocol traffic between AI Agents. AI Agents act as proxies with optional A2A protocol awareness, emitting structured telemetry tied to A2A semantics (tasks, messages, agents).

All three traffic types flow through the same data plane infrastructure and benefit from the same authentication, observability, and policy systems.

## Configuration materialization

When you create an AI entity in {{site.konnect_short_name}}, the control plane translates it into standard {{site.base_gateway}} primitives — Routes, Services, and Plugins (such as `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy`) — and Consumers, before distributing the configuration to data planes. Data planes execute AI traffic through this same Route/Service/Plugin model used for all {{site.base_gateway}} traffic; there's no separate AI-native runtime engine on the data plane.

## Endpoint mapping and routing

AI Model endpoints are exposed as ordinary {{site.base_gateway}} Routes with the AI Proxy Advanced plugin attached, which translates the incoming request into the target provider's format and back. Each configured target carries its own provider credentials — a static API key, AWS SigV4, Azure managed identity, or a GCP service account — which the data plane injects or signs automatically on the upstream call.

When multiple targets are configured for a model, the data plane distributes traffic using one of seven load-balancing strategies: `round-robin` (the default), `consistent-hashing`, `least-connections`, `lowest-latency`, `lowest-usage` (by token count or cost), `semantic` (route by prompt similarity), and `priority` (weighted, ordered failover). On an upstream error or timeout, the data plane retries and fails over to another target by default; an optional passive circuit breaker (`max_fails` and `fail_timeout`, off by default) ejects a repeatedly failing target across requests. There are no active health probes. Connections to upstream providers are reused by default, with reuse disabled when traffic is routed through a configured forward proxy. See [Load balancing](/ai-gateway/load-balancing/) for strategy details and tunables.

## Node registration and synchronization

Data plane nodes authenticate to the control plane using **AI Data Plane Certificates** — the same mTLS client-certificate mechanism used by {{site.base_gateway}} hybrid-mode data planes. When a node starts, it presents its certificate, registers itself, and pulls the latest configuration.

Configuration changes are push-triggered: the control plane notifies connected nodes as soon as a change is available, and each node pulls the updated configuration (tracked by a `config_hash`). Nodes and the control plane also exchange the same 30-second keepalive ping used by {{site.base_gateway}} hybrid mode, confirming the connection is alive. If the control plane doesn't hear from a node for 45 seconds (1.5× the ping interval), it marks the node disconnected; on connection loss, a node retries with a randomized 5-10 second backoff. {{site.ai_gateway}} doesn't currently support gradual or canary configuration rollout — nodes apply a configuration change as soon as they receive it.

Data plane nodes also stream telemetry (analytics, logs, health) back to {{site.konnect_short_name}}, powering {{site.konnect_short_name}} Analytics (Explorer and Dashboards) and attached logging policies. By default, this telemetry doesn't include LLM, MCP, or A2A request/response bodies — only usage, cost, and latency metadata. Two opt-in settings change that: `log_payloads` on the AI Proxy Advanced, AI MCP Proxy, and AI A2A Proxy plugins forwards full request/response bodies to the log serializer that attached logging policies (including {{site.konnect_short_name}}-bound ones) read; `log_blocked_content` on AI Policy guardrails forwards only the specific content that triggered a block. Both are off by default.

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

This enables per-team, per-environment, or per-region isolation without complex RBAC.

## Isolation from {{site.base_gateway}}

An {{site.ai_gateway}} instance has its own entity namespace, data plane pool, credentials, and analytics. It does not share configuration with {{site.base_gateway}} nodes or classic {{site.base_gateway}} consumers and plugins. {{site.ai_gateway}} and {{site.base_gateway}} can run in the same {{site.konnect_short_name}} organization without interference.

{{site.ai_gateway}} and {{site.base_gateway}} can't share a {{site.konnect_short_name}} Workspace: a Workspace subdivides a single {{site.base_gateway}} control plane, so {{site.ai_gateway}} instances can't participate. Isolation between the two happens one level up, at the control-plane boundary — each is its own top-level resource.

## Deployment topologies

{{site.ai_gateway}} runs in a single deployment mode: **hybrid**, with a {{site.konnect_short_name}}-managed control plane and self-managed data plane nodes. It is Konnect-first: configuration always originates in the {{site.konnect_short_name}} control plane, so self-managed traditional (database-backed) or standalone DB-less deployment isn't currently supported. Data plane nodes run in your own infrastructure and are configured from {{site.konnect_short_name}}, which they must be able to reach — there's no offline or fully self-hosted control plane option.

{% table %}
columns:
  - title: Characteristic
    key: characteristic
  - title: Hybrid mode
    key: hybrid
rows:
  - characteristic: Control plane
    hybrid: |
      Fully managed by Kong in {{site.konnect_short_name}}. Stores all AI entities and distributes configuration.
  - characteristic: Data plane
    hybrid: |
      Self-managed nodes running in your infrastructure (on-premises or your own cloud). No local database.
  - characteristic: Configuration
    hybrid: |
      Nodes authenticate with an AI Data Plane Certificate (mTLS) and pull configuration from the control plane, syncing on `config_hash`.
  - characteristic: Control plane outage
    hybrid: |
      Data plane nodes keep proxying traffic using their last known configuration. Only configuration updates pause until the connection is restored.
{% endtable %}

### Node topologies

Within hybrid mode, size the data plane to your traffic and availability needs:

- **Single node**: one data plane node per environment. Suitable for development, testing, or low-volume workloads.
- **Multi-node pool**: multiple stateless data plane nodes behind a load balancer, all pulling the same configuration from one {{site.ai_gateway}} instance. Nodes run active-active with no leader, so you scale out and handle failover by adding or removing nodes. Run pools across availability zones or regions for locality and resilience.

Each {{site.ai_gateway}} instance has its own data plane pool (see [Multi-tenancy and isolation](#multi-tenancy-and-isolation)): a node registers with a single {{site.ai_gateway}} instance and pulls configuration from only that instance.

For the underlying hybrid-mode mechanics, certificate management, and disaster-recovery guidance shared with {{site.base_gateway}}, see [Kong Gateway deployment topologies](/gateway/deployment-topologies/).
