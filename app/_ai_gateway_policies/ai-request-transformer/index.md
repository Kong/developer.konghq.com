---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: AI Response Transformer policy
    url: /ai-gateway/policies/ai-response-transformer/
---

The AI Request Transformer Policy uses a configured LLM service to transform a client request body before proxying the request upstream.

This Policy supports `llm/v1/chat` requests and can be tuned by setting the parameters in the [`config.llm`](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm) block.

The AI Request Transformer Policy runs **before** all of the [AI prompt](/ai-gateway/policies/?terms=ai%2520prompt) Policies, allowing it to also transform requests before sending them to a different LLM.

{:.warning}
> **Known failure mode: Chaining AI Request Transformer with the {{site.ai_gateway}}**
>
> Chaining AI Request Transformer with other {{site.ai_gateway}} operations may fail for some upstream providers, even though the same setup works correctly with other providers.
>
> The reason is that the AI Request Transformer Policy forwards raw model output, and if the LLM service model does not produce strict JSON, the proxy chain cannot function correctly. This is not a bug in {{site.ai_gateway}} but a limitation of LLM behavior.

{% comment %}
## How it works

{% include md/ai-gateway/v2/ai-transformer-diagram.md %}

The {{site.ai_gateway}} admin sets up an [`llm` configuration block](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm) and a [`prompt`](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-prompt) for the LLM service used to transform requests.

The prompt becomes the `system` message in the LLM chat request, and prepares the LLM with transformation
instructions for the incoming client request body.

1. The client makes an HTTP(S) call.
1. The {{site.ai_gateway}} creates a request to the LLM service using client's request body as the `user` message in the LLM chat request, and then sends it to the configured LLM service to be transformed.
1. The LLM service returns a response `assistant` message, containing the transformed user message. This is subsequently set as the request body for the upstream LLM provider.
1. The {{site.ai_gateway}} sends the transformed request to the upstream LLM provider.
1. The the upstream LLM provider returns a response to {{site.ai_gateway}}.
2. The {{site.ai_gateway}} sends the response to the [AI Response Transformer policy](/ai-gateway/policies/ai-response-transformer/) (as in figure 1), or directly to the client.
{% endcomment %}
