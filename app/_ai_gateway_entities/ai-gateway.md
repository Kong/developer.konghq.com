---
title: "{{site.ai_gateway}}"
content_type: reference
entities:
  - ai-gateway
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
permalink: /ai-gateway/entities/ai-gateway/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: |
  The top-level {{site.ai_gateway}} entity that owns Models, Providers, Policies, Agents, MCP Servers, and other AI-specific entities.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGateway
works_on:
  - konnect
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Provider entity
    url: /ai-gateway/entities/ai-provider/
  - text: Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Data Plane Certificate entity
    url: /ai-gateway/entities/ai-data-plane-certificate/
faqs:
  - q: How is an {{site.ai_gateway}} different from a {{site.konnect_short_name}} Gateway control plane?
    a: |
      An {{site.ai_gateway}} is a dedicated control plane purpose-built for AI traffic. It exposes its own
      entity surface (Models, Providers, Policies, Agents, MCP Servers, and so on) and its own
      data plane runtime. It doesn't share entities or data planes with a regular
      {{site.konnect_short_name}} Gateway control plane.

  - q: Can I run more than one {{site.ai_gateway}} in an organization?
    a: |
      Yes. An organization can hold multiple {{site.ai_gateway}} entities. Each one has its own
      configuration and telemetry endpoints, its own set of child entities, and its own
      data planes.

  - q: What does `config_hash` represent?
    a: |
      `config_hash` is a hash of the {{site.ai_gateway}}'s latest configuration, including all of its
      child entities. It changes any time something under the {{site.ai_gateway}} is created, updated,
      or deleted. Compare it to the `config_hash` reported by a data plane node to check whether
      the node has the current configuration.

  - q: What happens to child entities when I delete an {{site.ai_gateway}}?
    a: |
      Deleting an {{site.ai_gateway}} removes the entity. Its child entities (Models, Providers, Policies,
      Agents, MCP Servers, Vaults, Consumers, Consumer Groups, and Data Plane Certificates) are
      tied to the {{site.ai_gateway}} and are not addressable without it.

  - q: Is the {{site.ai_gateway}} entity available on-prem?
    a: |
      No. The {{site.ai_gateway}} entity is a {{site.konnect_short_name}} concept. On-prem deployments
      manage the same child entities (Models, Providers, Policies, and so on) directly through
      the Admin API, without a parent `ai-gateways/{id}` container.
---

## What is an {{site.ai_gateway}}?

An {{site.ai_gateway}} is the top-level {{site.ai_gateway}} entity. It's a dedicated control plane for AI traffic, separate from a regular {{site.konnect_short_name}} Gateway control plane, that owns the entities {{site.ai_gateway}} uses to serve LLM and agent workloads:

1. [Models](/ai-gateway/entities/ai-model/): AI model endpoints, capabilities, and load balancing.
1. [Providers](/ai-gateway/entities/ai-provider/): upstream LLM service connections and credentials.
1. [Policies](/ai-gateway/entities/ai-policy/): security, rate limiting, and guardrail behavior attached to other entities.
1. [Agents](/ai-gateway/entities/ai-agent/): A2A and HTTP agent routing.
1. [MCP Servers](/ai-gateway/entities/ai-mcp-server/): MCP tool exposure and session handling.
1. [Vaults](/ai-gateway/entities/ai-vault/): secret storage referenced from other entities.
1. [Consumers](/ai-gateway/entities/ai-consumer/), [Consumer Groups](/ai-gateway/entities/ai-consumer-group/), [Consumer Credentials](/ai-gateway/entities/ai-consumer-credential/): identities used in access control.
1. [Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/): certificates that authorize data plane nodes to connect.

Every other {{site.ai_gateway}} entity is created under an {{site.ai_gateway}} and addressed through its ID:

{% table %}
columns:
  - title: Surface
    key: surface
  - title: Endpoint
    key: endpoint
rows:
  - surface: {{site.ai_gateway}}
    endpoint: /v1/ai-gateways
  - surface: Child entities
    endpoint: /v1/ai-gateways/{aiGatewayId}/{entity}
{% endtable %}

## Endpoints

When an {{site.ai_gateway}} is created, {{site.ai_gateway}} provisions two endpoints that data planes connect to:

1. **Configuration endpoint** (`endpoints.configuration`): the URL data plane nodes use to receive their configuration from the control plane.
1. **Telemetry endpoint** (`endpoints.telemetry`): the URL data plane nodes use to ship analytics and runtime telemetry back to {{site.konnect_short_name}}.

Both endpoints are read-only, assigned at creation time, and stable for the lifetime of the {{site.ai_gateway}}. Data plane nodes need both URLs, along with a [Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/), to register with the {{site.ai_gateway}}.

## Configuration hash

`config_hash` is a read-only field that {{site.ai_gateway}} updates every time anything under the {{site.ai_gateway}} changes, such as a new Model, an updated Policy, or a deleted Provider. Each data plane node reports back the `config_hash` of the configuration it's running. The two values match when the node is in sync with the control plane.

Use `config_hash` to verify rollout: after a configuration change, watch the node `config_hash` (through [List Nodes](/ai-gateway/entities/ai-data-plane-certificate/) or the {{site.konnect_short_name}} UI) until every node reports the {{site.ai_gateway}}'s current value.

## Labels

`labels` are a free-form `key: value` map for organization. Use them to tag {{site.ai_gateway}}s by environment (`env: production`), team ownership, cost center, or any other dimension you filter on. Labels don't affect runtime behavior.

## Lifecycle

{{site.ai_gateway}}s can be created and managed through the {{site.konnect_short_name}} UI or the {{site.ai_gateway}} API. Once an {{site.ai_gateway}} exists, its child entities (Models, Providers, Policies, and so on) are managed through the {{site.ai_gateway}} API or decK as documented on each entity page.

Creating an {{site.ai_gateway}} provisions the configuration and telemetry endpoints and gives you the parent ID needed to create child entities. The {{site.ai_gateway}} has no runtime traffic of its own. Traffic flows once at least one Model, Agent, or MCP Server is configured under it and a data plane node is connected.

Updating an {{site.ai_gateway}} changes its `name`, `description`, or `labels`. Endpoints and `config_hash` are managed by {{site.ai_gateway}} and can't be set directly.

Deleting an {{site.ai_gateway}} removes the entity. Its child entities are scoped to the {{site.ai_gateway}} and can't be addressed without it.

## Schema

{% entity_schema %}
