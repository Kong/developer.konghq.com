---
title: "Meta provider"
layout: reference
content_type: reference
description: Reference for supported capabilities and configuration for the Meta provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/meta/

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
  ai-gateway: '2.4'

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
  - text: Meta documentation
    url: https://www.meta.ai/
---

<!--
TODO(AI-246 OQ1): the runtime capability matrix isn't confirmed. Verify image generation and editing, video input, and audio transcription before GA.
TODO(AI-246 OQ2): the `meta` discriminator name may change. Update `type: meta` here and in providers.yaml if it does.
-->

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Meta" %}

## Configure a {{ provider.name }} provider {% new_in 2.4 %}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/).
You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }}.

Create an AI Model Provider entity to store your {{ provider.name }} API key.
{{ provider.name }} authenticates with an `Authorization: Bearer` header:

{% entity_example %}
type: model-provider
data:
  display_name: Meta Production
  name: my-meta-account
  type: meta
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $META_API_KEY
    secret: true
    description: "The API key used to connect to Meta. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a {{ provider.name }} model {% new_in 2.4 %}

{{ provider.name }} supports chat completions and the Responses API through the OpenAI format, and the Messages API through the Anthropic format. Streaming, tool calling, and structured output are supported. Models also accept image, video, and PDF input.

By default, {{site.ai_gateway}} sends requests to the {{ provider.name }} hosted Model API at `https://api.meta.ai/v1`. Set the target `name` to the upstream model ID, for example `muse-spark-1.3`. {{site.ai_gateway}} passes the name to {{ provider.name }} unchanged.

{% entity_example %}
type: model
data:
  display_name: Muse Spark on Meta
  name: muse-spark
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /meta
  targets:
    - name: muse-spark-1.3
      provider: my-meta-account
      config:
        type: meta
{% endentity_example %}

To use a different base URL, set `upstream_url` on the target.

{:.warning}
> Model IDs with a `-contributor` suffix let {{ provider.name }} train on your prompts. Don't use them for sensitive data.

## Self-hosted Llama models

This provider targets the {{ provider.name }} hosted Model API. To route to a self-hosted open-weight Llama model, use the [Llama2 provider](/ai-gateway/ai-providers/llama/) with `upstream_url` instead.
