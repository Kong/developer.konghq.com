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

- An AI Model is under maintenance and clients keep retrying. Terminate its requests with a clear message, without removing its configuration.
- One AI Agent or AI MCP Server is misbehaving while the rest of your {{site.ai_gateway}} traffic is healthy. Disable only that entity.
- An AI Consumer or AI Consumer Group has excessive consumption. Block it until the usage is resolved.
- A request fails in production and you can't tell why. Echo the request back to the client to inspect it.

## Terminate requests with a custom response

Set [`config.status_code`](/ai-gateway/policies/request-termination/reference/#schema--config-status-code) to the HTTP status code to return, and [`config.message`](/ai-gateway/policies/request-termination/reference/#schema--config-message) to the response message.
The default status code is `503`.

The following example blocks requests with a `401` status code and a custom message:

{% entity_example %}
type: policy
data:
  name: block-requests
  display_name: Block requests with an error message
  type: request-termination
  global: true
  config:
    status_code: 401
    message: Error - Authentication required
formats:
  - konnect-api
{% endentity_example %}

To return a raw response instead of a JSON message, set [`config.body`](/ai-gateway/policies/request-termination/reference/#schema--config-body) and [`config.content_type`](/ai-gateway/policies/request-termination/reference/#schema--config-content-type).
The `body` and `message` parameters are mutually exclusive.

## Trigger the policy on a header

Set [`config.trigger`](/ai-gateway/policies/request-termination/reference/#schema--config-trigger) to an HTTP header name to terminate only requests that include that header.
Requests without the header pass through unchanged.

The following example terminates only requests that include the `X-Block-Request` header:

{% entity_example %}
type: policy
data:
  name: block-on-header
  display_name: Block requests with a header
  type: request-termination
  global: true
  config:
    status_code: 401
    message: Error - Authentication required
    trigger: X-Block-Request
formats:
  - konnect-api
{% endentity_example %}

## Debug requests with echo

Set [`config.echo`](/ai-gateway/policies/request-termination/reference/#schema--config-echo) to `true` to return a copy of the request to the client, instead of only the configured message.
Combine `echo` with `trigger` to debug requests on a live system without disturbing real traffic.

The echoed response includes the request and the internal routing details {{site.ai_gateway}} matched for it, so use `trigger` and remove the policy when you finish debugging.

The following example echoes the request back, but only for requests that include the `X-Debug` header:

{% entity_example %}
type: policy
data:
  name: echo-requests
  display_name: Echo requests with a header
  type: request-termination
  global: true
  config:
    status_code: 200
    echo: true
    trigger: X-Debug
formats:
  - konnect-api
{% endentity_example %}

## Scopes

Apply the Request Termination Policy globally to terminate all {{site.ai_gateway}} traffic on the data plane, or attach it to an AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group to terminate traffic for that entity only.
Global scope stops traffic for every AI Model, AI Agent, and AI MCP Server on the data plane.
To stop a single entity, attach the policy to that entity instead.

For an AI Consumer or AI Consumer Group, the policy takes effect only after the client authenticates.
A request without valid credentials is rejected by the authentication method before the policy runs.

For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

## Execution order

The Request Termination Policy has the lowest execution priority of the AI Policies, so it runs after the other policies that apply to the request.
Policies such as guardrails still run before termination, so they can consume calls or fail first.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).
