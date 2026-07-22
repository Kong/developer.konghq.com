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

{{site.ai_gateway}} on {{site.konnect_short_name}} is documented around its entity model.
If you run {{site.ai_gateway}} on self-hosted {{site.base_gateway}}, this page maps each entity to the plugins and objects you already configure, so you can read {{site.ai_gateway}} docs and know how to apply them to your deployment.
You can [convert](#convert-ai-gateway-2-0-entities-to-self-hosted-kong-gateway-config) any {{site.ai_gateway}} 2.0 decK configuration into the equivalent self-hosted config.

On {{site.konnect_short_name}}, you configure {{site.ai_gateway}} through its entity model: [AI Models](/ai-gateway/entities/ai-model/), [AI Model Providers](/ai-gateway/entities/ai-model-provider/), [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), [AI Agents](/ai-gateway/entities/ai-agent/), [AI Identity Providers](/ai-gateway/entities/ai-identity-provider/), [AI Policies](/ai-gateway/entities/ai-policy/), [AI Consumers](/ai-gateway/entities/ai-consumer/), [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/), and [AI Vaults](/ai-gateway/entities/ai-vault/). Self-hosted {{site.base_gateway}} doesn't expose these entities. Instead, you configure the same capabilities with AI plugins on [Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/).

Both deployments run the same {{site.base_gateway}} primitives. When you save an AI entity in {{site.konnect_short_name}}, {{site.ai_gateway}} generates the Services, Routes, Plugins, and Consumers that data planes run. On-prem, you create those primitives yourself.

{:.info}
> On-prem, each Policy-backed plugin's configuration maps 1:1 to an [{{site.ai_gateway}} Policy](/ai-gateway/policies/). The AI Policy fields and the plugin fields are the same.

## How entities translate to {{site.base_gateway}} configuration

AI entities are a high-level abstraction. When you save one, a dedicated conversion step translates it into the same {{site.base_gateway}} building blocks classic {{site.base_gateway}} uses (Routes, Services, plugins, Consumers), and that's what data plane nodes actually run.

The mapping isn't always 1:1. Some entities carry over almost directly while others become more than one {{site.base_gateway}} entity.

The following table describes how {{site.konnect_short_name}} {{site.ai_gateway}} entities map to {{site.ai_gateway}} on self-hosted {{site.base_gateway}} entities.

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
    primitives: "One or more Routes carrying the AI MCP Proxy plugin. The Route topology depends on the server [mode](/ai-gateway/entities/ai-mcp-server/#server-modes)."
  - entity: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    primitives: "A Service, a Route, and the AI A2A Proxy plugin."
  - entity: "[AI Identity Provider](/ai-gateway/entities/ai-identity-provider/)"
    primitives: "None of its own. A `key-auth` type materializes into a Key Auth Policy, and an `openid-connect` type into an OpenID Connect Policy, on the Route of every AI Model that references it, plus a shared anonymous Consumer with a Request Termination Policy that returns 401 for unauthenticated requests."
  - entity: "[AI Policy](/ai-gateway/entities/ai-policy/)"
    primitives: "The {{site.base_gateway}} plugin named by the policy `type` (for example, AI Prompt Guard or AI Rate Limiting Advanced), applied globally or scoped to whatever the policy is attached to."
  - entity: "[AI Consumer](/ai-gateway/entities/ai-consumer/)"
    primitives: "A [Consumer](/gateway/entities/consumer/) with its credentials."
  - entity: "[AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    primitives: "A [Consumer Group](/gateway/entities/consumer-group/) with its membership."
  - entity: "[AI Vault](/ai-gateway/entities/ai-vault/)"
    primitives: "A [Vault](/gateway/entities/vault/)."
{% endtable %}

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

## Convert {{site.ai_gateway}} 2.0 entities to self-hosted {{site.base_gateway}} config

Use `deck file ai2kong` to convert any {{site.ai_gateway}} 2.0 decK configuration into {{site.ai_gateway}} on self-hosted {{site.base_gateway}} entities.
The following steps walk through converting a decK `ai.yaml` file for a single AI Model.

1. Write a decK `ai.yaml` configuration file using the {{site.ai_gateway}} 2.0 entity model. For example, the following AI Model, `gpt-5-2`, exposes the `generate` capability on `/ai` and routes to a single target backed by the `openai-prod` AI Provider:

   ```sh
   echo '
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
             body:
               model:
                 - "@openai/gpt-5.2"
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
   ' > ai.yaml
   ```
1. Convert the {{site.ai_gateway}} entity config to {{site.base_gateway}} 3.x config:

   ```sh
   deck file ai2kong --state ai.yaml --output-file kong.yaml
   ```
   For this example AI Model, {{site.ai_gateway}} generates a Service, a Route, and an `ai-proxy-advanced` plugin on that Route. `kong.yaml` contains:

   {:.info}
   > This converted output still shows the `alias`/`model_alias` fields used by the self-hosted `ai-proxy-advanced` plugin schema. Verify with the `deck file ai2kong` conversion tool for the current output once it supports the `config.route.model` routing rule shown in the input above.

   ```yaml
   _format_version: "3.0"
   _info:
     select_tags:
     - 'managed-by: deck-ai'
   ai_models:
   - alias: '@openai/gpt-5.2'
     name: gpt-5-2
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
         model:
           model_alias: '@openai/gpt-5.2'
           name: gpt-5.2
           options:
             max_tokens: 1024
             temperature: 1
           provider: openai
         route_type: llm/v1/chat
     model:
       name: gpt-5-2
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

   The AI Provider generates no object of its own. Its `type` becomes the target's `model.provider`, and its `auth` is materialized into the same `ai-proxy-advanced` target.
1. Sync the converted config to your self-hosted {{site.base_gateway}}:
   ```sh
   deck gateway sync kong.yaml
   ```