---
title: Set up AI Proxy with AWS Bedrock in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using AWS Bedrock.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - aws-bedrock

tldr:
  q: How do I use the AI Proxy plugin with AWS Bedrock?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the AWS Bedrock provider and add the model and your API key.

tools:
  - deck

prereqs:
  inline:
    - title: AWS credentials and Bedrock model access
      content: |
        Before you begin, you must have AWS credentials with Bedrock permissions:

        - **AWS Access Key ID**: Your AWS access key
        - **AWS Secret Access Key**: Your AWS secret key
        - **Region**: AWS region where Bedrock is available (for example, `us-west-2`)

        1. Enable the rerank model in the [AWS Bedrock console](https://console.aws.amazon.com/bedrock/) under **Model Access**. Navigate to **Bedrock** > **Model access** and request access to `cohere.rerank-v3-5:0`.

        2. After model access is granted, construct the model ARN for your region:
           ```
           arn:aws:bedrock:<region>::foundation-model/cohere.rerank-v3-5:0
           ```
           Replace `<region>` with your AWS region (for example, `us-west-2`).

        3. Export the required values as environment variables:
           ```sh
           export DECK_AWS_ACCESS_KEY_ID="<your-access-key-id>"
           export DECK_AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
           export DECK_AWS_REGION="<region>"
           export DECK_AWS_MODEL="arn:aws:bedrock:<region>::foundation-model/cohere.rerank-v3-5:0"
           ```

           Replace `<region>` in both `AWS_REGION` and the `AWS_MODEL` ARN with your AWS Bedrock deployment region. See [FAQs](./#what-rerank-models-are-available) below for more details.
      icon_url: /assets/icons/aws.svg
    - title: Python and requests library
      content: |
        Install Python 3 and the requests library:
        ```sh
        pip install requests
        ```
      icon_url: /assets/icons/python.svg
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

To set up AI Proxy with AWS Bedrock, specify the model and set the appropriate authentication header.

In this example, we'll use the Meta Llama 3 70B Instruct model:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
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
    description: The AWS access key ID to use to connect to Bedrock.
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
    description: The AWS secret access key to use to connect to Bedrock.
formats:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform
{% endentity_examples %}
<!--vale on-->

## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
