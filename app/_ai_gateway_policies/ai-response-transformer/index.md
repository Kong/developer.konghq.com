---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: AI Request Transformer Policy
    url: /ai-gateway/policies/ai-request-transformer/
---

The AI Response Transformer Policy uses a configured LLM service to transform the upstream LLM provider's response before returning it to the client.

It can also terminate or otherwise nullify the response if it fails a compliance or formatting check from the configured LLM service.

This Policy supports `llm/v1/chat` requests and can be tuned by setting the parameters in the [`config.llm`](/ai-gateway/policies/ai-request-transformer/reference/#schema--config-llm) block.

The AI Response Transformer Policy runs **after** {{site.ai_gateway}} proxies to the upstream LLM service through an [AI Model](/ai-gateway/entities/ai-model/), allowing it to transform responses from any upstream LLM.

## How it works

{% include md/ai-gateway/v2/ai-response-transformer-diagram.md %}

The {{site.ai_gateway}} admin sets up an [`llm` configuration block](/ai-gateway/policies/ai-response-transformer/reference/#schema--config-llm) and a [`prompt`](/ai-gateway/policies/ai-response-transformer/reference/#schema--config-prompt) for the LLM service used to transform requests.

The prompt becomes the `system` message in the LLM chat request, and provides transformation
instructions to the LLM for the returning upstream response body.

1. The client makes an HTTP(S) call.
2. The {{site.ai_gateway}} sends the transformed request to the upstream LLM provider or uses the [AI Request Transformer Policy](/ai-gateway/policies/ai-request-transformer/).
3. The the upstream LLM provider returns a response to {{site.ai_gateway}}.
4. The AI Response Transformer policy sets the entire response body as the  `user` message in an LLM chat request, then sends it to the configured LLM service.
5. The LLM service returns a response `assistant` message, which is subsequently set as the upstream response body.
6. The Policy returns early (`kong.response.exit`) and can handle gzip or chunked requests, similar to the [Forward Proxy](/ai-gateway/policies/forward-proxy/) policy.

### Adjusting response headers, status codes, and body

You can additionally instruct the LLM service to respond in the following format, which lets you adjust the response headers, response status code, and response body:

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

