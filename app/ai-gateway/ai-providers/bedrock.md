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
      access_key_id: ${key_id}
      secret_access_key: ${access_key}
variables:
  key_id:
    value: $AWS_ACCESS_KEY_ID
    description: Your AWS access key ID.
  access_key:
    value: $AWS_SECRET_ACCESS_KEY
    secret: true
    description: Your AWS secret access key.
{% endentity_example %}

## Authentication with AWS

You can also use {{ provider.name }} with AWS credentials by setting `auth` to `aws` and specifying:

* **`access_key_id`** (optional): AWS access key ID for static IAM user credentials. If omitted, the default AWS credentials provider chain is used (EC2 instance profiles, environment variables, etc.).
* **`secret_access_key`** (optional): AWS secret access key paired with `access_key_id`. Required if `access_key_id` is set.
* **`assume_role_arn`** (optional): IAM role ARN to assume for temporary credentials. Useful for cross-account access.
* **`role_session_name`** (optional): Session name for the assumed role. Required if `assume_role_arn` is set.
* **`sts_endpoint_url`** (optional): Custom STS endpoint for role assumption. Defaults to `https://sts.amazonaws.com`.
* **`batch_role_arn`** (optional): Separate role ARN for Bedrock batch API calls.

## Choose a Bedrock endpoint {% new_in 2.3 %}

Amazon Bedrock serves inference from two endpoints. Set `endpoint_type` in the target `config` of an [AI Model](/ai-gateway/entities/ai-model/) to choose which one {{site.ai_gateway}} sends requests to:

<!--vale off-->
{% table %}
columns:
  - title: "`endpoint_type`"
    key: type
  - title: Upstream host
    key: host
  - title: Supported AI Model formats
    key: formats
rows:
  - type: "`runtime` (default)"
    host: "`https://bedrock-runtime.{region}.amazonaws.com`"
    formats: "All formats, including `bedrock`. {{site.ai_gateway}} translates OpenAI and Anthropic requests to the Bedrock Converse or InvokeModel APIs."
  - type: "`mantle`"
    host: "`https://bedrock-mantle.{region}.api.aws`"
    formats: "OpenAI Chat Completions, OpenAI Responses, and Anthropic Messages. {{site.ai_gateway}} forwards the request body without translating it and rewrites only the host, path, and authentication headers."
{% endtable %}
<!--vale on-->

Use `mantle` when your clients already speak the OpenAI or Anthropic APIs and you want Bedrock Mantle to handle them natively, for example to run the OpenAI Codex CLI against models on Bedrock. Keep `runtime` for Bedrock-native clients, for the Bedrock-specific APIs such as Rerank, async invoke, and batch, and for any model that has no Mantle support.

The Mantle endpoint has no Converse or InvokeModel API, so {{site.konnect_short_name}} rejects a target with `endpoint_type: mantle` if its AI Model declares a format with `type: bedrock`. Use the `openai` or `anthropic` format on AI Models with Mantle targets.

{% comment %}
TODO(reviewer, AI-123): Confirm the exact AI Model format and capability combinations that map to Mantle
(for example, `openai` + `generate` for Chat Completions and `openai` + `agentic` for Responses), and whether
Mantle supports embeddings or any other capability. Also confirm the list of Bedrock-specific APIs that stay
Runtime-only.
{% endcomment %}

Both endpoints accept the authentication types an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) of type `bedrock` supports:

* **AWS SigV4:** Set `config.auth.type` to `aws`, as described in [Authentication with AWS](#authentication-with-aws). This works the same way for both endpoints.
* **Bearer token:** Set `config.auth.type` to `basic` with an `Authorization` header whose value is `Bearer <BEDROCK_API_KEY>`, using an Amazon Bedrock API key.

The following AI Model sends OpenAI Chat Completions requests to Bedrock Mantle:

{% entity_example %}
type: model
data:
  name: my-mantle-model
  display_name: My Mantle model
  type: model
  formats:
    - type: openai
  capabilities:
    - generate
  targets:
    - name: ${model_id}
      provider: my-aws-account
      config:
        type: bedrock
        region: us-east-1
        endpoint_type: mantle
variables:
  model_id:
    value: $MANTLE_MODEL_ID
    description: The ID of a model that Amazon Bedrock serves through the Mantle endpoint in your region.
{% endentity_example %}

For a complete walkthrough, see [Route OpenAI traffic to Amazon Bedrock Mantle](/ai-gateway/route-openai-traffic-to-bedrock-mantle/).

## Connect through a VPC endpoint {% new_in 2.3 %}

If your data plane nodes reach Amazon Bedrock over AWS PrivateLink, set `vpc_endpoint` in the target `config` to the hostname of your interface VPC endpoint. {{site.ai_gateway}} sends requests to that host and keeps everything else the same as for the public endpoint:

* {{site.ai_gateway}} still builds the Bedrock path for each operation, including streaming (`invoke-with-response-stream`) and async invoke.
* SigV4 signs requests for the real Bedrock service and the configured `region`, not for the VPC endpoint hostname.
* If the VPC endpoint is unreachable, the request fails. {{site.ai_gateway}} doesn't fall back to the public endpoint.

`vpc_endpoint` is available on chat and invoke targets and on the embeddings model configuration in [`config.balancer.embeddings`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-embeddings).

{% entity_example %}
type: model
data:
  name: my-private-bedrock-model
  display_name: My private Bedrock model
  type: model
  formats:
    - type: openai
  capabilities:
    - generate
  targets:
    - name: us.anthropic.claude-haiku-4-5-20251001-v1:0
      provider: my-aws-account
      config:
        type: bedrock
        region: us-east-1
        vpc_endpoint: ${vpc_endpoint}
variables:
  vpc_endpoint:
    value: $BEDROCK_VPC_ENDPOINT
    description: "The DNS name of your Bedrock Runtime interface VPC endpoint, for example `vpce-0123456789abcdef0-abcdefgh.bedrock-runtime.us-east-1.vpce.amazonaws.com`."
{% endentity_example %}

`vpc_endpoint` overrides only the host. If you also set `upstream_url` on the same target, `upstream_url` takes precedence and {{site.ai_gateway}} ignores `vpc_endpoint`. Use `upstream_url` only when you need to override the full URL, because it also replaces the path that {{site.ai_gateway}} builds for each Bedrock operation.

{% comment %}
TODO(reviewer, AI-125):
- Q1: If `vpc_endpoint` and `upstream_url` are both set, is that a validation error instead of `upstream_url` winning? Update this paragraph if so.
- Confirm the accepted value format: bare hostname (OpenAPI description) or URL with scheme (Aha says "same rules as `aws_sts_endpoint_url`").
- Confirm whether `vpc_endpoint` also applies when `endpoint_type: mantle` (a Mantle PrivateLink endpoint), or only to Runtime.
- Confirm that serverless and Dedicated Cloud Gateways can't use this (PrivateLink reachability), or document how they can.
{% endcomment %}

For a complete walkthrough, see [Connect to Amazon Bedrock through a VPC endpoint](/ai-gateway/connect-to-bedrock-through-vpc-endpoint/).
