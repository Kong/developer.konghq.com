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
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/ai-providers/


faqs:
  - q: How do I specify model IDs for AWS Bedrock cross-region inference profiles?
    a: |
      For cross-region inference, prefix the model ID with a geographic identifier:
      ```
      {geography-prefix}.{provider}.{model-name}...
      ```

      For example: `us.anthropic.claude-sonnet-4-5-20250929-v1:0`

      {% table %}
      columns:
        - title: Prefix
          key: prefix
        - title: Geography
          key: geography
      rows:
        - prefix: "`us.`"
          geography: "United States"
        - prefix: "`eu.`"
          geography: "European Union"
        - prefix: "`apac.`"
          geography: "Asia-Pacific"
        - prefix: "`global.`"
          geography: "All commercial regions"
      {% endtable %}

      For a full list of supported cross-region inference profiles, see [Supported Regions and models for inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html) in the AWS documentation.

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

To use {{ provider.name }} with Kong AI Gateway, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

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