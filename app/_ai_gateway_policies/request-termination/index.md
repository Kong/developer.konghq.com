---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Terminate requests to your AI Models, AI Agents, and AI MCP Servers with a specific status code and response.'
categories:
  - traffic-control
tags:
  - traffic-control
  - ai
search_aliases:
  - request-termination
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

The Request Termination [AI Policy](/ai-gateway/entities/ai-policy/) terminates incoming requests with a status code and message that you define.
Use it to temporarily stop traffic to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), or to block a specific [AI Consumer](/ai-gateway/entities/ai-consumer/).

When the policy is enabled, every request within its scope is immediately terminated with the configured response.
You can also use the policy for debugging, by echoing the request back to the client with the [`config.echo`](/ai-gateway/policies/request-termination/reference/#schema--config-echo) parameter.

## Example use cases

The following table lists some common use cases for the Request Termination policy:

<!--vale off-->
{% table %}
columns:
  - title: "If you want to..."
    key: "if_you_want_to"
  - title: "Then see..."
    key: "then_see"
rows:
  - if_you_want_to: "Temporarily disable an AI Model <br><br> _For example, if the AI Model is under maintenance and clients keep retrying_"
    then_see: "[Block requests with an error message](/ai-gateway/policies/request-termination/examples/block-requests-with-error/)"
  - if_you_want_to: "Temporarily disable an AI Agent or AI MCP Server <br><br> _For example, if one entity is misbehaving while the rest of your {{site.ai_gateway}} traffic is healthy_"
    then_see: "[Block requests with an error message](/ai-gateway/policies/request-termination/examples/block-requests-with-error/)"
  - if_you_want_to: "Temporarily disable an AI Consumer or AI Consumer Group <br><br> _For example, if a consumer has excessive consumption_"
    then_see: "[Block requests with an error message](/ai-gateway/policies/request-termination/examples/block-requests-with-error/)"
  - if_you_want_to: "Debug erroneous requests in live systems using `config.echo`"
    then_see: "[Echo response back to client](/ai-gateway/policies/request-termination/examples/echo-response-to-client/)"
{% endtable %}
<!--vale on-->

## Scopes

Apply the Request Termination Policy globally to terminate all {{site.ai_gateway}} traffic on the data plane, or attach it to an AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group to terminate traffic for that entity only.

For an AI Consumer or AI Consumer Group, the policy takes effect only after the client authenticates.
A request without valid credentials is rejected by the authentication method before the policy runs.

For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

## Execution order

The Request Termination Policy has priority `2`, so only the Mocking and Post-Function Policies run after it.
Policies such as guardrails still run before termination, so they can consume calls or fail first.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).
