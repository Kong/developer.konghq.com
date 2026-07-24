---
title: "DeepSeek provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for DeepSeek provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/deepseek/

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


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="DeepSeek" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: Deepseek Production
  name: my-deepseek-account
  type: deepseek
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: $DEEPSEEK_API_KEY
{% endentity_example %}

Replace the following with your actual values:
* `$DEEPSEEK_API_KEY`: The API key used to connect to DeepSeek. Include the `Bearer ` prefix, for example `Bearer <your-api-key>`.
