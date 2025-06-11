---
title: 'AI AWS Guardrails'
name: 'AI AWS Guardrails'

ai_gateway_enterprise: true

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
---

The **AI AWS Guardrails** plugin enforces introspection on both inbound requests and outbound responses handled by the [AI Proxy](/plugins/ai-proxy/) plugin. It integrates with the [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/) service to apply compliance and safety policies at the gateway level. This ensures all data exchanged between clients and upstream LLMs adheres to the configured security standards.

{:.info}
> You must configure the required guardrail policies in advance in the [AWS console](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-create.html) or [API](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_CreateGuardrail.html).

## Overview

The plugin includes a configurable [`response_buffer_size`](/plugins/ai-aws-guardrails/reference/unreleased/#schema--config-response-buffer-size) parameter. This setting controls how many tokens from the upstream LLM response are buffered during streaming before being sent to the AWS Guardrails service for inspection. For example, setting `response_buffer_size` to `50` means the plugin will collect 50 tokens from the upstream model before sending them to AWS Guardrails for evaluation. Guardrail evaluation runs in chunks as tokens stream in.

{:.info}
> A smaller buffer size allows faster policy evaluation and quicker response rejection but may increase the number of guardrail calls. Larger sizes reduce API calls but may delay policy enforcement.

For response content inspection, you can also configure the `text_source` field to control which parts of the response are sent to the AWS Guardrails Content Guard Service. This setting determines whether the plugin inspects only the user's input or the full exchange between user and assistant. Use `concatenate_user_content` to focus on user prompts (for example, for prompt restriction policies), or `concatenate_all_content` to apply guardrails across the entire message history, including `system` and `assistant` responses.

## Format

This plugin works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode).