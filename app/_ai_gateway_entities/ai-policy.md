---
title: AI Policies
content_type: reference
entities:
  - ai-policy
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-policy/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "AI Policies for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayPolicy
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/

faqs:
  - q: Are AI Policies shared across multiple entities?
    a: |
      No. Each AI Policy is an independent configuration. To apply the same
      configuration to two AI Models, create two AI Policies with matching `config`,
      one per AI Model.

  - q: How is an AI Policy different from a plugin?
    a: |
      An AI Policy is a policy configuration created through the {{site.ai_gateway}} entity surface
      instead of the classic `/plugins` endpoint. The runtime effect is the same: a policy attached
      at the appropriate scope. {{site.ai_gateway}} manages the AI Policy's lifecycle alongside the
      entity it's attached to.

  - q: Can an AI Policy be scoped to an AI Consumer or AI Consumer Group?
    a: |
      Yes. Add the AI Policy's `name` or `id` to the AI Consumer's or AI Consumer Group's `policies` array.
      The Policy runs when the AI Consumer is identified during a request, or when a member of the
      AI Consumer Group is identified.

  - q: What happens to an AI Policy when its parent entity is deleted?
    a: |
      Standalone AI Policies referenced from parent entities through a `policies` array are independent
      and aren't deleted when a referencing parent is deleted. The reference is simply removed.
---

## What is an AI Policy?

Create an AI Policy when you want to add governance, security, transformation, or observability to {{site.ai_gateway}} traffic:
- Attach [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) to redact sensitive data
- Attach [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) to manage request volume
- Attach [AI Prompt Guard](/ai-gateway/policies/prompt-guard/) or [other guardrail Policies](/ai-gateway/#guardrails-and-content-safety) to validate prompts
- Attach [logging policies](/ai-gateway/policies/?category=logging) to track requests and responses for observability
- Attach authentication policies like [OpenID Connect](/ai-gateway/policies/openid-connect/) to control access and verify identity

**Each AI Policy is independent.** To apply the same configuration across multiple entities, create separate policies for each one. This ensures that deleting an entity deletes only its own policies—not configurations shared with other parts of your gateway.

{:.info}
> For the complete set of available policy types and configurations, see the [AI policies hub](/ai-gateway/policies/).

## Manage AI Policies

AI Policies are managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/policies`

For configuration examples and step-by-step setup instructions, see [Set up a global AI Policy](#set-up-a-global-ai-policy) below.

## AI Policy scopes

An AI Policy's scope is determined by where it's referenced. Each AI Policy is an independent configuration that applies at exactly one scope: globally, or to a specific entity (AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group). To apply identical configuration in multiple places, create one AI Policy per target.

The available scopes are:

* **Global**: An AI Policy with no parent entity reference applies to all {{site.ai_gateway}} traffic on the data plane. Non-AI traffic on the same data plane isn't affected.

* **Entity-scoped**: Reference the policy from the `policies` array on an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), [AI Consumer](/ai-gateway/entities/ai-consumer/), or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) entity. The policy applies at that entity's scope.

{:.info}
> For each policy type, find its configuration schema and required fields on that policy's reference page in the [AI policies hub](/ai-gateway/policies/). Configuration is specific to each policy type.

## Set up a global AI Policy

An AI Policy specifies a `type` (like AI Sanitizer or AI Rate Limiting Advanced) and a `config` block that configures that behavior. {{site.ai_gateway}} applies the policy at the scope you choose: globally across all traffic, or scoped to a specific AI Model, AI Agent, AI MCP Server, AI Consumer, or AI Consumer Group.

The following example creates a global PII sanitizer AI Policy that runs for every {{site.ai_gateway}} route. It anonymizes high-risk PII categories (email, phone, SSN, and credit cards) along with custom patterns for sensitive tokens like AWS API keys and GitHub tokens.

{% entity_example %}
type: policy
data:
  display_name: PII Sanitizer - Global
  name: pii-sanitizer-global
  type: ai-sanitizer
  enabled: true
  global: true
  config:
    anonymize:
      - email
      - phone
      - ssn
      - creditcard
      - custom
    custom_patterns:
      - name: aws_api_key
        regex: AKIA[0-9A-Z]{16}
        score: 0.95
      - name: github_token
        regex: ghp_[A-Za-z0-9]{36}
        score: 0.9
    host: sanitizer-service.internal
    port: 8080
    redact_type: placeholder
    stop_on_error: true
    recover_redacted: false
{% endentity_example %}

## Schema

{% entity_schema %}
