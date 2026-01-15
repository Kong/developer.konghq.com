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
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway


tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/
---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Cerebras" %}
