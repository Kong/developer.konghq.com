---
title: 'AI Response Transformer'
name: 'AI Response Transformer'

content_type: plugin

publisher: kong-inc
description: 'Use an LLM service to transform the upstream HTTP(S) prior to forwarding it to the client'


products:
  - gateway
  - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-response-transformer.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: Transform a response using OpenAI
    url: /how-to/transform-a-response-with-ai/
  - text: AI Request Transformer plugin
    url: /plugins/ai-request-transformer/
---

The AI Response Transformer plugin uses a configured LLM service to transform the upstream's HTTP(S) response before returning it to the client.
It can also terminate or otherwise nullify the response if it fails a compliance or formatting check from the configured LLM service, for example.

This plugin supports `llm/v1/chat` requests for the same providers as the [AI Proxy plugin](/plugins/ai-proxy/).

It also uses the same configuration and tuning parameters as the AI Proxy plugin, in the [`config.llm`](/plugins/ai-request-transformer/reference/#schema--config-llm) block.

The AI Response Transformer plugin runs **after** the AI Proxy plugin, and **after** proxying to the upstream service, allowing it to also transform responses coming from a different LLM.

## How it works

{% include plugins/ai-transformer-diagram.md %}

1. The {{site.base_gateway}} admin sets up an [`llm` configuration block](/plugins/ai-request-transformer/reference/#schema--config-llm).
1. The {{site.base_gateway}} admin sets up a `prompt`. 
The prompt becomes the `system` message in the LLM chat request, and provides transformation
instructions to the LLM for the returning upstream response body.
1. The client makes an HTTP(S) call.
1. After proxying the client's request to the backend, {{site.base_gateway}} sets the entire response body as the 
`user` message in the LLM chat request, then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream response body.
1. The plugin returns early (`kong.response.exit`) and can handle gzip or chunked requests, similar to the [Forward Proxy](/plugins/forward-proxy/) plugin.

### Adjusting response headers, status codes, and body

You can additionally instruct the LLM to respond in the following format, which lets you adjust the response headers, response status code, and response body:

```json
{
  "headers":
    {
      "new-header": "new-value"
    }
}
```

If the `parse_llm_response_json_instructions` parameter is set to `true`, {{site.base_gateway}} will parse these instructions and set the specified response headers, response status code, and replacement response body. 
This lets you change specific headers such as `Content-Type`, or throw errors from the LLM.
