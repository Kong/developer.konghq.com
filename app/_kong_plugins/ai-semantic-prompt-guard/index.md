---
title: 'AI Semantic Prompt Guard'
name: 'AI Semantic Prompt Guard'

content_type: plugin

tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Semantically and intelligently create allow and deny lists of topics that can be requested across every LLM.'


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

ai_gateway_url: "/ai-gateway/policies/ai-semantic-prompt-guard/"

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-semantic-prompt-guard.png

categories:
  - ai

tags:
  - ai
  - safety
  - dlp

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - semantic

related_resources:
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/v1/get-started/
  - text: AI Prompt Guard plugin
    url: /plugins/ai-prompt-guard/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: AI Semantic Cache plugin
    url: /plugins/ai-semantic-cache/
  - text: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-semantic-prompt-guard-plugin/
  - text: Embedding-based similarity matching in {{site.ai_gateway}} plugins
    url: /ai-gateway/v1/semantic-similarity/

faqs:
  - q: Does the AI Semantic Prompt Guard plugin support multilingual input?
    a: Yes, the AI Semantic Prompt Guard plugin supports multilingual input. Support depends on the capabilities of the configured [embedding model](/plugins/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider). The plugin sends raw UTF-8 text to the embedding provider supported by {{site.ai_gateway}} (for example, Azure, Bedrock, Gemini, Hugging Face, Mistral, or OpenAI). Similarity scores for the same prompt can differ by language, so test the embedding model with the languages your users send. See [Known limitations](#known-limitations).
  - q: |
      How do I resolve the MemoryDB error `Number of indexes exceeds the limit`?
    a: |
      If you see the following error in the logs:

      ```sh
      failed to create memorydb instance failed to create index: LIMIT Number of indexes (11) exceeds the limit (10)
      ```

      This means that the hardcoded MemoryDB instance limit has been reached.
      To resolve this, create more MemoryDB instances to handle multiple {{page.name}} plugin instances.

next_steps:
  - text: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-gcp-model-armor-plugin/
---

The AI Semantic Prompt Guard plugin extends the [AI Prompt Guard](/plugins/ai-prompt-guard/) plugin by allowing you to permit or block prompts based on a list of similar prompts, helping to prevent misuse of text completion requests.

You can use a combination of `allow` and `deny` rules to maintain integrity and compliance when serving an LLM service using {{site.ai_gateway}}.

## How it works

The matching behavior is as follows:
* If any `deny` prompts are set and the request matches a prompt in the `deny` list, the caller receives a 403 response.
* If any `allow` prompts are set, but the request matches none of the allowed prompts, the caller also receives a 403 response.
* If any `allow` prompts are set and the request matches one of the `allow` prompts, the request passes through to the LLM.
* If there are both `deny` and `allow` prompts set, the `deny` condition takes precedence over `allow`. Any request that matches a prompt in the `deny` list will return a 400 response, even if it also matches a prompt in the `allow` list. If the request doesn't match a prompt in the `deny` list, then it must match a prompt in the `allow` list to be passed through to the LLM.

## Plugin scope

Don't apply {{page.name}} to the route that serves its own embedding requests.

The plugin calls an embedding model to compute semantic similarity.
By default, it sends that request directly to the embedding provider.
If you set [`config.embeddings.model.options.upstream_url`](./reference/#schema--config-embeddings-model-options-upstream-url) to a route on the same {{site.base_gateway}} instance, the embedding request goes through the gateway like any other request.
When the plugin is global, it also applies to that request, which triggers another embedding request, and so on.
The loop doesn't end, and every request returns an HTTP `500` error.

{:.warning}
> **Important:** When {{page.name}} is global and `upstream_url` points back to the same {{site.base_gateway}} instance, every request fails with an HTTP `500` error because of a circular embedding loop.

Use one of the following options to avoid the loop:

* **Scope the plugin to the routes or services it protects.** The embedding request then goes to a route that the plugin doesn't cover.
* **Send embedding requests directly to the embedding provider.** Set `upstream_url` to the provider's endpoint, or leave it unset. The request bypasses {{site.base_gateway}} routing, so you must protect the embedding endpoint at the infrastructure level.

## Vector databases

{% include_cached /plugins/ai-vector-db.md name=page.name %}

{% include_cached /plugins/ai-partials-vectordb-embeddings.md %}

### Using cloud authentication with Redis {% new_in 3.13 %}

{% include_cached /plugins/redis/redis-cloud-auth.md tier=page.tier %}

{% include_cached /plugins/redis/enterprise.md name=page.name heading_level=3 redis_group="vectordb" %}

## Known limitations

{:.warning}
> Denied-topic matching compares the [embedding model](/plugins/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider) similarity score of a prompt to the `deny` prompts, and scores for the same prompt can differ by language.
> A prompt in another language can fall below the similarity threshold and bypass a `deny` prompt.
> Test the embedding model with the languages your users send.
> Combine the {{page.name}} plugin with other controls to block content.
