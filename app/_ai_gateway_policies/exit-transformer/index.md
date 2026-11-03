---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Customize the status code, body, and headers of responses that the data plane generates, such as authentication errors and unmatched route errors, using Lua functions.'
categories:
  - transformations
tags:
  - transformations
  - ai
search_aliases:
  - exit-transformer
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
---

The Exit Transformer [AI Policy](/ai-gateway/entities/ai-policy/) customizes the responses that {{site.ai_gateway}} generates itself.
You write one or more Lua functions that receive the response status, body, and headers, and return the values that {{site.ai_gateway}} sends to the client.
Use it to change a message or status code, add headers, or reshape the structure of an error response so that it matches the format your clients expect.

The Exit Transformer Policy only affects responses that {{site.ai_gateway}} generates, such as an authentication error or a response from the [Request Termination Policy](/ai-gateway/policies/request-termination/).
It doesn't change responses that come from an upstream LLM provider, an AI Agent, or an upstream MCP server.

{:.warning}
> Anyone who can create or edit an Exit Transformer Policy can run Lua code on your data plane, within the limits of the [sandbox](#sandboxing).

## Function syntax

Define the transformation in [`config.functions`](/ai-gateway/policies/exit-transformer/reference/#schema--config-functions).
Each entry is a string of Lua code that returns a function accepting `status`, `body`, and `headers` as parameters.
The return values become the response {{site.ai_gateway}} sends to the client:

```lua
return function(status, body, headers)
  return status, body, headers
end
```

{{site.ai_gateway}} passes the responses it generates for matched requests through the functions.
{{site.ai_gateway}} rejects a function that isn't valid Lua when you create the Policy, and the error includes the line and column of the syntax error.

The `status` argument is always present, but `body` and `headers` can be `nil`.
Check that they exist before you change them, and create them if they don't.

## Customize the response body and headers

The following example adds a prefix to the message of each response that {{site.ai_gateway}} generates for a matched request, and adds an `X-Exit-Transformed` header:

{% entity_example %}
type: policy
data:
  name: customize-exit-responses
  display_name: Customize exit responses
  type: exit-transformer
  global: true
  config:
    functions:
      - |-
        return function(status, body, headers)
          if type(body) == "table" then
            body.message = "Custom: " .. tostring(body.message)
          end
          headers = headers or {}
          headers["X-Exit-Transformed"] = "true"
          return status, body, headers
        end
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Handle unmatched routes

By default, the Policy transforms responses that {{site.ai_gateway}} generates after it matches a request to an entity.
To also transform responses for requests that match no route, enable [`config.handle_unknown`](/ai-gateway/policies/exit-transformer/reference/#schema--config-handle-unknown).

{:.warning}
> **Caution**: The `handle_unknown` parameter only works on a globally configured Policy.
> If you attach the Policy to an entity, such as an AI Model, {{site.ai_gateway}} doesn't transform responses for unmatched routes.

The following example replaces the default `404` response with a custom message:

{% entity_example %}
type: policy
data:
  name: customize-404-message
  display_name: Customize the 404 message
  type: exit-transformer
  global: true
  config:
    handle_unknown: true
    functions:
      - |-
        return function(status, body, headers)
          if status == 404 then
            local new_body = {
              error = true,
              status = status,
              message = "This is not the route you are looking for",
            }
            return status, new_body, headers
          end
          return status, body, headers
        end
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Scopes

Apply the Exit Transformer Policy globally to transform responses across all {{site.ai_gateway}} traffic, or attach it to an AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group to transform responses for that entity only.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

Authentication runs before an entity-scoped Policy.
If you attach the Exit Transformer Policy to an AI Model that uses an AI Auth Strategy, the Policy doesn't transform the authentication error that {{site.ai_gateway}} returns for a request without valid credentials.
To transform authentication errors, apply the Policy globally.

## Sandboxing

The Lua functions that you define in [`config.functions`](/ai-gateway/policies/exit-transformer/reference/#schema--config-functions) run in a sandboxed environment.
The [`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua) data plane setting controls the sandbox, and its default value is `strict`.
If a function needs a module or function that the `strict` sandbox restricts, set `untrusted_lua` to a less restrictive value, such as `lax` or `on`, in the data plane's `kong.conf` file.

{% include md/ai-gateway/v2/policies/sandbox.md %}
