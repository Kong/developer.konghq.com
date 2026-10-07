---
title: Connect to Amazon Bedrock through a VPC endpoint with {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/connect-to-bedrock-through-vpc-endpoint/

related_resources:
  - text: Amazon Bedrock provider
    url: /ai-gateway/ai-providers/bedrock/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Route OpenAI traffic to Amazon Bedrock Mantle
    url: /ai-gateway/route-openai-traffic-to-bedrock-mantle/

description: Send Amazon Bedrock traffic from {{site.ai_gateway}} through an AWS PrivateLink interface VPC endpoint while keeping Bedrock paths, streaming, and SigV4 signing intact.

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
  q: How do I route {{site.ai_gateway}} traffic to Amazon Bedrock over AWS PrivateLink?
  a: Set `vpc_endpoint` in the Bedrock target `config` of your AI Model to the DNS name of your Bedrock Runtime interface VPC endpoint. {{site.ai_gateway}} connects to that host, keeps building the Bedrock path for each operation, and signs requests with SigV4 for the real Bedrock service and region.

prereqs:
  inline:
    - title: Amazon Bedrock VPC endpoint
      content: |
        1. Create an interface VPC endpoint for the Bedrock Runtime service (`com.amazonaws.<region>.bedrock-runtime`) in the VPC where your data plane nodes run. See [Use interface VPC endpoints (AWS PrivateLink)](https://docs.aws.amazon.com/bedrock/latest/userguide/vpc-interface-endpoints.html) in the AWS documentation.
        1. Make sure your data plane nodes can resolve the endpoint's DNS name and reach it on port 443.
        1. Make sure your IAM user or role has `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` permissions, and that the VPC endpoint policy allows them.
        1. Export your AWS credentials, region, and the endpoint DNS name:
           ```bash
           export AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY_ID'
           export AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
           export AWS_REGION='YOUR_AWS_REGION'
           export BEDROCK_VPC_ENDPOINT='YOUR_VPC_ENDPOINT_DNS_NAME'
           ```
cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

---

{% comment %}
TODO(reviewer, AI-125):
- Confirm the value format for `vpc_endpoint` (bare hostname vs. URL with scheme) and update the prereq export and example.
- Confirm which data plane deployments can use this (self-managed hybrid only, or also Dedicated Cloud Gateways with private networking).
- Q1: Confirm the `vpc_endpoint` + `upstream_url` behavior (precedence or validation error).
{% endcomment %}

## Create an AI Model Provider

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) of type `bedrock` that stores your AWS credentials:

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

## Create an AI Model that uses the VPC endpoint

Create an [AI Model](/ai-gateway/entities/ai-model/) with a Bedrock target that sets `vpc_endpoint`:

{% entity_examples %}
ai_gateway_models:
  - ref: my-private-bedrock-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-private-bedrock-model
    display_name: "my-private-bedrock-model"
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
            - my-private-bedrock-model
    targets:
      - name: us.anthropic.claude-haiku-4-5-20251001-v1:0
        provider: my-aws-account
        config:
          type: bedrock
          region: !env AWS_REGION
          vpc_endpoint: !env BEDROCK_VPC_ENDPOINT
    capabilities:
      - generate
{% endentity_examples %}

The target uses the following settings:

* `vpc_endpoint`: Replaces only the host that {{site.ai_gateway}} connects to. {{site.ai_gateway}} still builds the Bedrock path for each operation, including streaming, and SigV4 still signs for the Bedrock service in `region`.
* `region`: Sets the region used for SigV4 signing. It must match the region of the VPC endpoint.

Leave `upstream_url` unset on this target. If both are set, `upstream_url` takes precedence and replaces the full URL, including the path.

If your AI Model also uses Bedrock embeddings, set `vpc_endpoint` in [`config.balancer.embeddings`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-embeddings) as well.

## Validate

Send a streaming chat request to the AI Model:

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
  model: my-private-bedrock-model
  stream: true
{% endvalidation %}
<!-- vale on -->

A `200` response with streamed chunks confirms that {{site.ai_gateway}} reached Bedrock through the VPC endpoint and built the streaming path. If the request fails with a connection error, check that your data plane nodes can resolve and reach the VPC endpoint. {{site.ai_gateway}} doesn't fall back to the public Bedrock endpoint.
