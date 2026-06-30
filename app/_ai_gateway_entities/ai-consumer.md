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
      on the Consumer.

  - q: How do I add credentials to an AI Consumer?
    a: |
      Credentials are a separate sub-entity, not a field on the Consumer. Create them under the
      Consumer's nested credentials endpoint. See the
      [AI Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference.

  - q: "What's the difference between `type: api-key` and `type: oauth`?"
    a: |
      The `type` declares which credential family the Consumer authenticates with. An `api-key`
      Consumer holds one or more `api-key` Credentials. An `oauth` Consumer holds one or more
      `oauth` Credentials whose `custom_id` maps to the OAuth provider's identifier. The
      Credential's `type` must match the Consumer's `type`.

  - q: Can an AI Consumer belong to multiple AI Consumer Groups?
    a: |
      Yes. An AI Consumer can be added to multiple AI Consumer Groups through the AI Consumer Group entity.
      See the [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) reference.

  - q: How do I attach AI Policies to an AI Consumer?
    a: |
      Add the Policy's `name` or `id` to the Consumer's [`policies`](#schema-aigateway-consumer-policies) array.
      See the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.
---

## What is an AI Consumer?

An AI Consumer is the {{site.ai_gateway}} entity that represents a downstream client of the AI APIs you publish through {{site.ai_gateway}}.

You can use AI Consumers and AI Consumer Groups to authenticate clients, attach AI Policies, and gate access to AI Models, AI Agents, and AI MCP Servers through those parent entities' `acls` field.

AI Consumers can be created and managed through the {{site.konnect_short_name}} UI and the {{site.ai_gateway}} API:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumers
{% endtable %}

## Authentication type

The [`type`](#schema-aigateway-consumer-type) field declares which credential family the Consumer authenticates with. Supported values are:

* `api-key`: the Consumer authenticates with one or more API key Credentials.
* `oauth`: the Consumer authenticates through an OAuth identity issued by an external OIDC provider. {{site.ai_gateway}} accepts any standards-compliant OAuth 2.0 / OpenID Connect provider configured through the [OpenID Connect policy](/ai-gateway/policies/openid-connect/), or, for MCP traffic, through the [AI MCP OAuth2 policy](/ai-gateway/policies/ai-mcp-oauth2/). The AI Consumer Credential carries a `custom_id` that maps to the OAuth provider's user identifier (for example, an OIDC Client ID or `sub` claim).

The `type` of every Credential issued to the Consumer must match the Consumer's `type`. See the [AI Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference for credential management.

## AI Consumer Group membership

An AI Consumer can belong to multiple AI Consumer Groups. AI Consumer Group membership is managed through the AI Consumer Group entity. See the [AI Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) reference for how to assign AI Consumers to groups.

## Attach Policies

Attach a Policy by adding its `name` or `id` to the Consumer's [`policies`](#schema-aigateway-consumer-policies) array. The policy runs in the request lifecycle when the Consumer is identified.

You can attach multiple Policies to a single Consumer. Each Policy runs independently.

For supported policy types and how Policies attach to other entities, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

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
