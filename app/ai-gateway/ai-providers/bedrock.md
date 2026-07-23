---
title: "Amazon Bedrock provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Amazon Bedrock provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/bedrock/

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


faqs:
  - q: How do I specify model IDs for Amazon Bedrock cross-region inference profiles?
    a: |
      {% include md/ai-gateway/v2/faqs/bedrock-models.md %}
  - q: How do I set the FPS parameter for video generation for Amazon Bedrock?
    a: |
      {% include md/ai-gateway/v2/faqs/bedrock-fps.md %}
  - q: How do I include guardrail configuration with Amazon Bedrock requests?
    a: |
      {% include md/ai-gateway/v2/faqs/bedrock-guardrails.md %}
  - q: How do I use Amazon Bedrock's Rerank API to improve RAG retrieval quality?
    a: |
      {% include md/ai-gateway/v2/faqs/bedrock-rerank.md %}

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon Bedrock" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon Bedrock" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

{% entity_example %}
type: model-provider
data:
  display_name: AWS Production
  name: my-aws-account
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: $AWS_ACCESS_KEY_ID
      secret_access_key: $AWS_SECRET_ACCESS_KEY
{% endentity_example %}

{% include md/ai-gateway/v2/aws-auth.md %}