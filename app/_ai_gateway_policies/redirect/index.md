---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Stop requests to your AI Models, AI Agents, and AI MCP Servers and send callers to a new URL with a redirect response.'
categories:
  - traffic-control
tags:
  - traffic-control
  - ai
search_aliases:
  - redirect
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

The Redirect [AI Policy](/ai-gateway/entities/ai-policy/) redirects requests to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) to a new URL.
It stops the request before it reaches the upstream and returns a redirect response with a `Location` header.
Use it when an endpoint has moved to another host and you want existing clients to follow it.

## How does the Redirect Policy work?

Set [`config.location`](/ai-gateway/policies/redirect/reference/#schema--config-location) to the URL that callers should use.
{{site.ai_gateway}} returns that URL in the `Location` header of every request that matches the policy's scope.
Streaming and non-streaming requests receive the same response.

By default, the response status code is `301`.
Set [`config.status_code`](/ai-gateway/policies/redirect/reference/#schema--config-status-code) to use a different code, such as `302` for a temporary redirect, or `307` or `308` to tell clients to repeat the request with the same method.

## Keep the incoming path

Set [`config.keep_incoming_path`](/ai-gateway/policies/redirect/reference/#schema--config-keep-incoming-path) to `true` to keep the path and query string of the incoming request.
The `Location` header then combines `config.location` with that path and query string.
This is useful when the new host serves the same paths as the old one.

The incoming path is the full path that the caller requested, including the route prefix of the AI Model or AI MCP Server.

The following table shows the result for a request to `/my-model/chat/completions?a=1`:

{% table %}
columns:
  - title: "`config.location`"
    key: location
  - title: "`config.keep_incoming_path`"
    key: path
  - title: "`Location` header"
    key: result
rows:
  - location: "`https://new.example.com`"
    path: "`true`"
    result: "`https://new.example.com/my-model/chat/completions?a=1`"
  - location: "`https://new.example.com/base`"
    path: "`true`"
    result: "`https://new.example.com/base/my-model/chat/completions?a=1`"
  - location: "`https://new.example.com/base`"
    path: "`false`"
    result: "`https://new.example.com/base`"
{% endtable %}

## Scopes

Attach the Redirect Policy to an AI Model, AI Agent, or AI MCP Server to redirect only that entity.
You can also attach it to an AI Consumer or AI Consumer Group, or apply it globally.
AI Consumer and AI Consumer Group scopes apply after the caller authenticates.

* To move a single endpoint, attach the policy to that entity.
* To move specific customers, attach it to their AI Consumer or AI Consumer Group.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

{:.warning}
> A global Redirect Policy redirects every request on the data plane, including requests to entities that you didn't intend to move.
> Attach the policy to a single entity instead.
> To keep a global policy, use a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to limit when it runs.
