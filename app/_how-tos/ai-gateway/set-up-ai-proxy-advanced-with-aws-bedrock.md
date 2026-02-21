---
title: Set up AI Proxy Advanced with AWS Bedrock in {{site.base_gateway}}.
permalink: /how-to/set-up-ai-proxy-advanced-with-aws-bedrock/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to create a chat route using AWS Bedrock.

products:
  - ai-gateway
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - aws-bedrock

tldr:
  q: How do I use the AI Proxy Advanced plugin with AWS Bedrock?
  a: Create a Gateway Service and a Route, then enable the AI Proxy Advanced plugin and configure it with the AWS Bedrock provider and add the model and your AWS credentials.

tools:
  - deck

prereqs:
  inline:
    - title: AWS credentials and Bedrock model access
      content: |
        Before you begin, you must have AWS credentials with Bedrock permissions:

        - **AWS Access Key ID**: Your AWS access key
        - **AWS Secret Access Key**: Your AWS secret key
        - **Region**: AWS region where Bedrock is available (for example, `us-east-1`)

        1. Enable the chat model in the [AWS Bedrock console](https://console.aws.amazon.com/bedrock/) under **Model Access**. Navigate to **Bedrock** > **Model access** and request access to `meta.llama3-70b-instruct-v1:0`.

        1. Export the required values as environment variables:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID="<your-access-key-id>"
           export DECK_AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
           ```
      icon_url: /assets/icons/aws.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the plugin

To set up AI Proxy Advanced with AWS Bedrock, specify the model and set the authenticate using AWS credentials.

In this example, we'll use the Meta Llama 3 70B Instruct model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              allow_override: false
              aws_access_key_id: ${aws_access_key_id}
              aws_secret_access_key: ${aws_secret_access_key}
            model:
              provider: bedrock
              name: meta.llama3-70b-instruct-v1:0
              options:
                bedrock:
                  aws_region: us-east-1
variables:
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
formats:
  - deck
{% endentity_examples %}
<!--vale on-->

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
