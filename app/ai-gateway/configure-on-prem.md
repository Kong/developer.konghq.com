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

On {{site.konnect_short_name}}, you configure {{site.ai_gateway}} through its entity model: [AI Providers](/ai-gateway/entities/ai-provider/), [AI Models](/ai-gateway/entities/ai-model/), [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/), and [AI Agents](/ai-gateway/entities/ai-agent/). On self-hosted on-prem {{site.base_gateway}}, you can configure the same capabilities with {{site.ai_gateway}} plugins. You create [Services](/gateway/entities/service/) and [Routes](/gateway/entities/route/) and attach the relevant plugin, rather than declaring entities.

{:.info}
> On-prem, each plugin's configuration maps 1:1 to an [{{site.ai_gateway}} Policy](/ai-gateway/policies/). The Policy fields and the plugin fields are the same.

## How configuration differs by deployment

The following table maps each capability to its {{site.konnect_short_name}} entity and its on-prem plugin:

{% table %}
columns:
  - title: Capability
    key: capability
  - title: "{{site.konnect_short_name}} entity"
    key: entity
  - title: On-prem plugin
    key: plugin
rows:
  - capability: Models
    entity: AI Model
    plugin: "[`ai-proxy-advanced`](/plugins/ai-proxy-advanced/)"
  - capability: MCP Servers
    entity: AI MCP Server
    plugin: "[`ai-mcp-proxy`](/plugins/ai-mcp-proxy/)"
  - capability: Agents
    entity: AI Agent
    plugin: "[`ai-a2a-proxy`](/plugins/ai-a2a-proxy/)"
{% endtable %}

## On-prem configuration

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

## Models

Use the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) (`ai-proxy-advanced`) plugin to transform and proxy requests to multiple AI providers and models at the same time, and to load balance across targets.

## MCP Servers

Use the [AI MCP Proxy](/plugins/ai-mcp-proxy/) (`ai-mcp-proxy`) plugin to convert APIs into MCP tools, proxy MCP servers, expose MCP tools to AI clients, and observe MCP traffic.

## Agents

Use the [AI A2A Proxy](/plugins/ai-a2a-proxy/) (`ai-a2a-proxy`) plugin to add observability and gateway control to Agent-to-Agent (A2A) protocol traffic. The plugin supports both JSON-RPC and REST bindings.

## Consumers, Consumer Groups, and Vaults

Access control and secret management on-prem use the same {{site.base_gateway}} objects as any other Gateway configuration, so there's no AI-specific setup. Use the existing {{site.base_gateway}} documentation:

* [Consumers](/gateway/entities/consumer/): Authenticate the clients that call your AI routes.
* [Consumer Groups](/gateway/entities/consumer-group/): Apply shared rate limits and policies to groups of Consumers.
* [Vaults](/gateway/entities/vault/): Store and reference provider credentials.
