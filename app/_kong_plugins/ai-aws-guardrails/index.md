---
title: 'AI AWS Guardrails'
name: 'AI AWS Guardrails'

tier: ai_gateway_enterprise
content_type: plugin

publisher: kong-inc
description: 'Use AWS Guardrails to validate requests and/or responses in the AI Proxy plugin before forwarding them between clients and upstream LLMs.'

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.11'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-aws-guardrails.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - moderation

related_resources:
  - text: Use the AI AWS Guardrails plugin
    url: /how-to/use-ai-aws-guardrails-plugin/
---

The **AI AWS Guardrails** plugin enforces introspection on both inbound requests and outbound responses handled by the [AI Proxy](/plugins/ai-proxy/) plugin. It integrates with the [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/) service to apply compliance and safety policies at the gateway level. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

## Prerequisites

Before using the AI AWS Guardrails plugin, you must define your guardrail policies in AWS. You can do this through:

* The [AWS Console](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-create.html)
* The [CreateGuardrail API](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_CreateGuardrail.html)

## Overview

The plugin includes a configurable [`response_buffer_size`](/plugins/ai-aws-guardrails/reference/#schema--config-response-buffer-size) parameter. This setting controls how many tokens from the upstream LLM response are buffered during streaming before being sent to the AWS Guardrails service for inspection. For example, setting `response_buffer_size` to `50` means the plugin will collect 50 tokens from the upstream model before sending them to AWS Guardrails for evaluation. Guardrail evaluation runs in chunks as tokens stream in.

{:.info}
> A smaller buffer size allows faster policy evaluation and quicker response rejection but may increase the number of guardrail calls. Larger sizes reduce API calls but may delay policy enforcement.

For response and request inspection, the plugin by default guards input only. You can change this behavior with the [`guarding_mode`](/plugins/ai-aws-guardrails/reference/#schema--config-guarding-mode) field, which supports `INPUT`, `OUTPUT`, or `BOTH`. To control which parts of the conversation are sent for content evaluation, use the [`text_source`](/plugins/ai-aws-guardrails/reference/#schema--config-text-source) field. Set it to `concatenate_user_content` to inspect only `user` input, or `concatenate_all_content` to include the full exchange, including system and assistant messages.

## Format

This plugin works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode).

## AWS IAM roles {% new_in 3.12 %}

The AI AWS Guardrails plugin supports AWS Identity and Access Management (IAM) roles. This allows the AWS Bedrock Guardrails service to be accessed using role assumption instead of static credentials.

To use AWS IAM roles with the plugin, set the `config.aws_assume_role_arn`, `config.aws_role_session_name`, and `config.aws_role_session_name`. For an example, see [Use IAM role assumption](/plugins/ai-aws-guardrails/examples/use-iam-role/).

{:.info}
> **Note:** These fields can be used with or without static AWS credentials (`config.aws_access_key_id` and `config.aws_secret_access_key`).

