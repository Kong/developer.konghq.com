---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Permit or block LLM prompts based on semantic similarity to predefined allow and deny rules.'
categories:
  - ai
tags:
  - ai
  - safety
  - dlp
related_resources:
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/
  - text: AI Prompt Guard AI Policy
    url: /ai-gateway/policies/ai-prompt-guard/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI Semantic Cache AI Policy
    url: /ai-gateway/policies/ai-semantic-cache/
  - text: Embedding-based similarity matching in {{site.ai_gateway}} AI Policies
    url: /ai-gateway/semantic-similarity/

faqs:
  - q: Does the AI Semantic Prompt Guard Policy support multilingual input?
    a: Yes, the AI Semantic Prompt Guard Policy supports multilingual input. Support depends on the capabilities of the configured [embedding model](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider). The AI Policy sends raw UTF-8 text to an embedding provider supported by {{site.ai_gateway}} (for example, Azure, Bedrock, Gemini, Hugging Face, Mistral, or OpenAI). As long as the embedding model supports multiple languages, semantic comparisons and rule enforcement will work as expected without requiring additional policy configuration.
  - q: |
      How do I resolve the MemoryDB error `Number of indexes exceeds the limit`?
    a: |
      If you see the following error in the logs:

      ```sh
      failed to create memorydb instance failed to create index: LIMIT Number of indexes (11) exceeds the limit (10)
      ```

      This means that the hardcoded MemoryDB instance limit has been reached.
      To resolve this, create more MemoryDB instances to handle multiple {{page.name}} policy instances.
---

The AI Semantic Prompt Guard Policy enforces prompt governance using semantic similarity matching. It compares incoming requests against your configured allow and deny lists, preventing misuse of text completion requests.

You can use a combination of `allow` and `deny` rules to maintain integrity and compliance when serving an LLM service using {{site.ai_gateway}}.

## How it works

By default, the Policy only evaluates the latest message from the `user` role. To also match earlier turns in a multi-turn conversation, set [`config.rules.match_all_conversation_history`](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-rules-match-all-conversation-history) to `true`. To also match messages from roles other than `user`, set [`config.rules.match_all_roles`](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-rules-match-all-roles) to `true`.

The matching behavior is as follows:
* If any `deny` prompts are set and the request matches a prompt in the `deny` list, the request is blocked.
* If any `allow` prompts are set, but the request matches none of the allowed prompts, the request is also blocked.
* If any `allow` prompts are set and the request matches one of the `allow` prompts, the request passes through to the LLM.
* If there are both `deny` and `allow` prompts set, the `deny` condition takes precedence over `allow`. Any request that matches a prompt in the `deny` list is blocked, even if it also matches a prompt in the `allow` list. If the request doesn't match a prompt in the `deny` list, then it must match a prompt in the `allow` list to be passed through to the LLM.

## Rejection modes

The {{page.name}} Policy responds to a blocked request according to its rejection mode.
In the default `none` mode, the response is a `400` with the message `bad request`, which hides that a guardrail is in use.

{% include_cached md/ai-gateway/v2/guardrail-rejection-modes.md name=page.name request_only=true %}

For example, a request that matches a `deny` prompt returns the following response in `verbose` mode.
The `detail` field contains the prompt that matched and its `score`, which is the distance between the request and that prompt (a lower score means a closer match):

```json
{
  "error": {
    "type": "guardrail_rejected",
    "plugin": "ai-semantic-prompt-guard",
    "reason": "prompt pattern is blocked",
    "code": "GUARDRAIL_BLOCKED",
    "detail": {
      "matched_prompt": "How do I pick a lock?",
      "score": 0.12
    }
  }
}
```

To return this response, set [`config.rejection_mode`](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-rejection-mode) to `verbose`:

{% entity_example %}
type: policy
data:
  display_name: AI Semantic Prompt Guard - Verbose Rejection
  name: ai-semantic-prompt-guard
  type: ai-semantic-prompt-guard
  config:
    embeddings:
      auth:
        header_name: Authorization
        header_value: Bearer ${openai_api_key}
      model:
        provider: openai
        name: text-embedding-3-small
    vectordb:
      strategy: redis
      distance_metric: cosine
      threshold: 0.5
      dimensions: 1024
      redis:
        host: ${redis_host}
        port: 6379
    rules:
      deny_prompts:
      - How do I pick a lock?
    rejection_mode: verbose
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
    description: Your OpenAI API key.
  redis_host:
    value: $REDIS_HOST
    description: The host where your Redis instance is running.
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Detect without blocking

{% include_cached md/ai-gateway/v2/guardrail-continue-on-detection.md name=page.name logs_detection=true %}

## Policy scope

Don't apply the {{page.name}} Policy to the AI Model that serves its own embedding requests.

The Policy calls an embedding model to compute semantic similarity.
By default, it sends that request directly to the embedding provider.
If you set [`config.embeddings.model.options.upstream_url`](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-options-upstream-url) to an AI Model on the same {{site.ai_gateway}} instance, the embedding request goes through the data plane like any other request.
When the Policy is global, it also applies to that request, which triggers another embedding request, and so on.
The loop doesn't end, and every request returns an HTTP `500` error.

{:.warning}
> **Important:** When the {{page.name}} Policy is global and `upstream_url` points back to the same {{site.ai_gateway}} instance, every request fails with an HTTP `500` error because of a circular embedding loop.

Use one of the following options to avoid the loop:

* **Attach the Policy to the AI Models it protects.** Create it with `global: false` and reference it in each AI Model's `policies` array. The embedding request then goes to an AI Model that the Policy doesn't cover. See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).
* **Send embedding requests directly to the embedding provider.** Set `upstream_url` to the provider's endpoint, or leave it unset. The request bypasses {{site.ai_gateway}} routing, so you must protect the embedding endpoint at the infrastructure level.

## Vector databases

{% include_cached md/ai-gateway/v2/ai-vector-db.md name=page.name %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}

## Known limitations

{:.warning}
> Denied-topic matching compares the [embedding model](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider) similarity score of a prompt to the `deny` prompts, and scores for the same prompt can differ by language.
> A prompt in another language can fall below the similarity threshold and bypass a `deny` prompt.
> Test the embedding model with the languages your users send.
> Combine the {{page.name}} Policy with other controls to block content.
