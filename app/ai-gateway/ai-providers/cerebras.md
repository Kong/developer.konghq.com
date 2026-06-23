---
title: "Cerebras provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Cerebras provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/cerebras/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Cerebras tutorials
    url: /how-to/?tags=cerebras
  - text: "{{site.ai_gateway}} Policies"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Cerebras" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Provider](/ai-gateway/entities/ai-provider/) and [AI Models](/ai-gateway/entities/ai-model/).

Refer to the [AI Model](/ai-gateway/entities/ai-model/) documentation for complete configuration options.
