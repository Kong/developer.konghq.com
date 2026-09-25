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
  ai-gateway: '2.2'

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

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="TypeSafe AI" %}

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

## Configure a {{ provider.name }} model

{:.info}
> The `decisions` capability requires `formats: [{type: typesafe}]` on the AI Model. There's no OpenAI-translated equivalent for this capability, so the native format is required here, unlike for other passthrough providers.

{% entity_example %}
type: model
data:
  display_name: TypeSafe Jev
  name: jev-decisions
  type: model
  capabilities:
    - decisions
  formats:
    - type: typesafe
  config:
    route:
      paths:
        - /jev
  targets:
    - name: jev-latest
      provider: my-typesafe-account
      config:
        type: typesafe
{% endentity_example %}

With this configuration, requests reach the AI Model at `{route path}/v1/systemone`. For this example, the path is `/jev/v1/systemone`. See [Request and response shape](#request-and-response-shape) for the request and response body.

### Route a target to an alternate TypeSafe-compatible host

A target's `config.upstream_url` can point at a different host serving the same `Jev` model, for example, a provider that re-hosts TypeSafe models behind its own endpoint. Because credentials differ per host, configure a separate `typesafe`-type AI Model Provider for it:

{% entity_example %}
type: model-provider
data:
  display_name: Jev via OpenRouter
  name: my-openrouter-account
  type: typesafe
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $OPENROUTER_API_KEY
    secret: true
    description: "The API key used to connect to the OpenRouter-hosted Jev endpoint. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

Then add a second target on the same AI Model, referencing that provider and overriding `upstream_url`:

```yaml
targets:
  - name: jev-latest
    provider: my-typesafe-account
  - name: typesafe/jev-1.13-20260917
    provider: my-openrouter-account
    config:
      type: typesafe
      upstream_url: https://openrouter.ai/api/alpha/decisions
```

## Request and response shape

{{ provider.name }}'s API takes a `state` string plus a map of typed `questions`, and returns typed decisions instead of generated text. {{site.ai_gateway}} passes this body through to {{ provider.name }} unmodified. It doesn't translate the body into the OpenAI chat shape, because there's no `messages` or `input` field to translate. See [TypeSafe's API reference](https://docs.typesafe.ai/api) for the full request and response schema. 

The `model` field is required and must match the AI Model entity's `name`.

For example, this request:

<!-- vale off -->
{% validation request-check %}
url: /jev/v1/systemone
status_code: 200
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  state: "Help! My payouts have been failing for 3 days."
  model: jev-decisions
  questions:
    is_urgent:
      type: noul
      instructions: "Does this convey urgency?"
{% endvalidation %}
<!-- vale on -->

Returns a response similar to:

```json
{
  "model": "jev-1.13.0",
  "answers": {
    "is_urgent": {
      "type": "noul",
      "noul": 0.95
    }
  },
  "usage": {
    "input_tokens": 283,
    "output_tokens": 23
  }
}
```
{:.no-copy-code}

Note the following:

* The response's `answers` field is a map keyed by the question's name, not an array.
* Answers to `noul`-type questions don't carry a `confidence` or `probabilities` field. For that question type, the number itself is the belief.

## Limitations

* The `decisions` capability's request body doesn't carry an extractable prompt, so it doesn't support:
  * Guardrails
  * Semantic caching
  * Semantic routing
  * `ai-llm-as-judge`
  * Prompt-based rate limiting
  * `model_alias`
* {{ provider.name }}'s own API reference documents a `401` status for authentication failures, but a missing or invalid API key currently returns `403`. Error bodies arrive under a `detail` field rather than an `error` field.
