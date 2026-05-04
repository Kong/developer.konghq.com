---
title: Policy
content_type: reference
entities:
  - policy
products:
  - ai-gateway
description: "Policies for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayPolicy
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Agent entity
    url: /ai-gateway/entities/agent/
  - text: MCP Server entity
    url: /ai-gateway/entities/mcp-server/
  - text: Plugin entity
    url: /gateway/entities/plugin/
faqs:
  - q: Are Policies shared across multiple entities?
    a: |
      No. Each Policy is an independent instance. To apply the same plugin
      configuration to two Models, create two Policies with matching `config`,
      one per Model.

  - q: How is a Policy different from a plugin?
    a: |
      A Policy is a plugin instance configured through the {{site.ai_gateway}} entity surface
      instead of the classic `/plugins` endpoint. The runtime effect is the same: a plugin attached
      at the appropriate scope. {{site.ai_gateway}} manages the Policy's lifecycle alongside the
      entity it's attached to.

  - q: Can a Policy be scoped to a Consumer or Consumer Group?
    a: |
      Not directly. A Policy attaches to {{site.ai_gateway}} globally or to a Model, Agent,
      or MCP Server. Per-consumer access is expressed through the `acls` field on those parent
      entities, which gates which Consumer Groups can reach the entity in the first place.

  - q: What plugin types can a Policy use?
    a: |
      Set the plugin name in the Policy's `type` field and provide the plugin's configuration
      in the `config` field. Examples include `ai-sanitizer`, `ai-prompt-guard`,
      `ai-prompt-decorator`, `ai-rate-limiting-advanced`, and `openid-connect`. The supported set
      isn't enumerated on this page, refer to the {{site.ai_gateway}} plugin reference for the full list.

  - q: What happens to a Policy when its parent entity is deleted?
    a: |
      Policies attached to a Model, Agent, or MCP Server are removed when the parent entity is
      deleted, along with the rest of that entity's derived primitives. Global policies are
      independent and aren't affected by deletions of other entities.
---

## What is a Policy?

A Policy is a plugin instance registered through the {{site.ai_gateway}} entity surface.

Each Policy declares a `type` (which is a plugin name, for example `ai-sanitizer` or `ai-rate-limiting-advanced`) and a `config` block whose contents follow that plugin's own schema. {{site.ai_gateway}} attaches the configured plugin at the scope you select: globally, or to a specific Model, Agent, or MCP Server.

Policies are not shared. Each Policy is one plugin instance. To apply the same configuration to two parent entities, create two Policies.

Policies are managed through the {{site.ai_gateway}} entity surface in both deployment modes:

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
    endpoint: /v1/ai-gateways/{aiGatewayId}/policies
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/policies
{% endtable %}

<!-- TODO: confirm the Konnect endpoint base path against the public Konnect API spec. The architecture proposal references `/ai-gateways/{id}/policies` as the path segment. -->

## Policy scopes

A Policy is scoped at the time you create it, by the endpoint you POST it to:

* **Global**: `POST /ai/policies` attaches the underlying plugin globally so it runs for every {{site.ai_gateway}} route on the data plane. Non-AI traffic on the same data plane is not affected.
* **Model**: `POST /ai/models/{modelId}/policies` attaches the underlying plugin at the Service of the Model's derived primitives. The plugin runs for requests routed through that Model. See the [Model entity](/ai-gateway/entities/model/).
* **Agent**: `POST /ai/agents/{agentId}/policies` attaches the plugin at the Service of the Agent's derived primitives. See the [Agent entity](/ai-gateway/entities/agent/).
* **MCP Server**: `POST /ai/mcp-servers/{mcpServerId}/policies` attaches the plugin at the Service of the MCP Server's derived primitives. See the [MCP Server entity](/ai-gateway/entities/mcp-server/).

Scope is fixed at creation time. Moving a Policy from one scope to another means deleting it and creating a new one under the target endpoint.

## Lifecycle

Creating a Policy creates exactly one plugin entry in the underlying runtime. Updating a Policy updates that plugin entry. Deleting a Policy deletes that plugin entry. All scopes support standard CRUD operations through the matching path.

The `config` field is passed through to the plugin without translation.

{:.info}
> **Plugin config schemas live with the plugin docs**
>
> {{site.ai_gateway}} does not define plugin configuration schemas under the Policy entity.
> For each plugin you intend to use as a Policy `type`, look up that plugin's reference page for its `config` shape.

## Set up a global Policy

The following example creates a global PII sanitizer Policy that runs for every {{site.ai_gateway}} route.

{% entity_example %}
type: policy
data:
  display_name: PII Sanitizer - Global
  ref: pii-sanitizer-global
  type: ai-sanitizer
  enabled: true
  config:
    anonymize:
      - phone
      - creditcard
    stop_on_error: true
{% endentity_example %}

## Set up a Model-scoped Policy

The following example attaches a rate-limiting Policy to a Model.

{% entity_example %}
type: policy
data:
  display_name: Rate Limit - Production GPT-4o
  ref: rate-limit-prod-gpt4o
  type: ai-rate-limiting-advanced
  enabled: true
  config:
    llm_providers:
      - name: openai
        limit:
          - 30
        window_size:
          - 60
    window_type: sliding
{% endentity_example %}

<!-- TODO: confirm the actual `config` shape for ai-rate-limiting-advanced against the plugin's current schema. -->

## Schema

{% entity_schema %}