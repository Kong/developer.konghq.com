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

The AI AWS Guardrails plugin allows users to enforce introspection in both inbound requests and outbound responses that will be handled by [AI Proxy](/plugins/ai-proxy/) plugin by integrating with [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/) service. It acts as a gatekeeper at the gateway level, ensuring that any data exchanged between clients and upstream LLM services adheres to user-configured compliance and security policies.
Users should configure the policies they need in adavanced on AWS.
The plugin provides a configurable `response_buffer_size` parameter for the response guard which determines the amount of token receiving in streaming from LLM upstream to be buffered before sending it to AWS guardrails service.

## Format

This plugin works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode), and is able to
compose an Azure Content Safety text check by compiling all chat history, or just the `'user'` content.