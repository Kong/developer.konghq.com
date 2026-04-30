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
      A Policy is a plugin instance configured through the {{site.ai_gateway}}. entity
      surface instead of the classic `/plugins` endpoint. The runtime effect
      is the same: a plugin attached at the appropriate scope. The differences
      are how you create it (`/ai/policies` or under a parent entity), how it's
      tagged in the workspace, and that the {{site.ai_gateway}}. control plane manages
      its lifecycle alongside the entity it's attached to.

  - q: Can a Policy be scoped to a Consumer or Consumer Group?
    a: |
      Not directly. A Policy attaches to the {{site.ai_gateway}} globally or
      to a Model, Agent, or MCP Server. Per-consumer access is expressed
      through the `acls` field on those parent entities, which gates which
      Consumer Groups can reach the entity in the first place.

  - q: What plugin types can a Policy use?
    a: |
      Any {{site.ai_gateway}}.-compatible plugin. Common values include `ai-sanitizer`,
      `ai-prompt-guard`, `ai-prompt-decorator`, `ai-rate-limiting-advanced`,
      and `openid-connect`. Set the plugin name in the Policy's `type` field
      and provide the plugin's configuration in the `config` field.

  - q: What happens to a Policy when its parent entity is deleted?
    a: |
      Policies attached to a Model, Agent, or MCP Server are removed when the
      parent entity is deleted, along with the rest of that entity's derived
      primitives. Global policies are independent and aren't affected by
      deletions of other entities.
---

## What is a Policy?

A Policy is a plugin instance registered through the {{site.ai_gateway}} entity surface.

Each Policy declares a `type` (the plugin name, for example `ai-sanitizer` or `ai-rate-limiting-advanced`) and a `config` block whose contents follow that plugin's own schema. The {{site.ai_gateway}} control plane attaches the configured plugin at the scope you select: globally, or to a specific Model, Agent, or MCP Server.

Policies are not shared. Each Policy is one plugin instance. To apply the same configuration to two parent entities, create two Policies.

## Policy scopes

A Policy is scoped at the time you create it, by the endpoint you POST it to:

* **Global**: `POST /ai/policies` attaches the underlying plugin at the global scope of the `_ai_gateway` workspace. The plugin runs for every {{site.ai_gateway}} request that reaches the runtime.
* **Model**: `POST /ai/models/{modelId}/policies` attaches the underlying plugin at the Service of the Model's derived primitives. The plugin runs for requests routed through that Model.
* **Agent**: `POST /ai/agents/{agentId}/policies` attaches the plugin at the Service of the Agent's derived primitives.
* **MCP Server**: `POST /ai/mcp-servers/{mcpServerId}/policies` attaches the plugin at the Service of the MCP Server's derived primitives.

Scope is fixed at creation time. Moving a Policy from one scope to another means deleting it and creating a new one under the target endpoint.

## Policy and plugin relationship

Creating a Policy creates exactly one plugin entry in the underlying runtime. Updating a Policy updates that plugin entry. Deleting a Policy deletes that plugin entry.

The `config` field is passed through to the plugin without translation. Refer to the documentation for the specific plugin to see the available fields, defaults, and validation rules.

{:.note}
> **Plugin config schemas live with the plugin docs**
>
> {{site.ai_gateway}} does not redeclare plugin configuration schemas under the Policy entity. For each plugin you intend to use as a Policy `type`, look up that plugin's reference page for its `config` shape.

## Set up a global Policy

The following example creates a global PII sanitizer Policy that runs for every {{site.ai_gateway}}. request.

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
formats:
  - admin-api
  - konnect-api
{% endentity_example %}

## Set up a Model-scoped Policy

The following example attaches a rate limiting Policy to a Model. It assumes a Model with `id` `bf138ba2-c9b1-4229-b268-04d9d8a6410b` already exists.

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
formats:
  - admin-api
  - konnect-api
{% endentity_example %}

<!-- TODO: confirm the actual `config` shape for ai-rate-limiting-advanced against the plugin's current schema. -->

## Schema

{% entity_schema %}
