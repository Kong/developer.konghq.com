---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Use AWS Guardrails to validate requests and/or responses before forwarding them between clients and upstream LLMs.'
categories:
  - ai
tags:
  - ai
  - safety
related_resources:
  - text: Use the AI AWS Guardrails Policy
    url: /ai-gateway/how-to/use-ai-aws-guardrails-policy/
---


The AI AWS Guardrails Policy enforces introspection on both inbound requests and outbound responses handled by the [AI Model](/ai-gateway/entities/ai-model/) entity. It integrates with the [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/) service to apply compliance and safety policies at the {{site.ai_gateway}} level. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

## Prerequisites

Before using the AI AWS Guardrails Policy, you must define your guardrail policies in AWS. You can do this through:

* The [AWS Console](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-components.html)
* The [CreateGuardrail API](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_CreateGuardrail.html)

## How it works

The AI AWS Guardrails Policy includes a configurable [`response_buffer_size`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-response-buffer-size) parameter. This setting controls how many tokens from the upstream LLM response are buffered during streaming before being sent to the AWS Guardrails service for inspection. For example, setting `response_buffer_size` to `50` means the AI AWS Guardrails Policy will collect 50 tokens from the upstream model before sending them to AWS Guardrails for evaluation. Guardrail evaluation runs in chunks as tokens stream in.

{:.info}
> A smaller buffer size allows faster policy evaluation and quicker response rejection but may increase the number of guardrail calls. Larger sizes reduce API calls but may delay policy enforcement.

For response and request inspection, the Policy by default guards input only. You can change this behavior with the [`guarding_mode`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-guarding-mode) field, which supports `INPUT`, `OUTPUT`, or `BOTH`. To control which parts of the conversation are sent for content evaluation, use the [`text_source`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-text-source) field. Set it to `concatenate_user_content` to inspect only `user` input, or `concatenate_all_content` to include the full exchange, including system and assistant messages.

## Rejection modes

When the Policy blocks a request or response, what the caller receives depends on the rejection mode.

{% include_cached md/ai-gateway/v2/guardrail-rejection-modes.md name=page.name %}

In `none` mode, the error message is the blocked message that you configured for the guardrail in AWS, for example:

```json
{
  "error": {
    "message": "Blocked by AWS guardrail (input)"
  }
}
```

In `verbose` mode, `reason` is the same blocked message, and `detail` is the list of assessments that AWS Bedrock Guardrails returned for the content. The assessments depend on which guardrail policies matched. For example, a request that contains a word from a custom word filter returns the following response:

```json
{
  "error": {
    "type": "guardrail_rejected",
    "plugin": "ai-aws-guardrails",
    "reason": "Blocked by AWS guardrail (input)",
    "code": "GUARDRAIL_BLOCKED",
    "detail": [
      {
        "appliedGuardrailDetails": {
          "guardrailId": "dlk3bhgw5pms",
          "guardrailVersion": "DRAFT",
          "guardrailArn": "arn:aws:bedrock:us-east-1:123456789012:guardrail/dlk3bhgw5pms",
          "guardrailOrigin": ["REQUEST"],
          "guardrailOwnership": "SELF"
        },
        "wordPolicy": {
          "customWords": [
            {
              "match": "bananaphone",
              "action": "BLOCKED",
              "detected": true
            }
          ]
        }
      }
    ]
  }
}
```

{:.warning}
> In `verbose` mode, the `detail` field includes the guardrail ARN, which contains your AWS account ID, along with the matched content. Only use `verbose` mode for clients that you trust with this information.

To return this response, set `config.rejection_mode` to `verbose`:

{% entity_example %}
type: policy
data:
  display_name: AI AWS Guardrails - Verbose Rejection
  name: ai-aws-guardrails
  type: ai-aws-guardrails
  config:
    aws_region: us-east-1
    guardrails_id: YOUR_GUARDRAIL_ID
    guardrails_version: DRAFT
    aws_access_key_id: ${aws_access_key_id}
    aws_secret_access_key: ${aws_secret_access_key}
    rejection_mode: verbose
variables:
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
    description: The AWS access key ID of an IAM identity with the `bedrock:ApplyGuardrail` permission.
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
    description: The AWS secret access key of the IAM identity.
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Detect without blocking

{% include_cached md/ai-gateway/v2/guardrail-continue-on-detection.md name=page.name logs_detection=true %}

## Format

This Policy works with all of the AI Model entity's [`model.capabilities` settings](/ai-gateway/entities/ai-model/#capabilities).

## AWS IAM roles

The AI AWS Guardrails Policy supports AWS Identity and Access Management (IAM) roles. This allows the AWS Bedrock Guardrails service to be accessed using role assumption instead of static credentials.

To use AWS IAM roles with the Policy, set the [`config.aws_assume_role_arn`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-aws-assume-role-arn), and [`config.aws_role_session_name`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-aws-role-session-name).

{:.info}
> **Note:** These fields can be used with or without static AWS credentials (`config.aws_access_key_id` and `config.aws_secret_access_key`).

## TLS verification

[`config.ssl_verify`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-ssl-verify) is enabled by default. The Policy verifies the TLS certificate when connecting to the AWS Bedrock service. To disable this, set `ssl_verify: false`.

## Logging

The AI AWS Guardrails Policy emits structured log data for every inspected request and response. For the full list of log fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/#ai-aws-guardrails-logs).

To log the raw content of blocked requests and responses, enable [`config.log_blocked_content`](/ai-gateway/policies/ai-aws-guardrails/reference/#schema--config-log-blocked-content). When enabled, the blocked prompt or response body appears under `ai.proxy.aws-guardrails.input_faulty_prompt` and `ai.proxy.aws-guardrails.output_faulty_response` in each log entry.

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}