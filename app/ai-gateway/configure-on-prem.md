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
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: AI MCP Proxy plugin
    url: /plugins/ai-mcp-proxy/
  - text: AI A2A Proxy plugin
    url: /plugins/ai-a2a-proxy/
---

On {{site.konnect_short_name}}, you configure {{site.ai_gateway}} through its entity model: [AI Providers](/ai-gateway/entities/ai-provider/), [AI Models](/ai-gateway/entities/ai-model/), [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI Policies](/ai-gateway/entities/ai-policy/). Self-hosted {{site.base_gateway}} doesn't expose these entities. Instead, you configure the same capabilities with AI plugins on [Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/).

Both deployments run the same {{site.base_gateway}} primitives. When you save an AI entity in {{site.konnect_short_name}}, {{site.ai_gateway}} generates the Services, Routes, Plugins, and Consumers that data planes run. On-prem, you create those primitives yourself.

{:.info}
> On-prem, each plugin's configuration maps 1:1 to an [{{site.ai_gateway}} Policy](/ai-gateway/policies/). The AI Policy fields and the plugin fields are the same.

## How entities become {{site.base_gateway}} configurations

The mapping depends on the entity. Some entities generate a single {{site.base_gateway}} primitive, some generate several, and an AI Provider generates none of its own.

{% table %}
columns:
  - title: "{{site.konnect_short_name}} entity"
    key: entity
  - title: On-prem {{site.base_gateway}} configuration
    key: primitives
rows:
  - entity: "[AI Model](/ai-gateway/entities/ai-model/)"
    primitives: "A Service, one Route per capability it serves, and the plugins on each Route (`ai-model-selector` and [`ai-proxy-advanced`](/plugins/ai-proxy-advanced/))."
  - entity: "[AI Provider](/ai-gateway/entities/ai-provider/)"
    primitives: "None of its own. Its `type` and credentials are materialized into the `ai-proxy-advanced` target of every AI Model that references it."
  - entity: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    primitives: "One or more Routes carrying the [`ai-mcp-proxy`](/plugins/ai-mcp-proxy/) plugin. The Route topology depends on the server [mode](/ai-gateway/entities/ai-mcp-server/#server-modes)."
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    primitives: "A Service, a Route, and the [`ai-a2a-proxy`](/plugins/ai-a2a-proxy/) plugin."
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    primitives: "The {{site.base_gateway}} plugin named by the policy `type` (for example, `ai-prompt-guard` or `ai-rate-limiting-advanced`), applied globally or scoped to whatever the policy is attached to."
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    primitives: "A [Consumer](/gateway/entities/consumer/) with its credentials."
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    primitives: "A [Consumer Group](/gateway/entities/consumer-group/) with its membership."
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    primitives: "A [Vault](/gateway/entities/vault/)."
{% endtable %}

### Example: an AI Model as {{site.base_gateway}} configuration

The following AI Model, `gpt-5-2`, exposes the `generate` capability on `/ai` and routes to a single target backed by the `openai-prod` AI Provider:

```yaml
# AI entities, as configured in {{site.konnect_short_name}}
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
        alias: "@openai/gpt-5.2"
    targets:
      - name: gpt-5.2
        provider: openai-prod
        config:
          type: openai
          temperature: 1.0
          max_tokens: 1024
providers:
  - name: openai-prod
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: "{vault://ai/openai-token}"
```

For this AI Model, {{site.ai_gateway}} generates a Service, a Route, and an `ai-proxy-advanced` plugin on that Route:

```yaml
services:
  - name: ai-gateway
    routes:
      - name: openai-chat
        paths:
          - /ai/chat/completions
        methods:
          - POST
plugins:
  - name: ai-proxy-advanced
    route:
      name: openai-chat
    config:
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: "{vault://ai/openai-token}"
          model:
            model_alias: "@openai/gpt-5.2"
            provider: openai
            name: gpt-5.2
```

The AI Provider generates no object of its own. Its `type` becomes the target's `model.provider`, and its `auth` is materialized into the same `ai-proxy-advanced` target.

## On-prem request flow

On-prem, a client sends requests to {{site.base_gateway}}, where a [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/) carry the AI plugin. The plugin applies the AI behavior and proxies the request to the upstream, whether that's an LLM provider, an MCP server, or an agent.

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
> _Figure 1:_ On-prem, {{site.ai_gateway}} capabilities are delivered by plugins on {{site.base_gateway}}, each proxying to its upstream.

## AI Models

Use the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) (`ai-proxy-advanced`) plugin to transform and proxy requests to multiple AI providers and models at the same time, and to load balance across targets. On {{site.konnect_short_name}}, an AI Model generates a Service, one Route per capability it serves (chat completions, embeddings, and so on), and the plugins on each Route (`ai-model-selector` and `ai-proxy-advanced`). On-prem, create one Route per capability you want to expose, each carrying its own `ai-proxy-advanced` plugin.

The AI Provider referenced by a target has no plugin of its own. Set its `type` and `auth` in the corresponding `targets` entry of the [`ai-proxy-advanced`](/plugins/ai-proxy-advanced/) plugin.


## AI MCP Servers

Use the [AI MCP Proxy](/plugins/ai-mcp-proxy/) (`ai-mcp-proxy`) plugin to convert APIs into MCP tools, proxy MCP servers, expose MCP tools to AI clients, and observe MCP traffic. On {{site.konnect_short_name}}, an AI MCP Server generates one or more Routes, each carrying an `ai-mcp-proxy` plugin. The number of Routes, and whether the plugin converts a REST API into MCP tools or proxies an existing MCP server, depends on the server [mode](/ai-gateway/entities/ai-mcp-server/#server-modes). On-prem, configure the plugin's mode and Routes to match the topology you want.


## AI Agents

Use the [AI A2A Proxy](/plugins/ai-a2a-proxy/) (`ai-a2a-proxy`) plugin to add observability and gateway control to Agent-to-Agent (A2A) protocol traffic. The plugin supports both JSON-RPC and REST bindings. On {{site.konnect_short_name}}, an AI Agent generates one Service, one Route, and one `ai-a2a-proxy` plugin, which matches what you configure on-prem.

## Consumers, Consumer Groups, and Vaults

Access control and secret management on-prem use the same {{site.base_gateway}} objects as any other Gateway configuration, so the objects themselves need no AI-specific setup. Use the existing {{site.base_gateway}} documentation:

* [Consumers](/gateway/entities/consumer/): Authenticate the clients that call your AI routes. For Consumer-scoped behavior, such as OpenID Connect authentication, attach the plugin directly to that Consumer.
* [Consumer Groups](/gateway/entities/consumer-group/): Apply shared rate limits and policies to groups of Consumers by attaching the plugin to the Consumer Group.
* [Vaults](/gateway/entities/vault/): Store and reference provider credentials.
