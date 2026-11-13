---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Change the host, port, or path of requests that {{site.ai_gateway}} sends to your AI Agents and AI MCP Servers, using values from the incoming request.'
categories:
  - transformations
tags:
  - transformations
  - ai
search_aliases:
  - route-transformer-advanced
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

{:.warning}
> **AI Model scope:** The Route Transformer Advanced policy applies to AI Agents and AI MCP Servers.
> For an AI Model, {{site.ai_gateway}} sends the request to the provider's original host, port, and path.
> This applies when you attach the policy to the AI Model, attach it to an AI Consumer that calls the AI Model, or apply it globally.

The Route Transformer Advanced [AI Policy](/ai-gateway/entities/ai-policy/) changes the host, port, or path that {{site.ai_gateway}} uses when it sends a request to your [AI Agents](/ai-gateway/entities/ai-agent/) and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/).
Use it when the upstream location depends on something in the request, such as a header that the client sets, and the client can't build that location itself.
You can set each value to a fixed string or build it from the request with [templates](#templates).

When you set the path, the value replaces the whole upstream path, and {{site.ai_gateway}} keeps the query string.
When you set host or port, {{site.ai_gateway}} sends the new host and port in the `Host` header.

Set [`config.escape_path`](/ai-gateway/policies/route-transformer-advanced/reference/#schema--config-escape-path) to `true` when a template can produce characters that aren't valid in a URL path, such as spaces.
{{site.ai_gateway}} then URL-encodes those characters.

## Templates

The Route Transformer Advanced policy accepts values from the request in `config.host`, `config.port`, and `config.path`.
The following table lists the supported sources:

{% table %}
columns:
  - title: Source
    key: source
  - title: Template
    key: template
rows:
  - source: Header
    template: |
      * `$(headers.{HEADER-NAME})`
      * `$(headers["{HEADER-NAME}"])`
  - source: Query parameter
    template: |
      * `$(query_params.{QUERY-PARAM-NAME})`
      * `$(query_params["{QUERY-PARAM-NAME}"])`
  - source: Captured URI group
    template: |
      * `$(uri_captures.{GROUP-NAME})`
      * `$(uri_captures["{GROUP-NAME}"])`
  - source: Shared variable
    template: |
      * `$(shared.{VARIABLE-NAME})`
      * `$(shared["{VARIABLE-NAME}"])`
{% endtable %}

Captured URI groups are the named groups in a regular expression route path in the [`config.route.paths`](/ai-gateway/entities/ai-agent/#schema-aigateway-agent-config-route-paths) of an AI Agent.
Shared variables are values that another AI Policy stores in the shared request context, for example with a [`property` node](/ai-gateway/policies/datakit/#property-node-inputs).

Templates use the request as it is when the policy runs.
A header that the [Request Transformer](/ai-gateway/policies/request-transformer/) policy adds is available in a template, because Request Transformer runs first.

To use the text of a template literally, wrap it in quotes inside another template.
For example, `$('$(headers["x-test"])')` renders as the text `$(headers["x-test"])`.

### Advanced templates

{{site.ai_gateway}} evaluates the content of `$(...)` as a Lua expression, so you can use logical operators.
For example, the following template uses a captured URI group, then a query parameter, and then a default value:

```
$(uri_captures["user-id"] or query_params["user"] or "unknown")
```

You can combine constant text with templates.
For example, `/orders/$(headers["Custom-Path"])` adds a fixed prefix to a value from a header.

To run more logic, wrap a Lua function in an expression:

```
$((function() ... implementation here ... end)())
```

The following template uses the first three characters of a header value as the path:

```
/$((function()
    local value = headers["Custom-Path"]
    return value:sub(1, 3)
  end)())
```

{% include md/ai-gateway/v2/policies/sandbox.md %}

{:.info}
> Templates treat trailing whitespace and newlines as part of the value.
> Make sure that multi-line templates don't end with extra whitespace or newlines, because {{site.ai_gateway}} adds them to the generated value.

## Scopes

The Route Transformer Advanced policy supports global scope and entity scope.
Apply it globally to change the upstream destination of all AI Agent and AI MCP Server traffic on the data plane.
Attach it to an AI Agent, an AI MCP Server, or an [AI Consumer](/ai-gateway/entities/ai-consumer/) to change it for that entity only.
A Policy attached to an AI Consumer applies after the client authenticates.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

{:.warning}
> **Global scope:** A global Route Transformer Advanced Policy changes the destination of every request that matches, including requests to entities that you didn't plan to change.
> Add a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) to limit which requests the Policy changes.
