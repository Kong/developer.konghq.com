---
title: "Cohere provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Cohere provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/cohere/

works_on:
 - konnect

products:
  - ai-gateway

tags:
  - ai

tools:
  - konnect-api
  - kongctl

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

faqs:
  - q: How do I use Cohere's Rerank API to improve RAG retrieval quality?
    a: |
      {% include md/ai-gateway/v2/faqs/cohere-rerank.md %}

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Cohere" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Cohere" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Cohere Production
  name: my-cohere-account
  type: cohere
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $COHERE_API_KEY
    secret: true
    description: "The API key used to connect to Cohere. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}
