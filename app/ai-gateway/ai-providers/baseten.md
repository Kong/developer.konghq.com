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

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Baseten" %}

## Configure a {{ provider.name }} provider

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/).
You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }} Model APIs or to your own dedicated {{ provider.name }} deployments.

Create an AI Model Provider entity to store your Baseten API key.
{{ provider.name }} authenticates with an `Authorization` header:

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

The same API key authenticates to both Model APIs and dedicated deployments in your Baseten workspace.
One AI Model Provider can serve both kinds of target.

## Configure a {{ provider.name }} model

{{ provider.name }} supports the `generate` capability (chat completions), with and without streaming.
Each [target](/ai-gateway/entities/ai-model/#targets) on the AI Model references the {{ provider.name }} provider and sets `config.type` to `baseten`.
How you set the target `name` and `upstream_url` depends on whether the model runs on {{ provider.name }} Model APIs or on a dedicated deployment.

Use Model APIs for the shared, hosted models in the {{ provider.name }} model library.
Use a dedicated deployment when you need dedicated GPUs or control over hardware and scaling.

### Model APIs

By default, {{site.ai_gateway}} sends requests to {{ provider.name }} Model APIs at `https://inference.baseten.co/v1`.
Set the target `name` to the model's slug, which includes the organization prefix, from the [{{ provider.name }} model library](https://docs.baseten.co/inference/model-apis/overview).
For example, use `deepseek-ai/DeepSeek-V4-Pro-0813` or `openai/gpt-oss-120b`:

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
https://model-MODEL_ID.api.baseten.co/environments/ENVIRONMENT/sync/v1/chat/completions
```
{:.no-copy-code}

Replace `MODEL_ID` with the model ID from your {{ provider.name }} dashboard.
Replace `ENVIRONMENT` with the deployment environment, for example `production`.
Set the target `name` to the model name your deployment serves.
For engines that take a `--served-model-name` flag, such as vLLM, use that value:

```yaml
targets:
  - name: SERVED_MODEL_NAME
    provider: my-baseten-account
    config:
      type: baseten
      upstream_url: https://model-MODEL_ID.api.baseten.co/environments/production/sync/v1/chat/completions
```

If your deployment exposes an API that the `generate` capability doesn't cover, use the [passthrough format](/ai-gateway/passthrough/) instead.
Set `formats[].type` to `passthrough` on the AI Model.

## Reasoning and usage

{{site.ai_gateway}} applies the following to {{ provider.name }} requests and responses:

- **Reasoning output:**
  {{ provider.name }} models return reasoning text in either `reasoning_content` or `thinking`.
  {{site.ai_gateway}} normalizes both to `reasoning`, in non-streaming responses and in streaming deltas.
- **Reasoning effort:**
  {{site.ai_gateway}} forwards `reasoning_effort` unchanged.
  {{ provider.name }} validates the value against the accepted values of the target model.
- **Cached tokens:**
  When {{ provider.name }} reports `usage.prompt_tokens_details.cached_tokens`, {{site.ai_gateway}} includes it in the response, the streaming usage event, and the logs.

The `model` field in responses contains the target `name`, for example `deepseek-ai/DeepSeek-V4-Pro-0813`.

To call the AI Model, send its `name` in the `model` field of the request. For more information, see [Request routing rules](/ai-gateway/entities/ai-model/#request-routing-rules).
