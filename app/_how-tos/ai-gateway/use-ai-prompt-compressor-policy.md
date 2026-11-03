---
title: Reduce prompt size with the AI Prompt Compressor Policy
permalink: /ai-gateway/use-ai-prompt-compressor-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Prompt Compressor Policy
    url: /ai-gateway/policies/ai-prompt-compressor/
  - text: AI RAG Injector Policy
    url: /ai-gateway/policies/ai-rag-injector/
  - text: Model cost management
    url: /ai-gateway/model-cost-management/

description: Use the AI Prompt Compressor Policy with the LLMLingua compressor service to shrink prompts before they reach the LLM, and use LLMLINGUA tags to compress only part of a prompt.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-model-provider
  - ai-model
  - ai-policy

tags:
  - ai
  - performance

tldr:
  q: How do I reduce the number of tokens sent to an LLM without rewriting my prompts?
  a: Run the LLMLingua compressor service, then attach an AI Prompt Compressor Policy to an AI Model. The Policy compresses prompts by a ratio that depends on their length, and compresses only the sections you wrap in `<LLMLINGUA>` tags.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
    - title: AI Prompt Compressor service
      include_content: md/ai-gateway/v2/prereqs/ai-prompt-compressor
      icon_url: /assets/icons/third-party/docker.svg

cleanup:
  inline:
    - title: Remove the AI Prompt Compressor service
      content: |
        ```bash
        docker rm -f compress-service
        ```
      icon_url: /assets/icons/third-party/docker.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Create the AI Model Provider, AI Model, and AI Prompt Compressor Policy

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/), an [AI Model](/ai-gateway/entities/ai-model/), and an [AI Prompt Compressor Policy](/ai-gateway/policies/ai-prompt-compressor/) that compresses prompts by ratio before the AI Model forwards them to OpenAI:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_policies:
  - ref: my-ai-prompt-compressor-policy
    name: my-ai-prompt-compressor-policy
    display_name: my-ai-prompt-compressor-policy
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: ai-prompt-compressor
    enabled: true
    global: false
    config:
      compressor_type: rate
      compressor_url: http://host.docker.internal:8080
      compression_ranges:
        - min_tokens: 20
          max_tokens: 100
          value: 0.8
        - min_tokens: 100
          max_tokens: 1000000
          value: 0.3
      stop_on_error: true
ai_gateway_models:
  - ref: my-gpt-4o
    name: my-gpt-4o
    display_name: my-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - my-gpt-4o
    capabilities: [generate]
    policies: [ !ref my-ai-prompt-compressor-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

Prompts under 20 tokens aren't compressed. Prompts of 20 to 100 tokens are compressed to 80% of their length, and longer prompts to 30%.

{:.info}
> If your {{site.ai_gateway}} data plane doesn't run in Docker, set `compressor_url` to `http://localhost:8080` instead.

## Validate configuration

Send a short prompt, then a long prompt with `<LLMLINGUA>` tags, and compare the `usage.prompt_tokens` value in each response.

{% navtabs "prompt-compressor-tests" %}
{% navtab "Short prompt" %}

A prompt under 20 tokens isn't compressed, so `usage.prompt_tokens` stays small and unchanged:

```bash
curl -s http://localhost:8000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: $OPENAI_AUTH_HEADER" \
  -d '{"model": "my-gpt-4o", "messages": [{"role": "user", "content": "What is DNS?"}]}'
```

The response reports `"prompt_tokens": 11`.

{% endnavtab %}
{% navtab "Long tagged prompt" %}

Create a long block of text and wrap it in `<LLMLINGUA>` tags. The Policy compresses only the tagged section and leaves the rest of the prompt as is:

```bash
CONTEXT=$(printf 'Kong Gateway is an API gateway that sits in front of upstream services and handles authentication, rate limiting, logging and traffic control through a plugin architecture. %.0s' {1..14})

curl -s http://localhost:8000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: $OPENAI_AUTH_HEADER" \
  -d "{\"model\": \"my-gpt-4o\", \"messages\": [{\"role\": \"user\", \"content\": \"<LLMLINGUA>$CONTEXT</LLMLINGUA> Summarize this in one sentence.\"}]}"
```

Without compression, this prompt is about 420 tokens. The response reports roughly 130 `prompt_tokens`, and the model still returns an accurate summary.

{% endnavtab %}
{% endnavtabs %}
