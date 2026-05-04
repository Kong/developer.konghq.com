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
      Yes. Add the Policy's `name` or `id` to the Consumer's or Consumer Group's `policies` array.
      The plugin runs when the Consumer is identified during a request, or when a member of the
      Consumer Group is identified.

      Unlike Model, Agent, and MCP Server, on-prem does not expose nested policy endpoints
      (`/ai/consumers/{id}/policies` or `/ai/consumer-groups/{id}/policies`) for these two entity
      types. The reference-array mechanism is the only way to attach a Policy to a Consumer or
      Consumer Group in either deployment mode.

  - q: What plugin types can a Policy use?
    a: |
      Set the plugin name in the Policy's `type` field and provide the plugin's configuration
      in the `config` field. Examples include `ai-sanitizer`, `ai-prompt-guard`,
      `ai-prompt-decorator`, `ai-rate-limiting-advanced`, and `openid-connect`. The supported set
      isn't enumerated on this page, refer to the {{site.ai_gateway}} plugin reference for the full list.

  - q: What happens to a Policy when its parent entity is deleted?
    a: |
      Policies created through an on-prem nested endpoint (`POST /ai/models/{modelId}/policies`,
      `POST /ai/agents/{agentId}/policies`, or `POST /ai/mcp-servers/{mcpServerId}/policies`) are
      lifecycle-coupled to the parent and removed when the parent is deleted, along with the rest
      of that entity's derived primitives.
      Standalone Policies referenced from parent entities through a `policies` array are independent
      and aren't deleted when a referencing parent is deleted. The reference is simply removed.
---

## What is a Policy?

A Policy is an AI Gateway entity that represents an action, taken by a plugin, that can be attached to an AI Gateway entity.

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

## Policy scopes

A Policy is scoped by where it's referenced from. Each Policy is an independent plugin instance attached at exactly one scope. To apply the same configuration in multiple places, create one Policy per place.

The available scopes are:

* **Global**: a Policy that no parent entity references runs for every {{site.ai_gateway}} route on the data plane. Non-AI traffic on the same data plane isn't affected.
* **Model**: referenced from the `policies` array on a [Model entity](/ai-gateway/entities/model/). The plugin runs at the Service of the Model's derived primitives.
* **Agent**: referenced from the `policies` array on an [Agent entity](/ai-gateway/entities/agent/). The plugin runs at the Service of the Agent's derived primitives.
* **MCP Server**: referenced from the `policies` array on an [MCP Server entity](/ai-gateway/entities/mcp-server/). The plugin runs at the Service of the MCP Server's derived primitives.
* **Consumer**: referenced from the `policies` array on a [Consumer entity](/ai-gateway/entities/consumer/). The plugin runs when the Consumer is identified during a request.
* **Consumer Group**: referenced from the `policies` array on a [Consumer Group entity](/ai-gateway/entities/consumer-group/). The plugin runs when a member of the Consumer Group is identified during a request.

### Creating Policies

In {{site.konnect_short_name}}, all Policies are created through a single endpoint at `/v1/ai-gateways/{aiGatewayId}/policies`. Scope is set entirely through the reference-array mechanism above: add the Policy's `name` or `id` to the parent entity's `policies` array, or leave it unreferenced for global scope.

In on-prem, the same flat creation endpoint is available at `/ai/policies`. On-prem additionally exposes convenience nested endpoints that create and scope a Policy in one call:

* `POST /ai/models/{modelId}/policies`
* `POST /ai/agents/{agentId}/policies`
* `POST /ai/mcp-servers/{mcpServerId}/policies`

Consumer and Consumer Group scoping uses the reference-array mechanism in both deployment modes.

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
  name: pii-sanitizer-global
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
  name: rate-limit-prod-gpt4o
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