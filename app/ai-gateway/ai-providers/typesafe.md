---
title: "TypeSafe AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for TypeSafe AI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/typesafe/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="TypeSafe AI" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for {{ provider.name }}:

{% entity_example %}
type: model-provider
data:
  display_name: TypeSafe AI Production
  name: my-typesafe-account
  type: typesafe
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $TYPESAFE_API_KEY
    secret: true
    description: "The API key used to connect to TypeSafe AI. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a model target for {{ provider.name }}

{:.info}
> Only the `decisions` capability is supported for {{ provider.name }} targets.

A [target](/ai-gateway/entities/ai-model/#targets) is an entry in the `targets` array on the AI Model entity, not the AI Model Provider. Unlike providers such as Amazon SageMaker, a target routing to {{ provider.name }} has no provider-specific `config` fields — only the common target options apply: `name` (the upstream model, for example `jev-latest`), `provider`, and `weight`.

```yaml
targets:
  - name: jev-latest
    provider: my-typesafe-account
    weight: 100
```

## Request and response shape

{{ provider.name }}'s API takes a `state` string plus a map of typed `questions`, and returns typed decisions instead of generated text. {{site.ai_gateway}} passes this body through to {{ provider.name }} unmodified — it doesn't translate it into the OpenAI chat shape, because there's no `messages` or `input` field to translate. See [TypeSafe's API reference](https://docs.typesafe.ai/api) for the full request and response schema. A few details worth calling out:

* The response's `answers` field is a map keyed by the question's name, not an array.
* Answers to `noul`-type questions carry no `confidence` or `probabilities` — for that question type, the number itself is the belief.
* {{site.ai_gateway}} extracts `usage.input_tokens` and `usage.output_tokens` from the response for token-usage analytics, but because the request body carries no extractable prompt, this capability doesn't support guardrails, semantic caching, semantic routing, `ai-llm-as-judge`, prompt-based rate limiting, or `model_alias`.
