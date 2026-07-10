---
title: "Migrate your models to {{site.ai_gateway}} 2.x"
content_type: reference
layout: reference

works_on:
 - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai

min_version:
  ai-gateway: '2.0'

description: This guide walks you through moving your models to the new {{site.ai_gateway}} AI Model and AI Provider entities.
---

In {{site.ai_gateway}} version 1.x, a model is an [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin attached to a Service and Route. The plugin holds the provider, credentials, route type, model options, and load balancer all in one place. 

In {{site.ai_gateway}} version 2.x, that single plugin becomes two entities: an [AI Provider](/ai-gateway/entities/ai-provider) that holds the upstream connection and credentials, and an [AI Model](/ai-gateway/entities/ai-model/) that holds routing, capabilities, format, load balancing, and one or more `targets` that each reference an AI Provider.

## Converting configuration files

The following `deck` snippet defines a chat model that load balances across two OpenAI models using round-robin:

```
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: openai-chat
  url: https://api.openai.com:443
  routes:
  - name: openai-chat-route
    paths:
    - /chat
  plugins:
  - name: ai-proxy-advanced
    config:
      balancer:
        algorithm: round-robin
      targets:
      - route_type: llm/v1/chat
        weight: 70
        auth:
          header_name: Authorization
          header_value: Bearer {vault://openai-vault/api-key}
        model:
          provider: openai
          name: gpt-4o
          options:
            max_tokens: 512
            temperature: 0.7
      - route_type: llm/v1/chat
        weight: 30
        auth:
          header_name: Authorization
          header_value: Bearer {vault://openai-vault/api-key}
        model:
          provider: openai
          name: gpt-4o-mini
          options:
            max_tokens: 512
            temperature: 0.7
```

The converter splits the credentials into an AI Provider and the routing and balancing into an AI Model. The route_type of `llm/v1/chat` becomes `capabilities: [generate]` with an `openai` format, and each target references the AI Provider by name.

```
# ai-gateway.yaml (AI Gateway v2 entity model)
providers:
- type: openai
  name: openai-prod
  display_name: OpenAI Production
  config:
    auth:
      # Carried over from the v1 target auth block.
      header_name: Authorization
      header_value: Bearer {vault://openai-vault/api-key}

models:
- type: model
  name: openai-chat
  display_name: OpenAI Chat
  enabled: true
  capabilities:
  - generate
  formats:
  - type: openai
  access:
    acls:
      allow: []
      deny: []
  policies: []
  config:
    route:
      paths:
      - /chat
    model:
      name_header: true
    balancer:
      algorithm: round-robin
  targets:
  - name: gpt-4o
    provider: openai-prod
    weight: 70
    config:
      type: openai
      max_tokens: 512
      temperature: 0.7
  - name: gpt-4o-mini
    provider: openai-prod
    weight: 30
    config:
      type: openai
      max_tokens: 512
      temperature: 0.7
```

## What to check on AI Models

- Capabilities and format: confirm the `route_type` was decomposed correctly. For example, `llm/v1/chat` maps to `capabilities: [generate]` and `formats: [{type: openai}]`, while `llm/v1/embeddings` maps to `capabilities: [embeddings]`. Asynchronous file and batch route types map to a Model with `type: api` and `capabilities` of `files` or `batches`.
- Provider reuse: if several version 1.x targets shared the same provider and credentials, the converter should produce a single AI Provider that all targets reference. Deduplicate any near-identical AI Providers it could not merge.
- Model options: per-target options such as `max_tokens`, `temperature`, `top_p`, and `top_k` move into each `targets[].config`, keyed by the provider `type`.
- Auth override: if you relied on `config.targets.auth.allow_override` in version 1.x, set `allow_auth_override: true` on the corresponding target in version 2.x.
- Vector database and embeddings: `config.vectordb` and `config.embeddings` settings carry over onto the AI Model config under the `balancer` config, keeping the same Redis or pgvector strategy.
