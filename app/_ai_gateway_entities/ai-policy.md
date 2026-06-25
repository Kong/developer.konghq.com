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

faqs:
  - q: Are AI Policies shared across multiple entities?
    a: |
      No. Each AI Policy is an independent configuration. To apply the same
      configuration to two AI Models, create two AI Policies with matching `config`,
      one per AI Model.

  - q: How is an AI Policy different from a plugin?
    a: |
      An AI Policy is a policy configuration created through the {{site.ai_gateway}} entity surface
      instead of the classic `/plugins` endpoint. The runtime effect is the same: a policy attached
      at the appropriate scope. {{site.ai_gateway}} manages the AI Policy's lifecycle alongside the
      entity it's attached to.

  - q: Can an AI Policy be scoped to an AI Consumer or AI Consumer Group?
    a: |
      Yes. Add the AI Policy's `name` or `id` to the AI Consumer's or AI Consumer Group's `policies` array.
      The Policy runs when the AI Consumer is identified during a request, or when a member of the
      AI Consumer Group is identified.

  - q: What happens to an AI Policy when its parent entity is deleted?
    a: |
      Standalone AI Policies referenced from parent entities through a `policies` array are independent
      and aren't deleted when a referencing parent is deleted. The reference is simply removed.
---

## What is an AI Policy?

An AI Policy is a reusable configuration that can be attached to {{site.ai_gateway}} entities to enforce security, transformation, and traffic-control behavior.

Each AI Policy specifies a `type` field (such as `ai-sanitizer` or `ai-rate-limiting-advanced`) that identifies the behavior, and a `config` block that provides that behavior's configuration. {{site.ai_gateway}} attaches the configured policy at the scope you select: globally, or to a specific AI Model, AI Agent, or AI MCP Server.

For the complete set of behaviors available as an AI Policy `type`, see the [AI policies hub](/ai-gateway/policies/).

**AI Policies are not shared.** Each AI Policy is an independent configuration tied to its parent entity's lifecycle. To apply identical configuration to two AI Models, create two separate AI Policies with matching `config`. This design ensures that deleting an AI Model deletes only its own AI Policies, not configurations used by other entities.

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

An AI Policy's scope is determined by where it's referenced. Each AI Policy is an independent configuration that applies at exactly one scope: globally, or to a specific entity (AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group). To apply identical configuration in multiple places, create one AI Policy per location.

The available scopes are:

* **Global**: an AI Policy with no parent entity reference applies to all {{site.ai_gateway}} traffic on the data plane. Non-AI traffic on the same data plane isn't affected.
* **AI Model**: referenced from the `policies` array on an [AI Model entity](/ai-gateway/entities/ai-model/). The Policy applies to that AI Model.
* **AI Agent**: referenced from the `policies` array on an [AI Agent entity](/ai-gateway/entities/ai-agent/). The Policy applies to that AI Agent.
* **AI MCP Server**: referenced from the `policies` array on an [AI MCP Server entity](/ai-gateway/entities/ai-mcp-server/). The Policy applies to that AI MCP Server.
* **AI Consumer**: referenced from the `policies` array on an [AI Consumer entity](/ai-gateway/entities/ai-consumer/). The Policy applies when the AI Consumer is identified during a request.
* **AI Consumer Group**: referenced from the `policies` array on an [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/). The Policy applies when a member of the AI Consumer Group is identified during a request.

### Creating AI Policies

All AI Policies are created through a single endpoint at `/v1/ai-gateways/{aiGatewayId}/policies`. Scope is determined entirely by which entity references the AI Policy: add the AI Policy's `name` or `id` to the parent entity's `policies` array, or omit the reference for global scope.

## Lifecycle

An AI Policy maps to exactly one Policy entry in the underlying runtime. Creating, updating, or deleting an AI Policy creates, updates, or deletes that Policy entry respectively. All scopes support standard CRUD operations through the AI Policy API endpoint.

The `config` field is passed through to the policy without translation.

{:.info}
> **Policy config schemas live with the policy docs**
>
> {{site.ai_gateway}} does not define policy configuration schemas under the AI Policy entity.
> For each policy you intend to use as an AI Policy `type`, look up that policy's reference page for its `config` shape.

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
