---
title: 'AI Semantic Response Guard'
name: 'AI Semantic Response Guard'

content_type: plugin

publisher: kong-inc
description: 'Permit or block LLM responses based on semantic similarity to predefined rules for chat, completions, and embeddings requests'

products:
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    ai-gateway: '2.0'

related_resources:
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/
  - text: AI Prompt Guard
    url: /ai-gateway/policies/ai-prompt-guard/
  - text: AI Semantic Prompt Guard
    url: /ai-gateway/policies/ai-semantic-prompt-guard/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI Semantic Cache
    url: /ai-gateway/policies/ai-semantic-cache/
  - text: Embedding-based similarity matching in {{site.ai_gateway}} AI Policies
    url: /ai-gateway/semantic-similarity/

icon: ai-semantic-response-guard.png

tags:
 - ai
 - safety
 - dlp
---

The AI Semantic Response Guard AI Policy filters LLM responses based on semantic similarity to predefined rules, helping prevent unwanted or unsafe responses when serving `/chat`, `/completions`, or `/embeddings` requests through {{site.ai_gateway}}.

You can use a combination of `allow` and `deny` response rules to maintain integrity and compliance when returning responses from an LLM service.

## How it works

The AI Policy analyzes the semantic content of the full LLM response before it is returned to the client. The matching behavior is as follows:

* If any `deny_responses` are set and the response matches a pattern in the deny list, the response is blocked with a `403 Forbidden`.
* If any `allow_responses` are set, but the response matches none of the allowed patterns, the response is also blocked with a `403 Forbidden`.
* If any `allow_responses` are set and the response matches one of the allowed patterns, the response is permitted.
* If both `deny_responses` and `allow_responses` are set, the `deny` condition takes precedence. A response that matches a deny pattern will be blocked, even if it also matches an allow pattern. If the response does not match any deny pattern, it must still match an allow pattern to be permitted.

## Response processing

To enforce these rules, the AI Semantic Response Guard Policy:

1. Disables streaming (`stream=false`) to ensure the full response body is buffered before analysis.
1. Intercepts the response body using the `guard-buffered-response` filter.
1. Extracts response text, supporting JSON parsing of multiple LLM formats and gzipped content.
1. Generates embeddings for the extracted text.
1. Searches the vector database (Redis or pgvector) against configured `allow_responses` or `deny_responses`.
1. Applies the decision rules described in [How it works](#how-it-works).

## Response selection

{% include_cached md/ai-gateway/v2/guardrail-message-selection.md subject="response" action="evaluates" example="the answer text without tool calls or reasoning" local=true %}

The Policy rejects the `user` and `system` keys.
The following details apply to responses:

* `tool_result` selects the output of tools that the provider runs on its own side. Tools that you run yourself answer in the next request, so they never appear in a response.
* The Policy doesn't support masking.
* The Policy supports `message_selection` only on routes that don't use passthrough mode.

### Streamed responses

A selection that only names `assistant` keeps streaming, and the Policy inspects the answer text as it arrives.
A selection that names `tool_call`, `reasoning`, or `tool_result` turns buffering on, because that content isn't available in the stream.
The Policy then guards the whole response once it is complete, so clients receive it only after it is complete.
A client that requested a stream receives a single JSON response instead of an event stream.
Choose `assistant` alone if you need the response to keep streaming.

{:.info}
> If a response is blocked or if a system error occurs during evaluation, the AI Policy returns a `403 Forbidden` to the client without exposing that the AI Semantic Response Guard blocked it.


## Text chunking

{% include_cached md/ai-gateway/v2/guardrail-chunking.md local=true subject="response" window=1500 streaming=true selection_anchor="response-selection" selection_label="Response selection" %}

The Policy compares one vector per part, so a long response becomes several comparisons.
It defaults to a smaller window because a long text dilutes the vector.
A part that matches a deny response blocks the text.
When the Policy lists allow responses, a part that matches none of them blocks the text, so a Policy with allow responses is stricter once the text is split.

## Detect without blocking

{% include_cached md/ai-gateway/v2/guardrail-continue-on-detection.md name=page.name logs_detection=true %}

## Vector databases

{% include_cached md/ai-gateway/v2/ai-vector-db.md name=page.name %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}