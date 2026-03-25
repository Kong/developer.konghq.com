---
title: AI Custom Guardrail
name: AI Custom Guardrail

tier: ai_gateway_enterprise
content_type: plugin

publisher: kong-inc
description: 'Use a third-party guardrails service to validate requests and/or responses in the AI Proxy plugin before forwarding them between clients and upstream LLMs'


products:
    - ai-gateway
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.14'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - moderation

icon: ai-custom-guardrail.png

categories:
   - ai

related_resources:
  - text: Use the AI Custom Guardrail plugin with the Mistral AI Moderation API
    url: /how-to/use-ai-custom-guardrail-with-mistral/
---

The AI Custom Guardrail plugin enforces introspection on both inbound requests and outbound responses handled by the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin. It can integrate with any HTTP-based guardrail service. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

{% include plugins/ai-plugins-note.md %}

## How it works

The AI Custom Guardrail plugin can be applied to:
* Input data (requests)
* Output data (responses)
* Both input and output data

Here's how it works if you apply it to both requests and responses:

1. The plugin intercepts the request and sends the request body to the guardrail service.
   1. The guardrail service analyzes the request against configured moderation categories and allows or blocks the request.
1. If allowed, the request is forwarded upstream with the AI Proxy or AI Proxy Advanced plugin.
1. On the way back, the plugin intercepts the response and sends the response body to the guardrail service.
   1. The guardrail service analyzes the response against configured moderation categories and allows or blocks the response.
1. If allowed, the response is forwarded to the client.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
  autonumber
  participant Client
  participant custguardrail as AI Custom Guardrail plugin
  participant guardrail as Guardrail service
  participant proxy as AI Proxy/Advanced plugin
  participant llm as Upstream AI service

  client->>custguardrail:Send request
  custguardrail<<->>guardrail:Intercept & send request body
  guardrail->>guardrail:Check against moderation <br>categories and blocklists
  guardrail->>custguardrail: Allow or block request
  custguardrail->>proxy: Forward allowed request
  proxy->>llm: Process allowed request
  llm->>proxy: Return AI response
  proxy->>custguardrail: Forward response
  custguardrail->>guardrail: Intercept & send response body
  guardrail->>guardrail: Check against moderation <br>categories and blocklists
  guardrail->>custguardrail: Allow or block response
  custguardrail->>client: Forward allowed response
{% endmermaid %}
<!-- vale on -->

## Configuration

To configure the AI Custom Guardrail plugin to work with your guardrail service, you must define your Service's required parameters under [`config.params`](./reference/#schema--config-params). They key will be the parameter name, and the value can be a string or a Lua expression.

Additionally, the following built-in variables are available in Lua expression. They can be used as arguments in functions, but not in function body:
* `$(source)`: The current phase on which the plugin is running. The value is `INPUT` if the plugin is currently inspecting the request, and `OUTPUT` if it's inspecting the response.
* `$(conf)`: A Lua table that corresponds to the plugin’s config field, meaning it has the same values as the plugin’s configuration, which allows to access sub-fields under `config`.
* `$(content)`: The text content being inspected, extracted from the request body in the `INPUT` phase and the response body in the `OUTPUT` phase.
* `$(resp)`:  The response from the guardrail service. 
   {:.warning}
   > This variable is a Lua table corresponding to the request body if the plugin is inspecting the request, but it's string when inspecting the response. Make sure to configure your functions accordingly.

### Request

The [`config.request`](./reference/#schema--config-request) field is used to configure the request that will be sent to your guardrail service. You can set the URL, request body, headers, query parameters, and authentication. You can use the parameters defined under [`config.params`](./reference/#schema--config-params) using the following syntax: `$(conf.params.<PARAM_KEY>)`.

### Response

The [`config.response`](./reference/#schema--config-response) field is used to define how to parse the response received by the guardrail service. You must define:
* [`config.response.block`](./reference/#schema--config-response-block)
* [`config.response.block_message`](./reference/#schema--config-response-block-message)

These fields can be defined using functions defined in [`config.functions`](./reference/#schema--config-functions), Lua expressions, or strings. For example, to use the value of a field named `action` in the guardrail service's response body, you can set `config.response.block` to `$(resp.action)`.

### Metrics

The [`config.metrics`](./reference/#schema--config-metrics) field allows you to define metrics to be logged by {{site.base_gateway}}. The following standard metrics are available:
* `block_reason`: The reason why the request or response was blocked.
* `block_details`: Additional details about the blocked request or response.
* `masked`: Whether content was masked in the request or response.

The values can be set to Lua expressions. You can also use the [`config.custom_metrics`](./reference/#schema--config-custom-metrics) field to define additional metrics.