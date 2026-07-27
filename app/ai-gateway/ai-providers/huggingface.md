---
title: "Hugging Face provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Hugging Face provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/huggingface/

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


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Hugging Face" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Hugging Face" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Huggingface Production
  name: my-huggingface-account
  type: huggingface
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $HUGGINGFACE_TOKEN
    description: "The access token used to connect to Hugging Face. Include the `Bearer` prefix, for example `Bearer <your-access-token>`."
{% endentity_example %}
