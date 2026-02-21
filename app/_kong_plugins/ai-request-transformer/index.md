---
title: 'AI Request Transformer'
name: 'AI Request Transformer'

content_type: plugin

publisher: kong-inc
description: Use an LLM service to transform a client request body prior to proxying the request to the upstream server


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
icon: ai-request-transformer.png

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
  - text: Transform a request body using OpenAI
    url: /how-to/transform-a-client-request-with-ai/
  - text: AI Response Transformer plugin
    url: /plugins/ai-response-transformer/
---

The AI Request Transformer plugin uses a configured LLM service to transform a client request body before proxying the request upstream.

This plugin supports the same `llm/v1/chat` requests and providers as the [AI Proxy plugin](/plugins/ai-proxy/).

It also uses the same configuration and tuning parameters as the AI Proxy plugin, under the [`config.llm`](/plugins/ai-request-transformer/reference/#schema--config-llm) block.

The AI Request Transformer plugin runs **before** all of the [AI prompt](/plugins/?terms=ai%2520prompt) plugins and the
AI Proxy plugin, allowing it to also transform requests before sending them to a different LLM.

{:.warning}
> **Known failure mode: AI Request Transformer with AI Proxy**
>
> Chaining AI Request Transformer with AI Proxy or AI Proxy Advanced may fail for some providers, even though the same setup works with others.
>
> The reason is that the AI Request Transformer plugin forwards raw model output, and if the model does not produce strict JSON, the proxy chain cannot function correctly. This is not a bug in {{site.ai_gateway}} but a limitation of LLM behavior.

## How it works

{% include plugins/ai-transformer-diagram.md %}

1. The {{site.base_gateway}} admin sets up an [`llm` configuration block](/plugins/ai-request-transformer/reference/#schema--config-llm).
1. The {{site.base_gateway}} admin sets up a `prompt`.
The prompt becomes the `system` message in the LLM chat request, and prepares the LLM with transformation
instructions for the incoming client request body.
1. The client makes an HTTP(S) call.
1. Before proxying the client's request to the backend, {{site.base_gateway}} sets the entire request body as the
`user` message in the LLM chat request, and then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream request body.
1. The {{site.base_gateway}} sends the transformed request to the AI LLM service.
1. The AI LLM service returns a response to {{site.base_gateway}}.
1. The {{site.base_gateway}} sends the transformed response to the client.
