---
title: 'AI Semantic Response Guard'
name: 'AI Semantic Response Guard'

content_type: policy
tier: ai_gateway_enterprise

publisher: kong-inc
description: 'Permit or block prompts based on semantic similarity to known LLM responses, preventing misuse of llm/v1/chat or llm/v1/completions requests'

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

related_resources:
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/
  - text: AI Prompt Guard
    url: /ai-gateway/policies/ai-prompt-guard/
  - text: AI Semantic Prompt Guard
    url: /ai-gateway/policies/ai-semantic-prompt-guard/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: AI Semantic Cache
    url: /ai-gateway/policies/ai-semantic-cache/
  - text: Use AI Semantic Response Guard to govern your LLM traffic
    url: /how-to/use-ai-semantic-response-guard-plugin/
  - text: Embedding-based similarity matching in {{site.ai_gateway}} AI Policies
    url: /ai-gateway/semantic-similarity/

icon: ai-semantic-response-guard.png

categories:
 - ai
tags:
 - ai
 - safety
 - dlp

next_steps:
  - text: Use AI Semantic Prompt Guard AI Policy to govern your LLM traffic
    url: /how-to/use-ai-semantic-prompt-guard-plugin/
  - text: Use AI Prompt Response AI Policy to govern your LLM traffic
    url: /how-to/use-ai-prompt-response-plugin/
  - text: Use AI Prompt Guard AI Policy to govern your LLM traffic
    url: /how-to/use-ai-prompt-guard-plugin/
---

The AI Semantic Response Guard AI Policy filters LLM responses based on semantic similarity to predefined rules, helping prevent unwanted or unsafe responses when serving `llm/v1/chat`, `llm/v1/completions`, or `llm/v1/embeddings` requests through {{site.ai_gateway}}.

You can use a combination of `allow` and `deny` response rules to maintain integrity and compliance when returning responses from an LLM service.

## How it works

The AI Policy analyzes the semantic content of the full LLM response before it is returned to the client. The matching behavior is as follows:

* If any `deny_responses` are set and the response matches a pattern in the deny list, the response is blocked with a `403 Forbidden`.
* If any `allow_responses` are set, but the response matches none of the allowed patterns, the response is also blocked with a `403 Forbidden`.
* If any `allow_responses` are set and the response matches one of the allowed patterns, the response is permitted.
* If both `deny_responses` and `allow_responses` are set, the `deny` condition takes precedence. A response that matches a deny pattern will be blocked, even if it also matches an allow pattern. If the response does not match any deny pattern, it must still match an allow pattern to be permitted.

## Response processing

To enforce these rules, the plugin:

1. Disables streaming (`stream=false`) to ensure the full response body is buffered before analysis.
2. Intercepts the response body using the `guard-response` filter.
3. Extracts response text, supporting JSON parsing of multiple LLM formats and gzipped content.
4. Generates embeddings for the extracted text.
5. Searches the vector database (Redis, Pgvector, or other) against configured `allow_responses` or `deny_responses`.
6. Applies the decision rules described above.

{:.info}
> If a response is blocked or if a system error occurs during evaluation, the plugin returns a `403 Forbidden` to the client without exposing that the AI Semantic Response Guard blocked it.

{% include_cached md/ai-gateway/v2/vectordb-embeddings.md %}

## Vector databases

{% include_cached md/ai-gateway/v2/ai-vector-db.md name=page.name %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}
