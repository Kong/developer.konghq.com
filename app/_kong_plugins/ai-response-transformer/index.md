---
title: 'AI Response Transformer'
name: 'AI Response Transformer'

content_type: plugin

publisher: kong-inc
description: 'Use an LLM service to transform the upstream HTTP(S) prior to forwarding it to the client'


products:
    - gateway

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
  - ai-gateway

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
---

The AI Response Transformer plugin uses a configured LLM service transform the upstream's HTTP(S) response before returning it back to the client.
It can also be configured to terminate or otherwise nullify the response, if it fails a compliance or formatting check from the configured LLM service, for example.

This plugin supports `llm/v1/chat` requests for the same providers as the [AI Proxy plugin](/plugins/ai-proxy/).

It also uses the same configuration and tuning parameters as the AI Proxy plugin, under the [`config.llm`](/plugins/ai-request-transformer/reference/#schema--config-llm) block.

The AI Response Transformer plugin runs **after** the AI Proxy plugin, and **after** proxying to the upstream (backend) service, allowing it to also transform responses coming from a different LLM.

## How it works

{% include plugins/ai-transformer-diagram.md %}

1. The {{site.base_gateway}} admin sets up an `llm` configuration block, following the same 
[configuration format](/plugins/ai-proxy/reference/) as the AI Proxy plugin, 
and the same `driver` capabilities.
1. The {{site.base_gateway}} admin sets up a `prompt`. 
The prompt becomes the `system` message in the LLM chat request, and prepares the LLM with transformation
instructions for the returning upstream response body.
1. The user makes an HTTP(S) call.
1. After proxying the user's request to the backend, {{site.base_gateway}} sets the entire response body as the 
`user` message in the LLM chat request, then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream response body.
1. The plugin returns early (`kong.response.exit`) and can handle gzip or chunked requests, similarly to the Forward Proxy plugin.

### Adjusting response headers, status codes, and body

You can additionally instruct the LLM to respond in the following format, which lets you adjust the response headers, response status code, and response body:

```json
{
  "headers":
    {
      "new-header": "new-value"
    },
  "status": 201,
  "body": "new response body"
}
```

{{site.base_gateway}} will parse these instructions and set all given response headers, set the response status code, 
and set replacement response body. 
This lets you change specific headers such as `Content-Type`, or throw errors from the LLM.
