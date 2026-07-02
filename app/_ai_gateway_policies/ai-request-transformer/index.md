---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Request Transformer Policy uses a configured LLM service to transform a client request body before proxying the request upstream.

This Policy supports the same `llm/v1/chat` requests and providers as the [AI Model entity](/ai-gateway/entities/ai-model/).

It also uses the same configuration and tuning parameters as the AI Model entity, under the [`config.llm`](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm) block.

The AI Request Transformer Policy runs **before** all of the [AI prompt](/ai-gateway/policies/?terms=ai%2520prompt) Policies, allowing it to also transform requests before sending them to a different LLM.

{:.warning}
> **Known failure mode: Chaining AI Request Transformer with the {{site.ai_gateway}}**
>
> Chaining AI Request Transformer with the {{site.ai_gateway}} may fail for some providers, even though the same setup works with others.
>
> The reason is that the AI Request Transformer Policy forwards raw model output, and if the model does not produce strict JSON, the proxy chain cannot function correctly. This is not a bug in {{site.ai_gateway}} but a limitation of LLM behavior.

## How it works

{% include md/ai-gateway/v2/ai-transformer-diagram.md %}

1. The {{site.ai_gateway}} admin sets up an [`llm` configuration block](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm).
1. The {{site.ai_gateway}} admin sets up a `prompt`.
The prompt becomes the `system` message in the LLM chat request, and prepares the LLM with transformation
instructions for the incoming client request body.
1. The client makes an HTTP(S) call.
1. Before proxying the client's request to the backend, {{site.ai_gateway}} sets the entire request body as the
`user` message in the LLM chat request, and then sends it to the configured LLM service.
1. The LLM service returns a response `assistant` message, which is subsequently set as the upstream request body.
1. The {{site.ai_gateway}} sends the transformed request to the AI LLM service.
1. The AI LLM service returns a response to {{site.ai_gateway}}.
1. The {{site.ai_gateway}} sends the transformed response to the client.

