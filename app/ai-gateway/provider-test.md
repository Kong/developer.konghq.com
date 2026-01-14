---
title: "OpenAI provider"
layout: reference
content_type: reference
description: Test
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

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
  gateway: '3.10'

---


{% include plugins/ai-proxy/tables/providers.html providers=site.data.plugins.ai-proxy provider_name="OpenAI" %}