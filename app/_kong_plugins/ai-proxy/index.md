---
title: 'AI Proxy'
name: 'AI Proxy'

content_type: plugin

publisher: kong-inc
description: The AI Proxy plugin lets you transform and proxy requests to a number of AI providers and models.


products:
  - gateway
  - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-proxy.png

categories:
  - ai

tags:
  - ai
  - ai-proxy

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Get started with {{site.ai_gateway}}
    url: /ai-gateway/get-started/

examples_groups:
  - slug: open-ai
    text: OpenAI use cases
  - slug: multimodal-open-ai
    text: Multimodal route types for OpenAI
  - slug: openai-processing
    text: Other OpenAI processing routes
  - slug: azure-processing
    text: Azure processing routes
  - slug: native-routes
    text: Native routes
  - slug: claude-code
    text: Claude Code use cases

faqs:
  - q: Can I override `config.model.name` by specifying a different model name in the request?
    a: |
      No. The model name must match the one configured in `config.model.name`. If a different model is specified in the request, the plugin returns a 400 error.
  - q: |
      Can I override `temperature`, `top_p`, and `top_k` from the request?
    a: |
      Yes. The values for [`temperature`](./reference/#schema--config-model-options-temperature), [`top_p`](./reference/#schema--config-model-options-top-p), and [`top_k`](./reference/#schema--config-model-options-top-k) in the request take precedence over those set in `config.targets.model.options`.

  - q: Can I override authentication values from the request?
    a: |
      Yes, but only if [`config.auth.allow_override`](./reference/#schema--config-auth-allow-override) is set to `true` in the plugin configuration.
      When enabled, this allows request-level auth parameters (such as API keys or bearer tokens) to override the static values defined in the plugin.
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Request and response formats
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}
