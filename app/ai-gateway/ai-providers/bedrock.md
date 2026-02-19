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
 - on-prem
 - konnect

products:
  - ai-gateway
  - gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.8'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Amazon Bedrock tutorials
    url: /how-to/?tags=bedrock
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/


faqs:
  - q: How do I specify model IDs for Amazon Bedrock cross-region inference profiles?
    a: |
      {% include faqs/bedrock-models.md %}
  - q: How do I set the FPS parameter for video generation for Amazon Bedrock?
    a: |
      {% include faqs/bedrock-fps.md %}
  - q: How do I include guardrail configuration with Amazon Bedrock requests?
    a: |
      {% include faqs/bedrock-guardrails.md %}
  - q: How do I use Amazon Bedrock's Rerank API to improve RAG retrieval quality?
    a: |
      {% include faqs/bedrock-rerank.md %}

how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - bedrock
    description: true
    view_more: false

---


{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Amazon Bedrock" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Amazon Bedrock" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      allow_override: false
      aws_access_key_id: ${key}
      aws_secret_access_key: ${secret}
    model:
      provider: bedrock
      name: meta.llama3-70b-instruct-v1:0
      options:
        bedrock:
          aws_region: us-east-1

variables:
  key:
    value: $AWS_ACCESS_KEY_ID
    description: The AWS access key ID to use to connect to Bedrock.
  secret:
    value: $AWS_SECRET_ACCESS_KEY
    description: The AWS secret access key to use to connect to Bedrock.
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

{% include plugins/ai-proxy/providers/how-tos.md %}