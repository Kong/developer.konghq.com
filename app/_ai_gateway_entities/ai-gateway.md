---
title: AI Gateways
content_type: reference
entities:
  - ai-gateway
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: The top-level {{site.ai_gateway}} entity that owns Models, Providers, Policies, Agents, MCP Servers, and other AI-specific entities.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGateway
works_on:
  - konnect
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Provider entity
    url: /ai-gateway/entities/provider/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: Data Plane Certificate entity
    url: /ai-gateway/entities/data-plane-certificate/
faqs:
  - q: How is an AI Gateway different from a {{site.konnect_short_name}} Gateway control plane?
    a: |
      An AI Gateway is a dedicated control plane purpose-built for AI traffic. It exposes its own
      entity surface (Models, Providers, Policies, Agents, MCP Servers, and so on) and its own
      data plane runtime. It doesn't share entities or data planes with a regular
      {{site.konnect_short_name}} Gateway control plane.

  - q: Can I run more than one AI Gateway in an organization?
    a: |
      Yes. An organization can hold multiple AI Gateway entities. Each one has its own
      configuration and telemetry endpoints, its own set of child entities, and its own
      data planes.

  - q: What does `config_hash` represent?
    a: |
      `config_hash` is a hash of the AI Gateway's latest configuration, including all of its
      child entities. It changes any time something under the AI Gateway is created, updated,
      or deleted. Compare it to the `config_hash` reported by a data plane node to check whether
      the node has the current configuration.

  - q: What happens to child entities when I delete an AI Gateway?
    a: |
      Deleting an AI Gateway removes the entity. Its child entities (Models, Providers, Policies,
      Agents, MCP Servers, Vaults, Consumers, Consumer Groups, and Data Plane Certificates) are
      tied to the AI Gateway and are not addressable without it.

  - q: Is the AI Gateway entity available on-prem?
    a: |
      No. The AI Gateway entity is a {{site.konnect_short_name}} concept. On-prem deployments
      manage the same child entities (Models, Providers, Policies, and so on) directly through
      the Admin API, without a parent `ai-gateways/{id}` container.
---

## What is an AI Gateway?

An AI Gateway is the top-level {{site.ai_gateway}} entity. It's a dedicated control plane for AI traffic — separate from a regular {{site.konnect_short_name}} Gateway control plane — that owns the entities {{site.ai_gateway}} uses to serve LLM and agent workloads:

1. [Models](/ai-gateway/entities/model/) — AI model endpoints, capabilities, and load balancing.
1. [Providers](/ai-gateway/entities/provider/) — upstream LLM service connections and credentials.
1. [Policies](/ai-gateway/entities/policy/) — security, rate limiting, and guardrail behavior attached to other entities.
1. [Agents](/ai-gateway/entities/agent/) — A2A and HTTP agent routing.
1. [MCP Servers](/ai-gateway/entities/mcp-server/) — MCP tool exposure and session handling.
1. [Vaults](/ai-gateway/entities/vault/) — secret storage referenced from other entities.
1. [Consumers](/ai-gateway/entities/consumer/), [Consumer Groups](/ai-gateway/entities/consumer-group/), [Consumer Credentials](/ai-gateway/entities/consumer-credential/) — identities used in access control.
1. [Data Plane Certificates](/ai-gateway/entities/data-plane-certificate/) — certificates that authorize data plane nodes to connect.

Every other {{site.ai_gateway}} entity is created under an AI Gateway and addressed through its ID:

{% table %}
columns:
  - title: Surface
    key: surface
  - title: Endpoint
    key: endpoint
rows:
  - surface: AI Gateway
    endpoint: /v1/ai-gateways
  - surface: Child entities
    endpoint: /v1/ai-gateways/{aiGatewayId}/{entity}
{% endtable %}

## Endpoints

When an AI Gateway is created, {{site.ai_gateway}} provisions two endpoints that data planes connect to:

1. **Configuration endpoint** (`endpoints.configuration`) — the URL data plane nodes use to receive their configuration from the control plane.
1. **Telemetry endpoint** (`endpoints.telemetry`) — the URL data plane nodes use to ship analytics and runtime telemetry back to {{site.konnect_short_name}}.

Both endpoints are read-only, assigned at creation time, and stable for the lifetime of the AI Gateway. Data plane nodes need both URLs, along with a [Data Plane Certificate](/ai-gateway/entities/data-plane-certificate/), to register with the AI Gateway.

## Configuration hash

`config_hash` is a read-only field that {{site.ai_gateway}} updates every time anything under the AI Gateway changes — a new Model, an updated Policy, a deleted Provider, and so on. Each data plane node reports back the `config_hash` of the configuration it's running. The two values match when the node is in sync with the control plane.

Use `config_hash` to verify rollout: after a configuration change, watch the node `config_hash` (through [List Nodes](/ai-gateway/entities/data-plane-certificate/) or the {{site.konnect_short_name}} UI) until every node reports the AI Gateway's current value.

## Labels

`labels` is a free-form `key: value` map for organization. Use it to tag AI Gateways by environment (`env: production`), team ownership, cost center, or any other dimension you filter on. Labels don't affect runtime behavior.

## Lifecycle

AI Gateways are created and managed through the {{site.konnect_short_name}} UI. Once an AI Gateway exists, its child entities (Models, Providers, Policies, and so on) are managed through the {{site.ai_gateway}} API, Terraform, or decK as documented on each entity page.

Creating an AI Gateway provisions the configuration and telemetry endpoints and gives you the parent ID needed to create child entities. The AI Gateway has no runtime traffic of its own — traffic flows once at least one Model, Agent, or MCP Server is configured under it and a data plane node is connected.

Updating an AI Gateway changes its `name`, `description`, or `labels`. Endpoints and `config_hash` are managed by {{site.ai_gateway}} and can't be set directly.

Deleting an AI Gateway removes the entity. Its child entities are scoped to the AI Gateway and can't be addressed without it.

## Schema

{% entity_schema %}
