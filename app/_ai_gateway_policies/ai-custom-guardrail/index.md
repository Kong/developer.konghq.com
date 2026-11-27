---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Use a third-party guardrails service to validate requests and/or responses before forwarding them between clients and upstream LLMs'
categories:
   - ai
tags:
  - ai
  - safety
---

The AI Custom Guardrail Policy enforces introspection on both inbound requests and outbound responses handled by an [AI Model](/ai-gateway/entities/ai-model/). The Policy can be attached to an AI Model, [AI Consumer](/ai-gateway/entities/ai-consumer/), [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/), or applied globally (see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes)). It can integrate with any HTTP-based guardrail service. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

## How it works

The AI Custom Guardrail Policy can be applied to:
* Input data (requests)
* Output data (responses)
* Both input and output data

Here's how it works if you apply it to both requests and responses:

1. The AI Custom Guardrail Policy intercepts the request and sends the request body to the guardrail service.
   - The guardrail service analyzes the request against configured moderation categories and allows or blocks the request.
1. If allowed, the request is forwarded upstream by the AI Model.
1. On the way back, the Policy intercepts the response and sends the response body to the guardrail service.
   - The guardrail service analyzes the response against configured moderation categories and allows or blocks the response.
1. If allowed, the response is forwarded to the client.

{% include_cached md/ai-gateway/v2/guardrail-flow-diagram.md name=page.name service="Guardrail service" masking=true %}

## Message selection

{% include_cached md/ai-gateway/v2/guardrail-message-selection.md policy="ai-custom-guardrail" %}

### Masking

When you set `allow_masking`, the guardrail service returns one masked text for the whole request, so the Policy needs exactly one message to write that text back into.
Select either `user` or `tool_result`, with `message_countback: 1`:

```yaml
config:
  allow_masking: true
  message_selection:
    user:
      message_countback: 1
```


You can't mask `system`. You can't mask the following keys either, as they don't have a single text field to write into, and the Policy never rewrites the system prompt:

* `assistant`
* `tool_call`
* `reasoning` 

{{site.ai_gateway}} rejects a configuration that selects one of these keys, more than one key, or more than one message when you save it.
To mask across several messages, keep using the legacy fields.


## Text chunking

{% include_cached md/ai-gateway/v2/guardrail-chunking.md window=10000 audit=true streaming=true %}

To mask content, set `response.mask` to a template that renders the masked text of a part, for example `$(resp.maskedContent)`.
An empty rendering means the part holds nothing to mask, and the part keeps its own text. Masking has three requirements:

* `allow_masking` must be `true`.
* `text_source` must be `last_message`, because the Policy writes the masked text back into that one message.
* `chunk_overlap` must be `0`, because a masked part can't repeat.

## Configuration

To configure the AI Custom Guardrail Policy to work with your guardrail service, you must define your guardrail vendor API's required parameters under [`config.params`](./reference/#schema--config-params). The key is the parameter name, and the value can be a string or a Lua expression.

Additionally, the following built-in variables are available in Lua expressions. They can be used as arguments in functions, but not in the function body:
* `$(source)`: The current phase on which the Policy is running. The value is `INPUT` if the Policy is inspecting the request, and `OUTPUT` if it's inspecting the response.
* `$(conf)`: A Lua table that corresponds to the Policy's config field, meaning it has the same values as the Policy's configuration, which allows to access sub-fields under `config`.
* `$(content)`: The text content being inspected, extracted from the request body in the `INPUT` phase and the response body in the `OUTPUT` phase.
* `$(resp)`:  The response from the guardrail service. 
   
   {:.warning}
   > This variable is a Lua table corresponding to the request body if the AI Custom Guardrail Policy is inspecting the request, but it's a string when inspecting the response. Make sure to configure your functions accordingly.

### Request

The [`config.request`](./reference/#schema--config-request) field is used to configure the request that will be sent to your guardrail service. You can set the URL, request body, headers, query parameters, and authentication. You can use the parameters defined under [`config.params`](./reference/#schema--config-params) using the following syntax: `$(conf.params.<PARAM_KEY>)`.

### Response

The [`config.response`](./reference/#schema--config-response) field is used to define how to parse the response received by the guardrail service. 

You must define:
* [`config.response.block`](./reference/#schema--config-response-block)
* [`config.response.block_message`](./reference/#schema--config-response-block-message)

These fields can be defined using functions defined in [`config.functions`](./reference/#schema--config-functions), Lua expressions, or strings. For example, to use the value of a field named `action` in the guardrail service's response body, you can set `config.response.block` to `$(resp.action)`.

### Metrics

The [`config.metrics`](./reference/#schema--config-metrics) field allows you to define metrics to be logged by {{site.base_gateway}}. 

The following standard metrics are available:
* `block_reason`: The reason why the request or response was blocked.
* `block_details`: Additional details about the blocked request or response.
* `masked`: Whether content was masked in the request or response.

The values can be set to Lua expressions. You can also use the [`config.custom_metrics`](./reference/#schema--config-custom-metrics) field to define additional metrics.

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}
