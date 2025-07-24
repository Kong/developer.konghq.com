---
title: 'AI Semantic Prompt Guard'
name: 'AI Semantic Prompt Guard'

content_type: plugin

tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Semantically and intelligently create allow and deny lists of topics that can be requested across every LLM.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

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

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - semantic

related_resources:
  - text: Get started with AI Gateway
    url: /ai-gateway/get-started/
  - text: AI Prompt Guard plugin
    url: /plugins/ai-prompt-guard/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: AI Semantic Cache plugin
    url: /plugins/ai-semantic-cache/
  - text: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-semantic-prompt-guard-plugin/

faqs:
  - q: Does the AI Semantic Prompt Guard plugin support multilingual input?
    a: Yes, the AI Semantic Prompt Guard plugin supports multilingual input—depending on the capabilities of the configured [embedding model](/plugins/ai-semantic-prompt-guard/reference/#schema--config-embeddings-model-provider). The plugin sends raw UTF-8 text to the embedding provider supported by AI Gateway (such as Azure, Bedrock, Gemini, Hugging Face, Mistral, or OpenAI). As long as the model supports multiple languages, semantic comparisons and rule enforcement will work as expected without requiring additional plugin configuration.

next_steps:
  - text: Use AI Semantic Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-semantic-prompt-guard-plugin/
  - text: Use AI Prompt Guard plugin to govern your LLM traffic
    url: /how-to/use-ai-prompt-guard-plugin/
---

The AI Semantic Prompt Guard plugin extends the [AI Prompt Guard](/plugins/ai-prompt-guard/) plugin by allowing you to permit or block prompts based on a list of similar prompts, helping to prevent misuse of `llm/v1/chat` or `llm/v1/completions` requests.

You can use a combination of `allow` and `deny` rules to maintain integrity and compliance when serving an LLM service using Kong AI Gateway.

## How it works

The matching behavior is as follows:
* If any `deny` prompts are set and the request matches a prompt in the `deny` list, the caller receives a 400 response.
* If any `allow` prompts are set, but the request matches none of the allowed prompts, the caller also receives a 400 response.
* If any `allow` prompts are set and the request matches one of the `allow` prompts, the request passes through to the LLM.
* If there are both `deny` and `allow` prompts set, the `deny` condition takes precedence over `allow`. Any request that matches a prompt in the `deny` list will return a 400 response, even if it also matches a prompt in the `allow` list. If the request doesn't match a prompt in the `deny` list, then it must match a prompt in the `allow` list to be passed through to the LLM.

