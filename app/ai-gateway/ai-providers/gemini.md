---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/gemini/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.8'

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      You have several options, depending on the SDK and configuration:

      - Use the **Gemini SDK**:

        1. Set [`llm_format`](/plugins/ai-proxy/reference/#schema--config-llm-format) to `gemini`.
        1. Use the Gemini provider.
        1. Configure parameters like [`temperature`](/plugins/ai-proxy/reference/#schema--config-targets-model-options-temperature), [`top_p`](/plugins/ai-proxy/reference/#schema--config-targets-model-options-top-p), and [`top_k`](/plugins/ai-proxy/reference/#schema--config-targets-model-options-top-k) on the client side:
            ```python
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config=genai.types.GenerationConfig(
                    temperature=0.7,
                    top_p=0.9,
                    top_k=40,
                    max_output_tokens=1024
                )
            )
            ```

      - Use the **OpenAI SDK** with the Gemini provider:
        1. Set [`llm_format`](/plugins/ai-proxy/reference/#schema--config-llm-format) to `openai`.
        1. You can configure parameters in one of three ways:
          - Configure them in the plugin only.
          - Configure them in the client only.
          - Configure them in both—the client-side values will override plugin config.

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - gemini
    description: true
    view_more: false
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with Kong AI Gateway, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      param_name: key
      param_value: ${key}
      param_location: query
    model:
      provider: gemini
      name: gemini-2.5-flash

variables:
  key:
    value: $GEMINI_API_KEY
    description: The API key to use to connect to Gemini.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}