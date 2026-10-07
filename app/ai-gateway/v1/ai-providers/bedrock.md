---
title: "Amazon Bedrock provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Amazon Bedrock provider
breadcrumbs:
  - /ai-gateway/v1/
  - /ai-gateway/v1/ai-providers/

permalink: /ai-gateway/v1/ai-providers/bedrock/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

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
    url: /ai-gateway/v1/
  - text: Amazon Bedrock tutorials
    url: /how-to/?tags=bedrock
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/v1/ai-providers/
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
major_version:
  ai-gateway: 1

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

## Connect through a VPC endpoint

{% comment %}
TODO(reviewer, AI-125): Add a new_in tag to this heading with the {{site.base_gateway}} version that ships
`model.options.bedrock.vpc_endpoint` in AI Proxy and AI Proxy Advanced. The plugin schema.json files are generated,
so the field appears in the plugin reference only after the gateway release. Remove this section from the PR if
the plugin field doesn't ship in the same release as AI Gateway 2.3.
{% endcomment %}

If {{site.base_gateway}} reaches Amazon Bedrock over AWS PrivateLink, set `model.options.bedrock.vpc_endpoint` to the DNS name of your Bedrock Runtime interface VPC endpoint. {{site.base_gateway}} connects to that host, keeps building the Bedrock path for each operation (including streaming), and signs requests with SigV4 for the real Bedrock service and `aws_region`. If you also set `model.options.upstream_url`, it takes precedence and replaces the full URL, including the path.

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
          vpc_endpoint: ${vpc_endpoint}

variables:
  key:
    value: $AWS_ACCESS_KEY_ID
    description: The AWS access key ID to use to connect to Bedrock.
  secret:
    value: $AWS_SECRET_ACCESS_KEY
    description: The AWS secret access key to use to connect to Bedrock.
  vpc_endpoint:
    value: $BEDROCK_VPC_ENDPOINT
    description: The DNS name of your Bedrock Runtime interface VPC endpoint.
{% endentity_example %}

{% include plugins/ai-proxy/providers/how-tos.md %}