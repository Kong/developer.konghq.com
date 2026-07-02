---
title: 'AI Semantic Prompt Guard'
name: 'AI Semantic Prompt Guard'

content_type: policy

publisher: kong-inc
description: 'Semantically and intelligently create allow and deny lists of topics that can be requested across every LLM.'


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
    a: Yes, the AI Semantic Prompt Guard Policy supports multilingual input—depending on the capabilities of the configured [embedding model](/ai-gateway/policies/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider). The AI Policy sends raw UTF-8 text to the embedding provider supported by {{site.ai_gateway}} (such as Azure, Bedrock, Gemini, Hugging Face, Mistral, or OpenAI). As long as the model supports multiple languages, semantic comparisons and rule enforcement will work as expected without requiring additional policy configuration.
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

The matching behavior is as follows:
* If any `deny` prompts are set and the request matches a prompt in the `deny` list, the caller receives a 403 response.
* If any `allow` prompts are set, but the request matches none of the allowed prompts, the caller also receives a 403 response.
* If any `allow` prompts are set and the request matches one of the `allow` prompts, the request passes through to the LLM.
* If there are both `deny` and `allow` prompts set, the `deny` condition takes precedence over `allow`. Any request that matches a prompt in the `deny` list will return a 400 response, even if it also matches a prompt in the `allow` list. If the request doesn't match a prompt in the `deny` list, then it must match a prompt in the `allow` list to be passed through to the LLM.

## Vector databases

{% include_cached md/ai-gateway/v2/ai-vector-db.md name=page.name %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}
