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
  Understand how {{site.ai_gateway}} distributes configuration from a {{site.konnect_short_name}} control plane to data plane nodes, and how AI-native concepts become actionable runtime configuration.
tools:
  - konnect-api
---

## How {{site.ai_gateway}} works

{{site.ai_gateway}} uses a XXX deployment model, separating the control plane from the data plane.

* **Control plane ({{site.konnect_short_name}})**: Fully managed by Kong in {{site.konnect_short_name}}, the control plane provides a centralized UI and API to configure AI Models, AI Providers, AI Agents, AI MCP Servers, AI Policies, and AI Consumers. The control plane generates data plane certificates and distributes configuration to registered nodes. It does not process or see the actual LLM, MCP, or A2A message payloads flowing through the data plane.

* **Data plane (self-managed)**: Proxy nodes running in your infrastructure that intercept AI traffic (LLM requests, MCP protocol traffic, and Agent-to-Agent communication), evaluate it against policies from the control plane, and proxy allowed traffic to upstream services. Nodes maintain a persistent connection to the control plane.

Data plane nodes periodically pull configuration updates from the control plane and report their `config_hash` to verify synchronization. Nodes stream telemetry (analytics, logs, health) back to {{site.konnect_short_name}}.

[**PLACEHOLDER**: Diagram showing {{site.konnect_short_name}} control plane, {{site.ai_gateway}} data plane nodes, and three traffic types: LLM client → data plane → AI Provider, MCP client → data plane → MCP server, A2A traffic → data plane → upstream agent]

## {{site.ai_gateway}} entities

The {{site.ai_gateway}} control plane is organized around a set of entities, each with a specific role. All entities are scoped to a single {{site.ai_gateway}} instance, which stores configuration metadata and endpoints for data plane nodes to connect to. An organization can run multiple {{site.ai_gateway}} instances for per-team, per-environment, or per-region isolation.

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
      Declares which upstream AI Providers to route to and which capabilities to expose (generate, embeddings, agentic, etc.). Handles load balancing, retry logic, format conversion, and logging. The primary entry point for LLM traffic.
    references: |
      TBA
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    description: |
      Exposes upstream agent endpoints with optional Agent-to-Agent (A2A) protocol awareness and telemetry. Can be typed as `a2a` (protocol-aware) or `http` (generic proxy).
    references: |
      TBA
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    description: |
      Converts REST APIs into MCP tools, proxies upstream MCP traffic, or aggregates tools from multiple sources.
    references: |
      TBA
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    description: |
      Applies governance, security, transformation, and observability behavior (rate limiting, sanitization, authentication, logging) to Models, Agents, MCP Servers, Consumers, or globally. Each policy is independent.
    references: |
      TBA
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    description: |
      Represents a downstream client identity for authentication and access control. Holds credentials (API key or OAuth) and can be assigned to AI Consumer Groups and have policies attached.
    references: |
      TBA
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    description: |
      A logical grouping of AI Consumers for bulk policy attachment and ACL management. Used to control access to Models, Agents, and MCP Servers.
    references: |
      TBA
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    description: |
      Stores secrets (API keys, tokens, certificates) referenced from other entities. Provides a secure, centralized place for credential management.
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

- **LLM traffic**: Client requests to AI Models (chat completions, embeddings, etc.) routed to upstream AI Providers (OpenAI, Anthropic, Bedrock, etc.). Handles format conversion, credential injection, load balancing, and cost/token tracking.

- **MCP traffic**: Model Context Protocol requests from MCP clients. AI MCP Servers act as MCP endpoints, converting REST APIs into tools or proxying upstream MCP servers. Supports session management, tool filtering, and aggregation.

- **A2A traffic**: Agent-to-Agent protocol traffic between AI Agents. AI Agents act as proxies with optional A2A protocol awareness, emitting structured telemetry tied to A2A semantics (tasks, messages, agents).

All three traffic types flow through the same data plane infrastructure and benefit from the same authentication, observability, and policy systems.

<!-- THIS SECTION IS TBD: CAN WE FRAME IT ANYHOW TO MAKE 100% CLEAR WE ARE KONNECT-FIRST

## Configuration materialization

When you create an AI entity in {{site.konnect_short_name}}, the control plane materializes it into Kong runtime primitives (Routes, Services, Plugins, Consumers) that the data plane executes.

[**PLACEHOLDER**: Description of how AI Models expand into Services + Routes + Plugins, how AI Policies materialize as scoped plugins, how AI Providers inject credentials, and how AI Consumers and AI Consumer Groups map to Kong Consumer primitives] -->

## Endpoint mapping and routing

[**PLACEHOLDER**: How {{site.ai_gateway}} routes requests to models and upstream providers. Address:
- How AI Model paths are exposed on the data plane
- How upstream provider endpoints are resolved and authenticated
- Hostname/port mapping for multi-provider scenarios
- Path rewriting and format conversion
- Load balancing target selection and health checks
- Connection pooling and keep-alive behavior]

## Node registration and synchronization

Data plane nodes authenticate to the control plane using **AI Data Plane Certificates** (X.509 credentials). When a node starts, it presents its certificate, registers itself, and pulls the latest configuration.

Each node stores the `config_hash` reported by the control plane. When the hash changes (because an entity was created, updated, or deleted), nodes download the updated configuration. Nodes compare their local `config_hash` to the {{site.ai_gateway}}'s `config_hash` to verify they're in sync.

Data plane nodes also stream telemetry (analytics, logs, health) back to the control plane's telemetry endpoint, powering {{site.konnect_short_name}} Explorer, Dashboards, and attached logging policies.

[**PLACEHOLDER**: Polling interval, gradual rollout strategy, handling of stale nodes, connection loss recovery]

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
      AI Models, AI Providers, AI Policies created under one AI Gateway are not visible to another.
  - aspect: Audit trails
    behavior: |
      Each AI Gateway tracks its own change history.
  - aspect: Telemetry endpoints
    behavior: |
      Each AI Gateway receives analytics and logs from its own data plane nodes.
  - aspect: Data plane pools
    behavior: |
      Data planes register under a single AI Gateway and pull configuration from only that AI Gateway.
{% endtable %}

This enables per-team, per-environment, or per-region isolation without complex RBAC.

## Isolation from {{site.base_gateway}}

An {{site.ai_gateway}} has its own entity namespace, data plane pool, credentials, and analytics. It does not share configuration with {{site.base_gateway}} nodes or classic Kong Gateway consumers and plugins. {{site.ai_gateway}} and {{site.base_gateway}} can run in the same {{site.konnect_short_name}} workspace without interference.

## Deployment topologies

[**PLACEHOLDER**: Describe common topologies:
- Single node per environment
- Regional multi-node pools (active-active, leader-follower)
- Reference deployment topology guidance for {{site.base_gateway}}, note which patterns apply to {{site.ai_gateway}}
- Failover and disaster recovery strategies]
