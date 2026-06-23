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

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Amazon Bedrock" %}

## Configure {{ provider.name }}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [Provider](/ai-gateway/entities/ai-provider/). You can then access supported [Models](/ai-gateway/entities/ai-model/) from  {{ provider.name }}.

Here's a minimal configuration for chat completions:

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

## Authentication with AWS

You can also use {{ provider.name }} with AWS credentials by setting `auth` to `aws` and specifying:

* **`access_key_id`** (optional): AWS access key ID for static IAM user credentials. If omitted, the default AWS credentials provider chain is used (EC2 instance profiles, environment variables, etc.).
* **`secret_access_key`** (optional): AWS secret access key paired with `access_key_id`. Required if `access_key_id` is set.
* **`assume_role_arn`** (optional): IAM role ARN to assume for temporary credentials. Useful for cross-account access.
* **`role_session_name`** (optional): Session name for the assumed role. Required if `assume_role_arn` is set.
* **`sts_endpoint_url`** (optional): Custom STS endpoint for role assumption. Defaults to `https://sts.amazonaws.com`.
* **`batch_role_arn`** (optional): Separate role ARN for Bedrock batch API calls.