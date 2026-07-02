---
title: 'AI Response Transformer'
name: 'AI Response Transformer'

content_type: policy

publisher: kong-inc
description: 'Use an LLM service to transform the upstream HTTP(S) prior to forwarding it to the client'


products:
    - ai-gateway

works_on:
    - konnect

min_version:
  ai-gateway: '2.0'

topologies:
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-response-transformer.png

categories:
  - ai

tags:
  - ai
  - safety

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: AI Request Transformer Policy
    url: /ai-gateway/policies/ai-request-transformer/
---

The AI Response Transformer Policy uses a configured LLM service to transform the upstream's HTTP(S) response before returning it to the client.

It can also terminate or otherwise nullify the response if it fails a compliance or formatting check from the configured LLM service, for example.

This Policy supports `llm/v1/chat` requests for the same [LLM providers](/ai-gateway/ai-providers/) that {{site.ai_gateway}} supports.

It also uses the same LLM configuration and tuning parameters as an [AI Model](/ai-gateway/entities/ai-model/), in the [`config.llm`](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm) block.

The AI Response Transformer Policy runs **after** {{site.ai_gateway}} proxies to the upstream LLM service through an [AI Model](/ai-gateway/entities/ai-model/), allowing it to transform responses from any upstream LLM.

## How it works

{% include md/ai-gateway/v2/ai-response-transformer-diagram.md %}

1. The {{site.ai_gateway}} admin sets up an [`llm` configuration block](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm).
1. The {{site.ai_gateway}} admin sets up a `prompt`. 
The prompt becomes the `system` message in the LLM chat request, and provides transformation
instructions to the LLM for the returning upstream response body.
1. The client makes an HTTP(S) call.
1. After proxying the client's request to the backend, {{site.ai_gateway}} sets the entire response body as the 
`user` message in the LLM chat request, then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream response body.
1. The Policy returns early (`kong.response.exit`) and can handle gzip or chunked requests, similar to the [Forward Proxy](/plugins/forward-proxy/) plugin.

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

If the `parse_llm_response_json_instructions` parameter is set to `true`, {{site.ai_gateway}} will parse these instructions and set the specified response headers, response status code, and replacement response body.
This lets you change specific headers such as `Content-Type`, or throw errors from the LLM.

