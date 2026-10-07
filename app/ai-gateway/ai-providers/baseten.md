---
title: "Baseten provider"
layout: reference
content_type: reference
description: Reference for supported capabilities and configuration for the Baseten provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/baseten/

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
  ai-gateway: '2.3'

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
  - text: Baseten Model APIs
    url: https://docs.baseten.co/inference/model-apis/overview
---

<!--
TODO(reviewer), AI-192 open questions to resolve before GA:
1. Non-streaming usage: Baseten documents `usage` as present only when streaming with `include_usage`.
   Confirm non-streaming responses return usage so token statistics and cost tracking work. If they
   don't, add a statistics_logging limitation to providers.yaml and a line under Limitations.
2. Streaming usage: Baseten defaults `stream_options.include_usage` and `continuous_usage_stats` to true.
   Confirm the 2.3 streaming parser handles per-chunk usage without double-counting.
3. Embeddings at GA: dedicated BEI deployments expose `/sync/v1/embeddings`. If embeddings ship at GA,
   flip `embeddings` to supported in providers.yaml and add a dedicated-deployment embeddings example.
4. Request validation: Baseten rejects unknown request fields (`additionalProperties: false`).
   Confirm Kong doesn't inject fields Baseten rejects.
5. Icon: app/assets/icons/baseten.svg is a placeholder. Replace with the approved Baseten logo.
6. The AI Gateway 2.3 release isn't in app/_data/products/ai-gateway.yml yet. Confirm min_version
   resolves correctly once the release entry lands.
-->

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Baseten" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }} Model APIs or to your own dedicated {{ provider.name }} deployments.

{{ provider.name }} authenticates with an `Authorization` header that carries your Baseten API key:

{% entity_example %}
type: model-provider
data:
  display_name: Baseten Production
  name: my-baseten-account
  type: baseten
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $BASETEN_API_KEY
    secret: true
    description: "The API key used to connect to Baseten. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

{{site.ai_gateway}} sends the header value to {{ provider.name }} unchanged, so keys in Baseten's legacy `Api-Key <your-api-key>` format also work.

## Configure a {{ provider.name }} model

{{ provider.name }} supports the `generate` capability (chat completions), with and without streaming. Each [target](/ai-gateway/entities/ai-model/#targets) on the AI Model references the {{ provider.name }} provider and sets `config.type` to `baseten`. How you set the target `name` and `upstream_url` depends on whether the model runs on Baseten Model APIs or on a dedicated deployment.

### Model APIs

By default, {{site.ai_gateway}} sends requests to Baseten Model APIs at `https://inference.baseten.co/v1`. Set the target `name` to the model's org-qualified slug from the [Baseten model library](https://docs.baseten.co/inference/model-apis/overview), for example `deepseek-ai/DeepSeek-V4-Pro-0813` or `openai/gpt-oss-120b`:

{% entity_example %}
type: model
data:
  display_name: DeepSeek V4 Pro on Baseten
  name: deepseek-v4-pro
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /baseten
  targets:
    - name: deepseek-ai/DeepSeek-V4-Pro-0813
      provider: my-baseten-account
      config:
        type: baseten
{% endentity_example %}

### Dedicated deployments

To route to a model you deployed on {{ provider.name }}, set the target `upstream_url` to the deployment's full chat completions endpoint:

```text
https://model-<MODEL_ID>.api.baseten.co/environments/<ENVIRONMENT>/sync/v1/chat/completions
```
{:.no-copy-code}

Replace `<MODEL_ID>` with the model ID from your Baseten dashboard and `<ENVIRONMENT>` with the deployment environment, for example `production`. Set the target `name` to the model name your deployment serves. For engines that take a `--served-model-name` flag, such as vLLM, use that value:

```yaml
targets:
  - name: <SERVED_MODEL_NAME>
    provider: my-baseten-account
    config:
      type: baseten
      upstream_url: https://model-<MODEL_ID>.api.baseten.co/environments/production/sync/v1/chat/completions
```

The same API key authenticates to both Model APIs and dedicated deployments in your Baseten workspace, so one AI Model Provider can serve both kinds of target.

## Send a request

Clients call the AI Model's route with an OpenAI-compatible chat completions request. The `generate` capability appends `/chat/completions` to the route path, so for the Model APIs example, send requests to `/baseten/chat/completions` and set `model` to the AI Model's `name`:

<!-- TODO(reviewer): confirm the default model selector matches the AI Model name (`deepseek-v4-pro`) rather than the slash-containing target name. -->

<!-- vale off -->
{% validation request-check %}
url: /baseten/chat/completions
status_code: 200
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  model: deepseek-v4-pro
  messages:
    - role: user
      content: "Summarize the benefits of an AI gateway in one sentence."
{% endvalidation %}
<!-- vale on -->

To stream the response, add `"stream": true` to the request body.

## Limitations

* {{ provider.name }}'s Anthropic-compatible `/v1/messages` endpoint, embeddings, and the `/predict` and async inference APIs aren't available through the `baseten` provider.
* Baseten-specific request parameters, such as `continuous_usage_stats` and `grammar`, aren't AI Model or target configuration fields.
<!-- TODO(reviewer): confirm whether clients can pass Baseten-specific body fields and the `x-session-affinity` header through unchanged (AI-192 OQ6), and document it here if so. -->
