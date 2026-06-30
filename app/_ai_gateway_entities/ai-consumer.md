---
title: AI Consumers
content_type: reference
entities:
  - ai-consumer
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-consumer/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "AI Consumers for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumer
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Consumer Credential entity
    url: /ai-gateway/entities/ai-consumer-credential/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.base_gateway}} Consumer entity"
    url: /gateway/entities/consumer/
faqs:
  - q: How is an AI Consumer different from a {{site.base_gateway}} Consumer?
    a: |
      The runtime entity is a regular Kong Consumer. The {{site.ai_gateway}} surface uses the
      {{site.ai_gateway}} entity convention ([`display_name`](#schema-aigateway-consumer-display-name), [`name`](#schema-aigateway-consumer-name), [`labels`](#schema-aigateway-consumer-labels)), requires an
      authentication [`type`](#schema-aigateway-consumer-type) field, accepts inline AI Consumer Group assignment, and lets you
      reference AI Policies. Credentials are managed as a separate sub-entity rather than embedded
      on the AI Consumer.

  - q: How do I add credentials to an AI Consumer?
    a: |
      Credentials are a separate sub-entity, not a field on the AI Consumer. Create them under the
      Consumer's nested credentials endpoint. See the
      [AI Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference.

  - q: "What's the difference between `type: api-key` and `type: oauth`?"
    a: |
      The `type` declares which credential family the AI Consumer authenticates with. An `api-key`
      AI Consumer holds one or more `api-key` Credentials. An `oauth` AI Consumer holds one or more
      `oauth` Credentials whose `custom_id` maps to the OAuth provider's identifier. The
      Credential's `type` must match the Consumer's `type`.

  - q: Can an AI Consumer belong to multiple AI Consumer Groups?
    a: |
      Yes. An AI Consumer can be added to multiple AI Consumer Groups through the AI Consumer Group entity.
      See the [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) reference.

  - q: How do I attach AI Policies to an AI Consumer?
    a: |
      Add the Policy's `name` or `id` to the AI Consumer's [`policies`](#schema-aigateway-consumer-policies) array.
      See the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.
---

## What is an AI Consumer?

An AI Consumer is the {{site.ai_gateway}} entity that identifies an external client consuming or using the AI APIs you publish through {{site.ai_gateway}}. Consumers can represent applications, services, or users who interact with your AI Models, AI Agents, and AI MCP Servers.

AI Consumers are essential for controlling access to your AI APIs, tracking usage, and ensuring security. They are identified through authentication credentials (API keys or OAuth), allowing {{site.ai_gateway}} to authenticate requests and apply Consumer-specific controls. By creating AI Consumers and organizing them into AI Consumer Groups, you can manage access controls at scale, attach AI Policies for governance and security, and monitor token usage per Consumer.

## Use cases for AI Consumers

Common use cases for enforcing controls at the AI Consumer level:

{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: Model access control
    description: Control which clients can access which AI Models, restricting access by team, application tier, or use case.
  - use_case: AI safety and guardrails
    description: Apply prompt validation, PII detection, and content filtering at the AI Consumer level using AI Policies.
  - use_case: Token and cost control
    description: Apply per-consumer rate limits and quotas to prevent token overages and control costs by AI Consumer tier.
  - use_case: AI request transformation
    description: Normalize or transform AI requests and responses per AI Consumer (for example, format prompts, inject system instructions, sanitize outputs).
  - use_case: Audit and compliance
    description: Track which clients are using which AI Models, monitor for policy violations, and maintain audit logs for compliance and analytics.
{% endtable %}

## Manage AI Consumers

AI Consumers can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/consumers`

For configuration examples and step-by-step setup instructions, see [Set up an AI Consumer](#set-up-an-ai-consumer) below.

## Authentication type

Choose an authentication method based on your deployment needs. Set the [`type`](#schema-aigateway-consumer-type) field to declare which credential family AI Consumers will use:

<!-- vale off -->
{% table %}
columns:
  - title: Type
    key: type
  - title: Use case
    key: use_case
rows:
  - type: "`api-key`"
    use_case: Simple, stateless authentication for internal services or mobile apps using a shared secret.
  - type: "`oauth`"
    use_case: Federated identity with an external OIDC provider. {{site.ai_gateway}} accepts any standards-compliant OAuth 2.0 / OpenID Connect provider configured through the [OpenID Connect policy](/ai-gateway/policies/openid-connect/), or for MCP traffic through the [AI MCP OAuth2 policy](/ai-gateway/policies/ai-mcp-oauth2/). The AI Consumer Credential carries a `custom_id` that maps to the OAuth provider's user identifier (for example, an OIDC Client ID or `sub` claim).
{% endtable %}
<!-- vale on -->

The `type` of every Credential issued to the Consumer must match the Consumer's `type`. See the [AI Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference for credential management.

## AI Consumer Group membership

To apply AI Policies and access controls to multiple AI Consumers at once, organize them into AI Consumer Groups. An AI Consumer can belong to multiple AI Consumer Groups, letting you manage access controls by team, application, or environment without duplicating configurations.

Manage AI Consumer Group membership through the [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) reference.

## Attach Policies

To enforce governance, security, or observability controls at the AI Consumer level, attach AI Policies. When an AI Consumer makes a request, {{site.ai_gateway}} applies any AI Policies attached to that Consumer before routing the request.

Attach an AI Policy by adding its `name` or `id` to the AI Consumer's [`policies`](#schema-aigateway-consumer-policies) array. You can attach multiple AI Policies to a single Consumer — each AI Policy runs independently, allowing you to layer controls for rate limiting, request validation, PII redaction, and other governance needs.

For supported policy types and how AI Policies attach to other entities, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference or browse all available AI Policies in the [AI policies hub](/ai-gateway/policies/).

## Set up an AI Consumer

The following example creates an AI Consumer assigned to a single AI Consumer Group. Credentials are issued separately through the [AI Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/).

{% entity_example %}
type: consumer
data:
  display_name: Mobile App - Production
  name: mobile-app-production
  type: api-key
  consumer_groups:
    - internal-teams
  policies: []
{% endentity_example %}

## Schema

{% entity_schema %}
