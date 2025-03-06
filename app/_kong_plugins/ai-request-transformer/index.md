---
title: 'AI Request Transformer'
name: 'AI Request Transformer'

content_type: plugin

publisher: kong-inc
description: Use an LLM service to transform a client request body prior to proxying the request to the upstream server


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
icon: ai-request-transformer.png

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
  - text: Transform a request body using OpenAI
    url: /how-to/transform-a-client-request-with-ai/
---

The AI Request Transformer plugin uses a configured LLM service to transform a client request body before proxying the request upstream.

This plugin supports `llm/v1/chat` requests for the same providers as the [AI Proxy plugin](/plugins/ai-proxy/).

It also uses the same configuration and tuning parameters as the AI Proxy plugin, under the [`config.llm`](/plugins/ai-request-transformer/reference/#schema--config-llm) block.

The AI Request Transformer plugin runs **before** all of the [AI prompt](/plugins/?terms=ai%2520prompt) plugins and the
AI Proxy plugin, allowing it to also transform requests before sending them to a different LLM.

## How it works

{% include plugins/ai-transformer-diagram.md %}

1. The {{site.base_gateway}} admin sets up an `llm` configuration block, following the same 
[configuration format](/plugins/ai-proxy/reference/) as the AI Proxy plugin, 
and the same `driver` capabilities.
1. The {{site.base_gateway}} admin sets up a `prompt`. 
The prompt becomes the `system` message in the LLM chat request, and prepares the LLM with transformation
instructions for the incoming client request body.
1. The client makes an HTTP(S) call.
1. Before proxying the client's request to the backend, {{site.base_gateway}} sets the entire request body as the 
`user` message in the LLM chat request, and then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream request body.
