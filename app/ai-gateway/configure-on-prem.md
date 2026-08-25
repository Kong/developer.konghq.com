---
title: "Configure {{site.ai_gateway_name}} on-prem"

description: "Configure {{site.ai_gateway_name}} on self-hosted {{site.base_gateway}} using the 3.x data model and AI plugins, and map each core entity to its plugin."
content_type: reference
layout: reference
products:
  - ai-gateway

works_on:
  - on-prem

breadcrumbs:
  - /ai-gateway/

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: "Migrate to {{site.ai_gateway}} 2.x"
    url: /ai-gateway/v2-migration-guide/
  - text: deck file ai2kong
    url: /deck/file/ai2kong/
  - text: deck ai sync
    url: /deck/ai/sync/
  - text: deck ai dump
    url: /deck/ai/dump/
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: AI MCP Proxy plugin
    url: /plugins/ai-mcp-proxy/
  - text: AI A2A Proxy plugin
    url: /plugins/ai-a2a-proxy/
---

The existing {{site.ai_gateway}} documentation follows the {{site.konnect_short_name}} model: AI Models, AI Model Providers, AI MCP Servers, AI Agents, and more, that you configure in {{site.konnect_short_name}}. See [{{site.ai_gateway}} entities](/ai-gateway/entities/) for the full list. Self-hosted {{site.base_gateway}} doesn't have these objects. This page shows you how to configure the same capabilities with AI plugins on [Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/).

There are two ways to bridge that gap:

* Read [How entities translate to {{site.base_gateway}} configuration](#how-entities-translate-to-kong-gateway-configuration) to translate what you read in {{site.ai_gateway}} docs into the plugin fields you configure by hand.
* [Convert](#convert-ai-gateway-2-0-entities-to-self-hosted-kong-gateway-config) an existing {{site.ai_gateway}} 2.0 decK configuration into the equivalent self-hosted config, instead of hand-writing the plugins.

Both deployments run the same {{site.base_gateway}} Services, Routes, Plugins, and Consumers (what we call primitives). When you save an AI entity in {{site.konnect_short_name}}, {{site.ai_gateway}} generates the primitives that data planes run. On-prem, you produce those same primitives yourself, either by writing the plugin config directly or by converting an entity-model file.

## How entities translate to {{site.base_gateway}} configuration

AI entities are a high-level abstraction. When you save one, a dedicated conversion step translates it into the same Routes, Services, plugins, and Consumers that self-hosted {{site.base_gateway}} uses, and that's what data plane nodes actually run.

The mapping isn't always 1:1. Some entities carry over almost directly, others become more than one {{site.base_gateway}} object, and a few have no self-hosted equivalent at all.

The following table shows how {{site.konnect_short_name}} {{site.ai_gateway}} entities map to on-prem {{site.base_gateway}} configuration.

{% table %}
columns:
  - title: "{{site.konnect_short_name}} entity"
    key: entity
  - title: On-prem {{site.base_gateway}} configuration
    key: primitives
rows:
  - entity: "[AI Model](/ai-gateway/entities/ai-model/)"
    primitives: "A Service, one Route per capability it serves, and the AI Proxy Advanced plugin on each Route."
  - entity: "[AI Model Provider](/ai-gateway/entities/ai-model-provider/)"
    primitives: "None of its own. Its `type` and credentials are materialized into the AI Proxy Advanced target of every AI Model that references it."
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    primitives: "One or more Routes carrying the AI MCP Proxy plugin, depending on the server [mode](/ai-gateway/entities/ai-mcp-server/#server-modes). The `upstream-server` mode has no self-hosted equivalent; the plugin's `mode` field doesn't support it."
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    primitives: "For `type: a2a`, a Service, a Route, and the AI A2A Proxy plugin. For `type: http`, a Service and a Route with no AI plugin, since the AI A2A Proxy plugin always applies A2A protocol handling."
  - entity: "[AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/)"
    primitives: "None of its own. A `key-auth` type materializes into a Key Auth Policy, and an `openid-connect` type into an OpenID Connect Policy, on the Route of every AI Model or AI Agent that references it, plus a shared anonymous Consumer with a Request Termination Policy that returns 401 for unauthenticated requests."
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    primitives: "The {{site.base_gateway}} plugin named by the policy `type` (for example, AI Prompt Guard or AI Rate Limiting Advanced), applied globally or scoped to whatever the policy is attached to."
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    primitives: "A [Consumer](/gateway/entities/consumer/) with its credentials."
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    primitives: "A [Consumer Group](/gateway/entities/consumer-group/) with its membership."
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    primitives: "A [Vault](/gateway/entities/vault/)."
  - entity: "[AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/)"
    primitives: "None. It authorizes {{site.konnect_short_name}}-managed data planes to connect to a specific {{site.ai_gateway}}. Self-hosted hybrid mode deployments use the standard [Certificate](/gateway/entities/certificate/) entity and [hybrid mode node configuration](/gateway/hybrid-mode/) instead."
{% endtable %}

## On-prem request flow

On-prem, a client sends requests to {{site.base_gateway}}, where a [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/) carry the AI plugin. The plugin applies the AI behavior and proxies the request to the upstream, whether that's an LLM provider, an MCP server, or an agent.

<!--vale off-->
{% mermaid %}
flowchart LR
  Client(Client)
  subgraph Gateway["{{site.base_gateway}}"]
    P1[AI Proxy Advanced]
    P2[AI MCP Proxy]
    P3[AI A2A Proxy]
  end
  LLM(LLM providers)
  MCP(MCP servers)
  Agent(Agents)
  Client --> P1 --> LLM
  Client --> P2 --> MCP
  Client --> P3 --> Agent
{% endmermaid %}
<!--vale on-->
> _Figure 1:_ On-prem, {{site.ai_gateway}} capabilities are delivered by plugins on {{site.base_gateway}}, each proxying to its upstream.

## AI Models

Use the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) (`ai-proxy-advanced`) plugin to transform and proxy requests to multiple AI providers and models at the same time, and to load balance across targets.

- **On {{site.konnect_short_name}}:** An AI Model generates a Service, one Route per capability it serves (chat completions, embeddings, and so on), and the plugins on each Route (`ai-model-selector` and `ai-proxy-advanced`).
- **On-prem:** You create one Route per capability you want to expose, each carrying its own `ai-proxy-advanced` plugin.

The AI Model Provider referenced by a target has no plugin of its own. Set its `type` and `auth` in the corresponding `targets` entry of the [`ai-proxy-advanced`](/plugins/ai-proxy-advanced/) plugin.

## AI MCP Servers

Use the [AI MCP Proxy](/plugins/ai-mcp-proxy/) (`ai-mcp-proxy`) plugin to convert APIs into MCP tools, proxy MCP servers, expose MCP tools to AI clients, and observe MCP traffic.

- **On {{site.konnect_short_name}}:** An AI MCP Server generates one or more Routes, each carrying an `ai-mcp-proxy` plugin. The number of Routes, and whether the plugin converts a REST API into MCP tools or proxies an existing MCP server, depends on the server [mode](/ai-gateway/entities/ai-mcp-server/#server-modes).
- **On-prem:** You configure the plugin's mode and Routes to match the topology you want.

## AI Agents

Use the [AI A2A Proxy](/plugins/ai-a2a-proxy/) (`ai-a2a-proxy`) plugin to add observability and gateway control to Agent-to-Agent (A2A) protocol traffic. The plugin supports both JSON-RPC and REST bindings, and always applies A2A protocol handling, agent card URL rewriting, and A2A telemetry. It has no mode to turn that off.

On {{site.konnect_short_name}}, an AI Agent with `type: a2a` generates:
- One Service
- One Route
- One `ai-a2a-proxy` plugin

This matches what you configure on-prem. An AI Agent with `type: http` generates a Service and Route with no AI plugin, since `type: http` is a plain transparent proxy. Replicate it on-prem with a Service and Route and no plugin attached.

## AI Auth Strategies

Use the `key-auth` or `openid-connect` auth strategy, backed by the `key-auth` and `openid-connect` {{site.base_gateway}} plugins, to authenticate the clients calling your AI routes.

- **On {{site.konnect_short_name}}:** An AI Auth Strategy generates a `key-auth` or `openid-connect` plugin on the Route of every AI Model or AI Agent that references it, plus a shared anonymous Consumer carrying a `request-termination` plugin that returns `401` for requests that don't authenticate.
- **On-prem:** You attach the corresponding plugin to each Route yourself, and configure the anonymous Consumer and `request-termination` plugin to match.

## AI Policies

An AI Policy applies a specific behavior, named by its `type` (for example, `ai-prompt-guard` or `ai-rate-limiting-advanced`), either globally or scoped to whatever it's attached to: an AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group. On {{site.konnect_short_name}}, an AI Policy generates the {{site.base_gateway}} plugin named by that `type`, applied at the same scope.

{:.info}
> On-prem, each Policy-backed plugin's configuration maps 1:1 to an [{{site.ai_gateway}} Policy](/ai-gateway/policies/). The AI Policy fields and the plugin fields are the same.

## Consumers, Consumer Groups, Vaults, and Data Plane Certificates

Access control and secret management on-prem use the same {{site.base_gateway}} objects as any other Gateway configuration, so the objects themselves need no AI-specific setup. Use the existing {{site.base_gateway}} documentation:

* [Consumers](/gateway/entities/consumer/): Authenticate the clients that call your AI routes. For Consumer-scoped behavior, such as OpenID Connect authentication, attach the plugin directly to that Consumer.
* [Consumer Groups](/gateway/entities/consumer-group/): Apply shared rate limits and policies to groups of Consumers by attaching the plugin to the Consumer Group.
* [Vaults](/gateway/entities/vault/): Store and reference provider credentials.

[AI Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/) have no on-prem equivalent. They authorize {{site.konnect_short_name}}-managed data planes to connect to a specific {{site.ai_gateway}}. Self-hosted hybrid mode deployments use the standard [Certificate](/gateway/entities/certificate/) entity and [hybrid mode node configuration](/gateway/hybrid-mode/) instead.

## Convert {{site.ai_gateway}} 2.0 entities to self-hosted {{site.base_gateway}} config

AI Model, AI MCP Server, AI Agent, and AI Policy entities need conversion, since each one generates {{site.base_gateway}} Services, Routes, or plugins. AI Consumers, AI Consumer Groups, and AI Vaults pass through conversion unchanged, since they're already shaped like their [native {{site.base_gateway}} equivalents](#consumers-consumer-groups-vaults-and-data-plane-certificates).

decK's `file ai2kong`, `ai sync`, and `ai dump` all translate the same {{site.ai_gateway}} 2.x configuration between its entity-model representation and its self-hosted plugin representation. They don't change versions, only where the config runs. `kongctl convert ai-gateway` does something different: it upgrades an older {{site.ai_gateway}} running on {{site.base_gateway}} plugin configuration to the 2.x entity model, for {{site.konnect_short_name}}.

<!--vale off-->
{% table %}
columns:
  - title: Command
    key: command
  - title: Direction
    key: direction
  - title: Use case
    key: usecase
rows:
  - command: "[`deck file ai2kong`](/deck/file/ai2kong/)"
    direction: "{{site.ai_gateway}} 2.x entity file → self-hosted config file"
    usecase: "Convert an `ai.yaml` file to a `kong.yaml` file without touching a live gateway, so you can review the output or apply it separately."
  - command: "[`deck ai sync`](/deck/ai/sync/)"
    direction: "{{site.ai_gateway}} 2.x entity file → live self-hosted {{site.base_gateway}}"
    usecase: "Convert and apply in one step. Equivalent to running `deck file ai2kong` followed by `deck gateway sync`."
  - command: "[`deck ai dump`](/deck/ai/dump/)"
    direction: "Live self-hosted {{site.base_gateway}} or {{site.konnect_short_name}} → {{site.ai_gateway}} 2.x entity file"
    usecase: "Export configuration previously created with `deck ai sync` (tagged `managed_by:deck-ai`) back into the entity model, for backup or review."
  - command: "[`kongctl convert ai-gateway`](/ai-gateway/v2-migration-guide/)"
    direction: "Pre-2.0 {{site.ai_gateway}} plugin config → {{site.ai_gateway}} 2.x entity file, for {{site.konnect_short_name}}"
    usecase: "One-time version upgrade: move an existing {{site.ai_gateway}} running on {{site.base_gateway}} configuration to a {{site.konnect_short_name}} {{site.ai_gateway}} 2.x control plane. See [Migrate to {{site.ai_gateway}} 2.x](/ai-gateway/v2-migration-guide/)."
{% endtable %}
<!--vale on-->

The rest of this section uses `deck file ai2kong` to show exactly what config each entity generates.

### Conversion workflow

Every example that follows uses the same two-step conversion, shown once here. Write your {{site.ai_gateway}} 2.0 entity configuration to `ai.yaml`, then:

1. Convert it to {{site.base_gateway}} 3.x config:

   ```sh
   deck file ai2kong --source ai.yaml --output-file kong.yaml
   ```
1. Sync the converted config to your self-hosted {{site.base_gateway}}:

   ```sh
   deck gateway sync kong.yaml
   ```

To skip the intermediate file, run `deck ai sync ai.yaml` instead of both steps.

The following sections show what `ai.yaml` and the resulting `kong.yaml` look like for each entity type.

### Convert an AI Model

The following AI Model, `gpt-5-2`, exposes the `generate` capability on `/ai` and routes to a single target backed by the `openai-prod` AI Model Provider:

```yaml
# ai.yaml (AI Gateway 2.0 entity model)
models:
  - name: gpt-5-2
    capabilities:
      - generate
    formats:
      - type: openai
    config:
      route:
        paths:
          - /ai
        model:
          body_param: model
          values: ["gpt-5.2"]
    targets:
      - name: gpt-5.2
        provider: openai-prod
        config:
          type: openai
          temperature: 1.0
          max_tokens: 1024
model_providers:
  - name: openai-prod
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: "{vault://ai/openai-token}"
```
{:.collapsible}

Converting it generates a Service, a Route, and an `ai-proxy-advanced` plugin on that Route:

```yaml
# kong.yaml (self-hosted Kong Gateway 3.x)
_format_version: "3.0"
_info:
  select_tags:
  - 'managed_by:deck-ai'
ai_models:
- name: gpt-5-2
plugins:
- config:
    body_path: model
    max_request_body_size: 8388608
    source: body
  name: ai-model-selector
  route: openai-chat
- config:
    balancer:
      algorithm: round-robin
    genai_category: text/generation
    llm_format: openai
    targets:
    - auth:
        header_name: Authorization
        header_value: '{vault://ai/openai-token}'
      description: gpt-5.2
      logging:
         log_payloads: false
         log_statistics: true
      model:
        model_alias: 'gpt-5.2'
        name: gpt-5.2
        options:
          max_tokens: 1024
          temperature: 1
        provider: openai
      route_type: llm/v1/chat
  model: gpt-5-2
  name: ai-proxy-advanced
  route: openai-chat
services:
- name: ai-gateway
  routes:
  - methods:
    - POST
    name: openai-chat
    paths:
    - /ai/chat/completions
    strip_path: false
  url: http://ai-gateway.upstream.local
```
{: .no-copy-code .collapsible }

The AI Model Provider generates no object of its own. Its `type` becomes the target's `model.provider`, and its `auth` is materialized into the same `ai-proxy-advanced` target.

{:.info}
> The converted output uses the `alias` and `model_alias` field names from the self-hosted `ai-model-selector` and `ai-proxy-advanced` plugin schemas. These are distinct from `config.route.model` on the {{site.ai_gateway}} entity shown in the input; `deck file ai2kong` handles the translation between the two.

### Convert an AI MCP Server

The following AI MCP Server, `demo-mcp`, uses [conversion-listener mode](/ai-gateway/entities/ai-mcp-server/#server-modes) to expose a single `get-item` tool that proxies a REST `GET` request:

```yaml
# ai.yaml (AI Gateway 2.0 entity model)
mcp_servers:
  - ref: demo-mcp
    name: demo-mcp
    display_name: "Demo MCP Server"
    type: conversion-listener
    enabled: true
    access:
      acl_attribute_type: consumer
    config:
      url: https://mock.example.com
      route:
        paths:
          - /demo-mcp
    tools:
      - name: get-item
        description: Fetch an item by id
        annotations:
          title: Fetch an item by id
        method: GET
        path: /items/{itemId}
        parameters:
          - name: itemId
            in: path
            description: The item id
            required: true
            schema:
              type: string
```
{:.collapsible}

Converting it generates a Service, a Route, and an `ai-mcp-proxy` plugin carrying the tool definition:

```yaml
# kong.yaml (self-hosted Kong Gateway 3.x)
_format_version: "3.0"
_info:
  select_tags:
  - 'managed_by:deck-ai'
services:
- host: localhost
  name: demo-mcp
  routes:
  - name: demo-mcp-route
    paths:
    - /demo-mcp
    plugins:
    - config:
        acl_attribute_type: consumer
        include_consumer_groups: true
        logging:
          log_audits: false
          log_payloads: false
          log_statistics: true
        mode: conversion-listener
        tools:
        - annotations:
            title: Fetch an item by id
          description: Fetch an item by id
          method: GET
          name: get-item
          parameters:
          - description: The item id
            in: path
            name: itemId
            required: true
            schema:
              type: string
          path: /items/{itemId}
      name: ai-mcp-proxy
```
{: .no-copy-code .collapsible }

### Convert an AI Agent

The following AI Agent, `demo-agent`, proxies Agent-to-Agent traffic to an upstream agent:

```yaml
# ai.yaml (AI Gateway 2.0 entity model)
agents:
  - ref: demo-agent
    name: demo-agent
    type: a2a
    display_name: "Demo Agent"
    enabled: true
    labels:
      team: demo
    config:
      url: https://agent.example.com
      route:
        paths:
          - /agents/demo
      logging:
        max_payload_size: 524288
```
{:.collapsible}

Converting it generates a Service, a Route, and an `ai-a2a-proxy` plugin on that Route:

```yaml
# kong.yaml (self-hosted Kong Gateway 3.x)
_format_version: "3.0"
_info:
  select_tags:
  - 'managed_by:deck-ai'
services:
- name: demo-agent
  routes:
  - name: demo-agent-route
    paths:
    - /agents/demo
    plugins:
    - config:
        logging:
          log_payloads: false
          log_statistics: true
          max_payload_size: 524288
      name: ai-a2a-proxy
  tags:
  - team:demo
  url: https://agent.example.com
```
{: .no-copy-code .collapsible }

An AI Agent with `type: http` converts the same way, minus the `ai-a2a-proxy` plugin: just the Service and Route.

### Convert an AI Policy

An AI Policy generates no object of its own. It must be attached to another entity, such as an AI Model, AI Agent, or AI MCP Server, and converts into the {{site.base_gateway}} plugin named by the policy `type`, scoped to that entity's Route.

The following `ai.yaml` defines a minimal chat model, `gpt-5-2`, with an `ai-gw-prompt-guard` policy attached:

```yaml
# ai.yaml (AI Gateway 2.0 entity model)
models:
  - name: gpt-5-2
    capabilities:
      - generate
    formats:
      - type: openai
    config:
      route:
        paths:
          - /ai
        model:
          body_param: model
          values: ["gpt-5.2"]
    policies:
      - ai-gw-prompt-guard
    targets:
      - name: gpt-5.2
        provider: openai-prod
        config:
          type: openai
model_providers:
  - name: openai-prod
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: "{vault://ai/openai-token}"
policies:
  - ref: ai-gw-prompt-guard
    name: ai-gw-prompt-guard
    display_name: "AI Prompt Guard"
    type: ai-prompt-guard
    enabled: true
    config:
      deny_patterns:
        - ".*(W|w)ar.*"
```
{:.collapsible}

Converting it generates the same Service, Route, `ai-model-selector`, and `ai-proxy-advanced` plugins as [converting an AI Model](#convert-an-ai-model), plus an `ai-prompt-guard` plugin on the same Route, scoped to the `gpt-5-2` model:

```yaml
# kong.yaml (self-hosted Kong Gateway 3.x)
- config:
    deny_patterns:
    - .*(W|w)ar.*
  model: gpt-5.2
  name: ai-prompt-guard
  route: openai-chat
```
{: .no-copy-code .collapsible }

The `model` and `route` fields on the plugin scope it to that AI Model's traffic instead of applying globally.
