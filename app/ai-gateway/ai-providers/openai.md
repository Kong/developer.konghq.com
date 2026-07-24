---
title: "OpenAI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for OpenAI provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/openai/

tools:
  - konnect-api
  - kongctl

works_on:
 - konnect

products:
  - ai-gateway

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

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="OpenAI" %}


## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: OpenAI Production
  name: my-openai-account
  type: openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: $OPENAI_API_KEY
{% endentity_example %}

Replace the following with your actual values:
* `$OPENAI_API_KEY`: The API key used to connect to OpenAI. Include the `Bearer ` prefix, for example `Bearer <your-api-key>`.
