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

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Amazon Bedrock tutorials
    url: /how-to/?tags=bedrock
  - text: "{{site.ai_gateway}} Policies"
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

---


{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon Bedrock" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Amazon Bedrock" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/). You can then access supported [Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

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


<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: AWS Production
  name: my-aws-account
  type: bedrock
  config:
    auth:
      type: aws
      allow_override: false
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_SECRET_ACCESS_KEY
{% endkonnect_api_request %}
<!--vale on-->
