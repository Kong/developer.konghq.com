---
title: Route Claude CLI traffic through {{site.ai_gateway}} and AWS Bedrock
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-bedrock/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
    url: /ai-gateway/use-claude-code-with-ai-gateway-openai/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an AWS Bedrock model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  konnect:
     - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE
       value: 2m
  inline:
    - title: AWS Bedrock
      content: |
        1. Enable model access in AWS Bedrock:
           1. Sign in to the AWS Management Console.
           1. Navigate to Amazon Bedrock.
           1. Select **Model access** in the left navigation.
           1. Request access to Claude models (for example, `us.anthropic.claude-haiku-4-5-20251001-v1:0`).
        1. Create an IAM user with Bedrock permissions:
           1. Navigate to IAM in the AWS Console.
           1. Create a new user or select an existing user.
           1. Attach the `AmazonBedrockFullAccess` policy, or create a custom policy with `bedrock:InvokeModel` permissions.
           1. Create access keys for the user.
        1. Export your AWS credentials and region:
           ```bash
           export AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY_ID'
           export AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
           export AWS_REGION='YOUR_AWS_REGION'
           ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - bedrock

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against an AWS Bedrock model?
  a: Create an AI Provider entity to store your AWS credentials, create an AI Policy that strips fields Claude CLI sends that Bedrock rejects, create an AI Model entity with an Anthropic-compatible format that routes to Bedrock through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

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

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses the following settings:

* `type: bedrock`: Specifies that this provider speaks Bedrock's Messages API format.
* `config.auth.type: aws`: Uses AWS credentials format.

## Create an AI Policy entity

Create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using [request transformer](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that Bedrock's API does not support.

{% entity_examples %}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
{% endentity_examples %}

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see a `400` error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

The AI Policy uses the following settings:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
*  `config.remove.headers`: Removes the `anthropic-beta` header.
*  `config.remove.querystring`: Removes the `beta` query string parameter.
*  `config.remove.body`: Removes the `output_config`, `context_management`, `mcp_servers`, `container`, and `service_tier`body fields.

{:.info}
> Don't strip `model`: {{site.ai_gateway}} uses that field to select the target, and removing it breaks routing.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

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
        access_key_id: !secret {source: !env AWS_ACCESS_KEY_ID}
        secret_access_key: !secret {source: !env AWS_SECRET_ACCESS_KEY}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
ai_gateway_models:
  - ref: my-claude-bedrock
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-claude-bedrock
    display_name: "my-claude-bedrock"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - my-claude-bedrock
    targets:
      - name: us.anthropic.claude-haiku-4-5-20251001-v1:0
        provider: my-aws-account
        config:
          type: bedrock
          region: !env AWS_REGION
    policies:
      - !ref strip-claude-beta-info#name
    capabilities:
      - generate
{% endentity_examples %}

The AI Model uses the following settings:

* `name`/`display_name: my-claude-bedrock`: The identifier you pass to `claude --model`. {{ site.claude_code }} uses this, not the upstream target name, to select the model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively.
* `config.route.paths: [/]`: Configures the base path where this model's routes are accessible.
* `capabilities: [generate]`: Enables text generation. For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `policies`: Attaches the `strip-claude-beta-info` policy created in the previous step, so its header and body transformations apply to every request sent through this model.

## Run {{ site.claude_code }}

{{ site.claude_code }}'s experimental beta features send fields that Bedrock rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: my-claude-bedrock
base_url: http://localhost:8000/
disable_experimental_betas: true
{% endvalidation %}
<!-- vale on -->

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The Madrid Skylitzes is a remarkable 12th-century illuminated Byzantine
manuscript that represents one of the most important surviving examples
of medieval historical documentation. Here are the key details:

What it is

The Madrid Skylitzes is the only surviving illustrated manuscript of John
Skylitzes' "Synopsis of Histories" (Σύνοψις Ἱστοριῶν), which chronicles
Byzantine history from 811 to 1057 CE - covering the period from the death
of Emperor Nicephorus I to the deposition of Michael VI.

Artistic Significance

- 574 miniature paintings (with about 100 lost over time)
- Lavishly decorated with gold leaf, vibrant pigments, and intricate
detailing
- Depicts everything from imperial coronations and battles to daily life
in Byzantium
- The only surviving Byzantine illuminated chronicle written in Greek

Unique Collaboration

The manuscript is believed to be the work of 7 different artists from
various backgrounds:
- 4 Italian artists
- 1 English or French artist
- 2 Byzantine artists
```
{:.no-copy-code}