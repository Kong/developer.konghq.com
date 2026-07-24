---
title: "Kimi provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Kimi provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/kimi/

min_version:
  ai-gateway: '2.0'

works_on:
  - konnect

tools:
  - konnect-api
  - kongctl

products:
  - ai-gateway

tags:
  - ai
  - kimi

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


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Kimi" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/) as follows:

{% entity_example %}
type: model-provider
data:
  display_name: Kimi Production
  name: my-kimi-account
  type: kimi
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: $KIMI_TOKEN
{% endentity_example %}

Replace the following with your actual values:
* `$KIMI_TOKEN`: The API token used to connect to Kimi. Include the `Bearer ` prefix, for example `Bearer <your-api-token>`.
