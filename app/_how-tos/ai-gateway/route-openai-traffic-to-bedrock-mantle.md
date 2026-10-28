---
title: Route OpenAI traffic to Amazon Bedrock Mantle with {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/route-openai-traffic-to-bedrock-mantle/

related_resources:
  - text: Amazon Bedrock provider
    url: /ai-gateway/ai-providers/bedrock/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

description: Configure an AI Model that sends OpenAI Chat Completions requests to the Amazon Bedrock Mantle endpoint without translating them.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.3'

tags:
  - ai
  - bedrock

tldr:
  q: How do I send OpenAI-format requests to Amazon Bedrock Mantle through {{site.ai_gateway}}?
  a: Create an AI Model Provider of type `bedrock` with your AWS credentials, then create an AI Model with the `openai` format and a Bedrock target that sets `endpoint_type` to `mantle`. {{site.ai_gateway}} sends OpenAI requests to `bedrock-mantle.{region}.api.aws` in OpenAI format, without translating them to Bedrock Converse, and signs them with SigV4.

prereqs:
  inline:
    - title: Amazon Bedrock Mantle
      content: |
        1. In the AWS Management Console, confirm that Amazon Bedrock Mantle is available in your region and that your account has access to the model you want to use.
        1. Create an IAM user or role with permission to call Bedrock Mantle, then create access keys for it. The following is an example security policy you can apply to your IAM user or role:
           ```json
           {
             "Version": "2012-10-17",
             "Statement": [
               {
                 "Sid": "VisualEditor0",
                 "Effect": "Allow",
                 "Action": [
                   "bedrock-mantle:GetModel",
                   "bedrock-mantle:ListFiles",
                   "bedrock:InvokeModel",
                   "bedrock-mantle:CreateFile",
                   "bedrock-mantle:ListModels",
                   "bedrock-mantle:CancelInference",
                   "bedrock-mantle:GetFile",
                   "bedrock:InvokeModelWithResponseStream",
                   "bedrock-mantle:CreateInference",
                   "bedrock-mantle:CountTokens"
                 ],
                 "Resource": [
                   "arn:aws:bedrock-mantle:{region}:{account_id}:project/{project_name_or_default}",
                   "arn:aws:bedrock-mantle:{region}:{account_id}:project/{project_name_or_default}/{model_name_1}",
                   "arn:aws:bedrock-mantle:{region}:{account_id}:project/{project_name_or_default}/{model_name_2}"
                 ]
               }
             ]
           }
           ```
        1. Export your AWS credentials, region, and the Mantle model ID:
           ```bash
           export AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY_ID'
           export AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
           export AWS_REGION='YOUR_AWS_REGION'
           export MANTLE_MODEL_ID='YOUR_MANTLE_MODEL_ID'
           ```
cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

## Create an AI Model Provider

Create a `bedrock` type [AI Model Provider](/ai-gateway/entities/ai-model-provider/) that stores your AWS credentials. The same provider works for Bedrock Runtime and Bedrock Mantle targets:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-aws-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-aws-account
    display_name: "AWS Production"
    type: bedrock
    config:
      auth:
        type: aws
        access_key_id: !env AWS_ACCESS_KEY_ID
        secret_access_key: !secret {source: !env AWS_SECRET_ACCESS_KEY}
{% endentity_examples %}

To authenticate with an Amazon Bedrock API key instead of SigV4, set [`config.auth.type`](/ai-gateway/entities/ai-model-provider/#schema-aigateway-model-provider-config-auth) to `basic` and add an `Authorization` header with the value `Bearer <BEDROCK_API_KEY>` in `config.auth.headers`.

## Create an AI Model with a Mantle target

Create an [AI Model](/ai-gateway/entities/ai-model/) that accepts OpenAI requests and routes them to Bedrock Mantle:

{% entity_examples %}
ai_gateway_models:
  - ref: my-mantle-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-mantle-model
    display_name: "my-mantle-model"
    type: model
    formats:
      - type: openai
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - my-mantle-model
    targets:
      - name: !env MANTLE_MODEL_ID
        provider: my-aws-account
        config:
          type: bedrock
          region: !env AWS_REGION
          endpoint_type: mantle
    capabilities:
      - generate
{% endentity_examples %}

The AI Model uses the following settings:

* `formats: [type: openai]`: Accepts OpenAI Chat Completions requests. A Mantle target can't be paired with the `bedrock` format, because Mantle has no Converse or InvokeModel API, and {{site.konnect_short_name}} rejects that configuration.
* `targets[].config.endpoint_type: mantle`: Sends requests to `https://bedrock-mantle.{region}.api.aws` instead of the default Bedrock Runtime endpoint. {{site.ai_gateway}} keeps the OpenAI request format instead of translating it to Bedrock Converse, and changes only the host, path, and authentication headers.
* `config.route.model`: Lets clients send the alias `my-mantle-model` in the `model` field instead of the upstream model ID.

## Validate

Send a chat request to the AI Model:

<!-- vale off -->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
retry: true
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
  messages:
  - role: "user"
    content: "Say this is a test!"
  model: my-mantle-model
{% endvalidation %}
<!-- vale on -->

A `200` response with an OpenAI Chat Completions body confirms that Bedrock Mantle served the request.
