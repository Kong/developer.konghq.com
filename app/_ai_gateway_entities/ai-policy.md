---
title: AI Policies
content_type: reference
entities:
  - ai-policy
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-policy/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "AI Policies for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayPolicy
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: Plugin entity
    url: /gateway/entities/plugin/
faqs:
  - q: Are AI Policies shared across multiple entities?
    a: |
      No. Each AI Policy is an independent instance. To apply the same plugin
      configuration to two AI Models, create two AI Policies with matching `config`,
      one per AI Model.

  - q: How is an AI Policy different from a plugin?
    a: |
      An AI Policy is a plugin instance configured through the {{site.ai_gateway}} entity surface
      instead of the classic `/plugins` endpoint. The runtime effect is the same: a plugin attached
      at the appropriate scope. {{site.ai_gateway}} manages the AI Policy's lifecycle alongside the
      entity it's attached to.

  - q: Can an AI Policy be scoped to an AI Consumer or AI Consumer Group?
    a: |
      Yes. Add the AI Policy's `name` or `id` to the AI Consumer's or AI Consumer Group's `policies` array.
      The plugin runs when the AI Consumer is identified during a request, or when a member of the
      AI Consumer Group is identified.

  - q: What plugin types can an AI Policy use?
    a: |
      Set the plugin name in the AI Policy's `type` field and provide the plugin's configuration
      in the `config` field. Examples include `ai-sanitizer`, `ai-prompt-guard`,
      `ai-prompt-decorator`, `ai-rate-limiting-advanced`, and `openid-connect`. The supported set
      isn't enumerated on this page, refer to the {{site.ai_gateway}} plugin reference for the full list.

  - q: What happens to an AI Policy when its parent entity is deleted?
    a: |
      Standalone AI Policies referenced from parent entities through a `policies` array are independent
      and aren't deleted when a referencing parent is deleted. The reference is simply removed.
---

## What is an AI Policy?

An AI Policy is an {{site.ai_gateway}} entity that represents an action, taken by a plugin, that can be attached to an {{site.ai_gateway}} entity.

Each AI Policy declares a `type` (which is a plugin name, for example `ai-sanitizer` or `ai-rate-limiting-advanced`) and a `config` block whose contents follow that plugin's own schema. {{site.ai_gateway}} attaches the configured plugin at the scope you select: globally, or to a specific AI Model, AI Agent, or AI MCP Server.

For the set of plugin types you can use as an AI Policy `type`, see the [AI plugin reference](/plugins/?category=ai).

**AI Policies are not shared.** Each AI Policy is an independent plugin instance tied to its parent entity's lifecycle. To apply identical configuration to two AI Models, create two separate AI Policies with matching `config`. This design ensures that deleting an AI Model deletes only its own AI Policies, not configurations used by other entities.

AI Policies are managed through the {{site.ai_gateway}} entity surface:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/policies
{% endtable %}

## AI Policy scopes

An AI Policy is scoped by where it's referenced from. Each AI Policy is an independent plugin instance attached at exactly one scope. To apply the same configuration in multiple places, create one AI Policy per place.

The available scopes are:

* **Global**: an AI Policy that no parent entity references runs for every {{site.ai_gateway}} route on the data plane. Non-AI traffic on the same data plane isn't affected.
* **AI Model**: referenced from the `policies` array on an [AI Model entity](/ai-gateway/entities/ai-model/). The plugin runs at the Service of the AI Model's derived primitives.
* **AI Agent**: referenced from the `policies` array on an [AI Agent entity](/ai-gateway/entities/ai-agent/). The plugin runs at the Service of the AI Agent's derived primitives.
* **AI MCP Server**: referenced from the `policies` array on an [AI MCP Server entity](/ai-gateway/entities/ai-mcp-server/). The plugin runs at the Service of the AI MCP Server's derived primitives.
* **AI Consumer**: referenced from the `policies` array on an [AI Consumer entity](/ai-gateway/entities/ai-consumer/). The plugin runs when the AI Consumer is identified during a request.
* **AI Consumer Group**: referenced from the `policies` array on an [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/). The plugin runs when a member of the AI Consumer Group is identified during a request.

### Creating AI Policies

All AI Policies are created through a single endpoint at `/v1/ai-gateways/{aiGatewayId}/policies`. Scope is set entirely through the reference-array mechanism above: add the AI Policy's `name` or `id` to the parent entity's `policies` array, or omit the reference for global scope.

## Lifecycle

Creating an AI Policy creates exactly one plugin entry in the underlying runtime. Updating an AI Policy updates that plugin entry. Deleting an AI Policy deletes that plugin entry. All scopes support standard CRUD operations through the matching path.

The `config` field is passed through to the plugin without translation.

{:.info}
> **Plugin config schemas live with the plugin docs**
>
> {{site.ai_gateway}} does not define plugin configuration schemas under the AI Policy entity.
> For each plugin you intend to use as an AI Policy `type`, look up that plugin's reference page for its `config` shape.

## Set up a global AI Policy

The following example creates a global PII sanitizer AI Policy that runs for every {{site.ai_gateway}} route.

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

## Schema

{% entity_schema %}
