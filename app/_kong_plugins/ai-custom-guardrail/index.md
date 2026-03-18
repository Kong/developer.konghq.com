---
title: AI Custom Guardrail
name: AI Custom Guardrail

content_type: plugin

publisher: kong-inc
description: 'Use a third-party guardrails service to validate requests and/or responses in the AI Proxy plugin before forwarding them between clients and upstream LLMs.'


products:
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

# related_resources:
#   - text: How-to guide for the plugin
#     url: /how-to/guide/
---

The AI Custom Guardrail plugin enforces introspection on both inbound requests and outbound responses handled by the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin. It can integrate with any guardrail service. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

{% include plugins/ai-plugins-note.md %}

## How it works

To configure the AI Custom Guardrail plugin to work with your guardrail service, you must define you service's required parameters under [`config.params`](./reference/#schema--config-params). They key will be the parameter name, and the value can be a string or a Lua expression.

Once your parameters are defined, you must set the request and response configuration.

### Request

The [`config.request`](./reference/#schema--config-request) field is used to configure the request that will be sent to your guardrail service. You can set the URL, request body, headers, query parameters, and authentication. You cna use the parameters defined under [`config.params`](./reference/#schema--config-params) using the following syntax: `$(conf.params.<PARAM_KEY>)`.

### Response

The [`config.response`](./reference/#schema--config-response) field is used to define how to parse the response received by the guardrail service. You must define:
* [`config.response.block`](./reference/#schema--config-response-block)
* [`config.response.block_message`](./reference/#schema--config-response-block-message)

These fields can be defined using functions defined in [`config.functions`](./reference/#schema--config-functions), Lua expressions, or strings. For example, to use the value of a field named `action` in the guardrail service's response body, you can set `config.response.block` to `$(resp.action)`.