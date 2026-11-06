---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Send requests to a different host when the request headers match a rule, for AI Agents and AI MCP Servers.'
categories:
  - traffic-control
tags:
  - traffic-control
  - ai
search_aliases:
  - route-by-header
  - route by request header
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
---

The Route By Header [AI Policy](/ai-gateway/entities/ai-policy/) sends a request to a different host when the request headers match a rule you define.
Use it when requests for the same [AI Agent](/ai-gateway/entities/ai-agent/) or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) must be served by different hosts, depending on a header value that the client sends, such as a region or an environment.

## How does the Route By Header Policy work?

The Route By Header Policy evaluates the rules in [`config.rules`](/ai-gateway/policies/route-by-header/reference/#schema--config-rules). 
Each rule has a `condition` and an `upstream_name`.
The `condition` is a map of header names to header values.
The `upstream_name` is the host that receives the request when the condition matches.
If the hostname can't be resolved, {{site.ai_gateway}} returns a `503` response with the message `name resolution failed`.

{{site.ai_gateway}} evaluates the rules in the order you list them and applies the first rule that matches.
A rule matches when the request includes every header in the `condition` with the exact value.
Header names are case-insensitive, and header values are case-sensitive.

When a rule matches, {{site.ai_gateway}} replaces the host of the request with the `upstream_name` and sends the request to that host.
The request keeps its original path and method.
When no rule matches, {{site.ai_gateway}} sends the request to the URL configured on the AI Agent or AI MCP Server.

## Scopes

Apply the Route By Header Policy globally to evaluate the rules for all {{site.ai_gateway}} traffic on the data plane, or attach it to an AI Agent, an AI MCP Server, or an [AI Consumer](/ai-gateway/entities/ai-consumer/) to evaluate the rules for that entity only.
A global policy sends every request that includes a matching header, so choose header names and values that only your intended clients send.
An AI Consumer's rules apply after the client authenticates.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).
