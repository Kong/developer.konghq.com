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
      reference AI Policies.

  - q: How do I add credentials to an AI Consumer?
    a: |
      For `type: api-key` AI Consumers, credentials are managed through a separate credentials
      endpoint, not as a field on the Consumer. Create them via POST to `/consumers/{id}/credentials`.
      `type: oauth` AI Consumers don't use this endpoint — see the next question.

  - q: "What's the difference between `type: api-key` and `type: oauth`?"
    a: |
      The `type` declares how the AI Consumer authenticates. An `api-key` AI Consumer holds one or
      more `api-key` Credentials created through the credentials endpoint. An `oauth` AI Consumer
      has no Credentials — instead, its own `custom_id` field is set (at creation or update time) to
      the identifier your OIDC provider issues (for example, a `sub` claim), and an authentication
      policy maps the incoming token to that AI Consumer.

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

<!-- vale off -->
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
<!-- vale on -->

## Manage AI Consumers

AI Consumers can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/consumers`
* [kongctl](/kongctl/)

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
    use_case: Federated identity with an external OIDC provider. {{site.ai_gateway}} accepts any standards-compliant OAuth 2.0 / OpenID Connect provider configured through the [OpenID Connect Policy](/ai-gateway/policies/openid-connect/), or for MCP traffic through the [AI MCP OAuth2 Policy](/ai-gateway/policies/ai-mcp-oauth2/). The AI Consumer's own `custom_id` field maps to the OAuth provider's user identifier (for example, an OIDC Client ID or `sub` claim).
{% endtable %}
<!-- vale on -->

`api-key` AI Consumers authenticate through one or more `api-key` Credentials created via the credentials endpoint. `oauth` AI Consumers don't have Credentials — set `custom_id` directly on the AI Consumer instead.

## AI Consumer Group membership

To apply AI Policies and access controls to multiple AI Consumers at once, organize them into AI Consumer Groups. An AI Consumer can belong to multiple AI Consumer Groups, letting you manage access controls by team, application, or environment without duplicating configurations.

Manage AI Consumer Group membership through the [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/).

## Attach Policies

To enforce governance, security, or observability controls at the AI Consumer level, attach AI Policies. When an AI Consumer makes a request, {{site.ai_gateway}} applies any AI Policies attached to that AI Consumer before routing the request.

Attach an AI Policy by adding its `name` or `id` to the AI Consumer's [`policies`](#schema-aigateway-consumer-policies) array. You can attach multiple AI Policies to a single AI Consumer — each AI Policy runs independently, allowing you to layer controls for rate limiting, request validation, PII redaction, and other governance needs.

For supported policy types and how AI Policies attach to other entities, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference or browse all available AI Policies in the [AI policies hub](/ai-gateway/policies/).

## Set up an AI Consumer

{% navtabs "consumer_type" %}
{% navtab "api-key" %}

The following example creates an `api-key` AI Consumer assigned to a single AI Consumer Group. After creating it, add one or more API key Credentials (see [Create Consumer Credentials](#create-consumer-credentials) below).

{% entity_example %}
type: consumer
data:
  display_name: Mobile App - Production
  name: mobile-app-production
  type: api-key
  policies: []
{% endentity_example %}

{% endnavtab %}
{% navtab "oauth" %}

The following example creates an `oauth` AI Consumer. Set `custom_id` to the identifier your OIDC provider issues (for example, a `sub` claim) — this is how {{site.ai_gateway}} maps an incoming token to this AI Consumer. `oauth` AI Consumers don't have Credentials.

{% entity_example %}
type: consumer
data:
  display_name: OAuth User 1
  name: oauth-user-1
  type: oauth
  custom_id: user-id-from-oidc-provider
  policies: []
{% endentity_example %}

{% endnavtab %}
{% endnavtabs %}

## Create Consumer Credentials

After creating an `api-key` AI Consumer, create one or more Credentials for authentication. Credentials are managed through a separate endpoint and only support `type: api-key` — `oauth` AI Consumers authenticate through their `custom_id` field instead (see [Set up an AI Consumer](#set-up-an-ai-consumer) above).

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Mobile App Key 1
  name: mobile-app-key-1
  type: api-key
{% endkonnect_api_request %}
<!-- vale on -->

The response includes the generated `api_key` value. Store this securely — it cannot be retrieved later.

## Schema

{% entity_schema %}
