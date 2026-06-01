---
title: AI Consumers
content_type: reference
entities:
  - ai-consumer
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
permalink: /ai-gateway/entities/ai-consumer/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "Consumers for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumer
works_on:
  - konnect
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Consumer Credential entity
    url: /ai-gateway/entities/ai-consumer-credential/
  - text: Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.base_gateway}} Consumer entity"
    url: /gateway/entities/consumer/
faqs:
  - q: How is an {{site.ai_gateway}} Consumer different from a {{site.base_gateway}} Consumer?
    a: |
      The runtime entity is a regular Kong Consumer. The {{site.ai_gateway}} surface uses the
      {{site.ai_gateway}} entity convention (`display_name`, `name`, `labels`), requires an
      authentication `type` field, accepts inline Consumer Group assignment, and lets you
      reference Policies. Credentials are managed as a separate sub-entity rather than embedded
      on the Consumer.

  - q: How do I add credentials to an AI Consumer?
    a: |
      Credentials are a separate sub-entity, not a field on the Consumer. Create them under the
      Consumer's nested credentials endpoint. See the
      [Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference.

  - q: "What's the difference between `type: api-key` and `type: oauth`?"
    a: |
      The `type` declares which credential family the Consumer authenticates with. An `api-key`
      Consumer holds one or more `api-key` Credentials. An `oauth` Consumer holds one or more
      `oauth` Credentials whose `custom_id` maps to the OAuth provider's identifier. The
      Credential's `type` must match the Consumer's `type`.

  - q: Can a Consumer belong to multiple Consumer Groups?
    a: |
      Yes. The `consumer_groups` array accepts one or more references to Consumer Groups by
      `name` or `id`.

  - q: How do I attach Policies to a Consumer?
    a: |
      Add the Policy's `name` or `id` to the Consumer's `policies` array.
      See the [Policy entity](/ai-gateway/entities/ai-policy/) reference.
---

## What is a Consumer?

A Consumer is the {{site.ai_gateway}} entity that represents a downstream client of the AI APIs you publish through {{site.ai_gateway}}.

You can use Consumers and Consumer Groups to authenticate clients, attach Policies, and gate access to Models, Agents, and MCP Servers through those parent entities' `acls` field.

Consumers can be created and managed through the {{site.konnect_short_name}} UI, the {{site.ai_gateway}} API, or decK:

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

## Configure a Consumer

When you create a Consumer, the configuration steps generally follow this order:

1. Choose an authentication `type`: `api-key` for API key credentials, or `oauth` for OAuth 2.0 / OpenID Connect credentials.
1. Optionally assign the Consumer to one or more Consumer Groups through the `consumer_groups` array.
1. Optionally attach Policies to the Consumer for request-level plugin execution.
1. Create credentials separately through the [Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/).

For a concrete example, see [Set up a Consumer](#set-up-a-consumer).

## Authentication type

The `type` field declares which credential family the Consumer authenticates with. Supported values are:

* `api-key`: the Consumer authenticates with one or more API key Credentials.
* `oauth`: the Consumer authenticates through an OAuth identity issued by an external OIDC provider. {{site.ai_gateway}} accepts any standards-compliant OAuth 2.0 / OpenID Connect provider configured through the [OpenID Connect plugin](/plugins/openid-connect/), or, for MCP traffic, through the [AI MCP OAuth2 plugin](/plugins/ai-mcp-oauth2/). The Consumer Credential carries a `custom_id` that maps to the OAuth provider's user identifier (for example, an OIDC Client ID or `sub` claim).

The `type` of every Credential issued to the Consumer must match the Consumer's `type`. See the [Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/) reference for credential management.

## Consumer Group membership

You can assign a Consumer to one or more Consumer Groups through the `consumer_groups` array. Each entry references a Consumer Group by `name` or `id`.

Consumer Groups are managed through their own entity surface. See the [Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) reference.

## Attach Policies

Policies are how plugin configurations apply to a Consumer. Attach a Policy by adding its `name` or `id` to the Consumer's `policies` array. The underlying plugin runs in the request lifecycle when the Consumer is identified.

You can attach multiple Policies to a single Consumer. Each Policy is an independent plugin instance.

For the supported plugin types and how Policies attach to other entities, see the [Policy entity](/ai-gateway/entities/ai-policy/) reference.

## Set up a Consumer

The following example creates an AI Consumer assigned to a single Consumer Group. Credentials are issued separately through the [Consumer Credential entity](/ai-gateway/entities/ai-consumer-credential/).

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
