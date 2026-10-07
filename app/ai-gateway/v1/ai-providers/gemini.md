---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/v1/
  - /ai-gateway/v1/ai-providers/

permalink: /ai-gateway/v1/ai-providers/gemini/

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
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/
  - text: Gemini tutorials
    url: /how-to/?tags=gemini
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/v1/ai-providers/
faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      {% include faqs/gemini-model-params.md %}
  - q: How do I use Gemini's `googleSearch` tool for real-time web searches?
    a: |
      {% include faqs/gemini-search.md %}
  - q: How do I control aspect ratio and resolution for Gemini image generation?
    a: |
      {% include faqs/gemini-image.md %}
  - q: How do I get reasoning traces from Gemini models?
    a: |
      {% include faqs/gemini-thinking.md %}

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - gemini
    description: true
    view_more: false
major_version:
  ai-gateway: 1

---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Gemini" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

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

<!-- TODO(AI-174): Confirm the {{site.base_gateway}} version that ships the AI Gateway 2.3 Gemini changes in AI Proxy and AI Proxy Advanced. The `new_in 3.17` tags on this page are placeholders. -->

## Thought signatures on the OpenAI-compatible route

{% new_in 3.17 %} Gemini thinking models attach an opaque `thoughtSignature` to response parts, and expect it back on the matching part in the next turn to keep reasoning context across multi-turn conversations and function calls. When you use an OpenAI-compatible `route_type` such as `llm/v1/chat` with `model.provider: gemini`, {{site.ai_gateway}} captures each `thoughtSignature` from the Gemini or Vertex AI response, returns it to the client in the OpenAI-compatible response, and re-attaches it to the matching part when it translates the next request.

To keep signatures intact, send the assistant message from the previous response back unchanged in the conversation history, including any tool calls. {{site.ai_gateway}} doesn't inspect or modify signature contents and doesn't log them at default log levels.

<!-- TODO(AI-174 OQ3): Document where the signature sits in the OpenAI-compatible payload, add a request/response example, and state whether streaming responses are supported. -->
<!-- TODO(AI-174 OQ6): Confirm which route types carry signatures (`llm/v1/chat` and `llm/v1/responses` are expected). -->

## Gemini Interactions API

{% new_in 3.17 %} {{site.ai_gateway}} forwards requests for the [Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions) to Gemini without translating the request or response body. The plugin's `auth` settings still authenticate the upstream request. The Interactions API is available only in the native Gemini format; {{site.ai_gateway}} doesn't translate it to or from the OpenAI or Anthropic formats.

<!-- TODO(AI-174 OQ4): Confirm the `route_type` for the Interactions API (a new value, or `preserve` with path detection) and add an `entity_example`. -->
<!-- TODO(AI-174 OQ2): State which analytics, cost tracking, and guardrail plugins apply to Interactions API traffic. -->

{% include plugins/ai-proxy/providers/how-tos.md %}