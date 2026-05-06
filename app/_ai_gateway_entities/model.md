---
title: AI Models
content_type: reference
entities:
  - ai-model
products:
  - ai-gateway
description: AI Models registered with the {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: Load balancing with AI Proxy Advanced
    url: /ai-gateway/load-balancing/
  - text: Provider entity
    url: /ai-gateway/entities/provider/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: Consumer Group entity
    url: /gateway/entities/consumer-group/
faqs:
  - q: What's the difference between a Model entity and the `model` field inside an AI Proxy Advanced plugin config?
    a: |
      A Model entity is the first-class {{site.ai_gateway}} entity you declare through the `/ai/models` API or {{site.konnect_short_name}}.
      {{site.ai_gateway}} derives the AI Proxy Advanced plugin (and its `model` configuration) from the entity.
      You don't configure the underlying plugin directly.

  - q: Can I edit the Service, Routes, or plugins that {{site.ai_gateway}} generates from a Model?
    a: |
      No. Generated primitives are protected from direct modification through the standard Admin API.
      Update the Model entity instead, and {{site.ai_gateway}} recreates the underlying primitives within a single transaction.

  - q: What happens when I update a Model?
    a: |
      {{site.ai_gateway}} deletes the Model's derived primitives and recreates them from the updated entity state, all within a single database transaction.
      On failure, the transaction rolls back and no partial state is written.

  - q: What happens when I delete a Model?
    a: |
      The Model and all its derived primitives (Service, Routes, plugin instances) are deleted within a single transaction.

  - q: Can I apply the same configuration to multiple Models?
    a: |
      Yes, by attaching one Policy with that configuration to each Model.
      Policies are not shared between entities, each instance is independent.
      See [Policy entity](/ai-gateway/entities/policy/).

  - q: How do I limit which consumers can reach a Model?
    a: |
      Set the `acls` field on the Model with allow or deny lists.
      Each entry is a string that references a Consumer, Consumer Group, or Authenticated Group by name.

  - q: Does the Model entity store provider credentials?
    a: |
      No. Provider credentials live on the [Provider entity](/ai-gateway/entities/provider/) and are materialized into the generated AI Proxy Advanced plugin configuration at Model creation time.
      Updating a Provider propagates the credential change to all Models that reference it.

  - q: Are on-prem and {{site.konnect_short_name}} Model entities the same?
    a: |
      The schemas are intentionally aligned at the field level. The same Model definition works in both modes.
      On-prem omits a few {{site.konnect_short_name}}-specific path segments and concepts that don't apply in a single-deployment context, such as the `ai-gateways/{id}` container and Data Plane certificate or node management. The Model entity itself is identical.
---

## What is a Model?

A Model is a first-class {{site.ai_gateway}} entity that represents an AI model endpoint exposed through {{site.ai_gateway}}.

A Model declares which capabilities it exposes (such as `chat`, `responses`, or `embeddings`), which upstream provider models it routes to, and how requests are load-balanced and logged. {{site.ai_gateway}} translates a Model into the underlying primitives that the runtime uses to serve traffic, so you don't need to assemble Services, Routes, or plugin entries by hand.

Models are managed through the {{site.ai_gateway}} entity surface in both deployment modes:

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
    endpoint: /v1/ai-gateways/{aiGatewayId}/models
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/models
{% endtable %}

## How a Model maps to runtime configuration

When you create or update a Model, {{site.ai_gateway}} generates a fixed set of primitives:

* One [Gateway Service](/gateway/entities/service/).
* One [Route](/gateway/entities/route/) per declared capability in the `capabilities` array.
* One [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin per generated Route.

Provider credentials are added into the AI Proxy Advanced plugin configuration at generation time, sourced from the Provider entity that the Model's `target_models` reference. Updating the Provider propagates credential changes to every Model that uses it.

Generated primitives are protected. Direct PUT, PATCH, or DELETE calls against the underlying Service, Routes, or plugin entries through the standard Admin API are rejected. To change anything about a Model's runtime footprint, update the Model entity. {{site.ai_gateway}} deletes and recreates the derived primitives within a single transaction.

{:.info}
> **Why a transaction instead of an in-place update?**
>
> A Model's structure (which capabilities exist, which providers it routes to) determines how many Routes and plugin entries are needed. A delete-and-recreate cycle is the simplest way to keep the entity and its derived primitives consistent, especially when capabilities are added or removed.

## Capabilities

The `capabilities` field tells {{site.ai_gateway}} which AI workflows the Model exposes. Each capability becomes one Route on the generated Service. A Model must declare at least one capability.

Model `type` controls which capability set applies:

* `model`: synchronous request/response workloads through generative APIs. Supported capabilities are `chat`, `embeddings`, `assistants`, `responses`, `audio-transcriptions`, `audio-translations`, `image-generation`, `image-edits`, `video-generations`, and `realtime`.
* `api`: asynchronous workloads through the files and batches APIs. Supported capabilities are `batches` and `files`.

Not every provider supports every capability. The set of capabilities you can declare on a Model depends on what the provider in `target_models` exposes. See [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for per-provider details.

## Target models and load balancing

A Model's `target_models` field lists one or more upstream provider model instances. For each entry, you provide the upstream model name (for example, `gpt-4o`) and reference the Provider to use by its `name`. Each target can also override settings such as `temperature`, `max_tokens`, `input_cost`, and `output_cost`.

When a Model has more than one target, requests are load-balanced according to `config.balancer`. For the supported algorithms, configuration options, and tuning guidance, see [Load balancing with AI Proxy Advanced](/ai-gateway/load-balancing/).

## Access control

A Model's `acls` field controls which identities are allowed to reach the Model. The field accepts `allow` and `deny` lists. Each entry is a string that references a Consumer, Consumer Group, or Authenticated Group by name. Access is enforced at the Service level of the generated primitives.

For per-request authentication and identity, configure the appropriate authentication plugin globally or as a Policy on the Model.

## Attach Policies

Policies are the way you apply plugin configurations to a Model. A Policy attached to a Model runs at the Service level of the Model's generated primitives, so it applies to every request routed through any of the Model's capabilities.

A Model declares the Policies it uses through its `policies` field. Each entry is a string that references a Policy by name or ID. {{site.konnect_short_name}} resolves these references against Policies created at `/v1/ai-gateways/{aiGatewayId}/policies`. On-prem also supports the nested endpoint `/ai/models/{modelId}/policies`, which creates and attaches a Policy in one call.

You can attach multiple Policies to a single Model. Each Policy has an independent plugin instance, so attaching the same plugin type twice with different configurations creates two separate plugin entries.

Not every plugin type is valid as a Model Policy.

Policies attached to a Model are deleted when the Model is deleted.

For further information see the [Policy entity](/ai-gateway/entities/policy/) reference.

### Plugin priority and Policy execution order

A Policy attached to a Model creates one plugin entry on the Service of the Model's derived primitives. That plugin runs at the [priority](/gateway/entities/plugin/#plugin-priority) of its underlying plugin type, which determines when it executes relative to other plugins on the request.

The AI Proxy Advanced plugin runs at priority `770` and parses the request body to resolve the model name. Any Policy whose underlying plugin type has a priority higher than `770` runs before that resolution. Authentication plugin types (such as OpenID Connect) fall into this category. They still gate access correctly because routing to the Model's generated Service already occurred, but model-level identity details (provider and target model) are not available yet.

For Policies whose runtime behavior depends on the resolved Model identity, attach plugin types that run at priority `770` or lower, or use [dynamic plugin ordering](/gateway/entities/plugin/) to push their execution later.

## Set up a Model

The following example creates an OpenAI Model that exposes both `chat` and `responses` capabilities, routed through a single OpenAI Provider, with token usage logging enabled.

{% entity_example %}
type: model
data:
  display_name: GPT-4o Production
  name: gpt-4o-production
  type: model
  enabled: true
  capabilities:
    - chat
    - responses
  formats:
    - type: openai
  acls:
    allow:
      - internal-teams
    deny: []
  policies: []
  target_models:
    - name: gpt-4o
      provider:
        name: my-openai-account
      config:
        temperature: 0.7
        max_tokens: 4096
        input_cost: 0.0000025
        output_cost: 0.000010
  config:
    logging:
      statistics: true
      payloads: false
    response_streaming: allow
    max_request_body_size: 1048576
    model:
      name_header: true
    balancer:
      algorithm: round-robin
      retries: 3
      connect_timeout: 60000
      read_timeout: 60000
      write_timeout: 60000
{% endentity_example %}

## Schema

{% entity_schema %}
