---
title: AI Consumers
content_type: reference
entities:
  - ai-consumer
products:
  - ai-gateway
description: "Consumers for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumer
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Consumer Credential entity
    url: /ai-gateway/entities/consumer-credential/
  - text: Consumer Group entity
    url: /ai-gateway/entities/consumer-group/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
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
      [Consumer Credential entity](/ai-gateway/entities/consumer-credential/) reference.

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
      See the [Policy entity](/ai-gateway/entities/policy/) reference.
---

## What is a Consumer?

A Consumer is the {{site.ai_gateway}} entity that represents a downstream client of the AI APIs you publish through {{site.ai_gateway}}.

You can use Consumers and Consumer Groups to authenticate clients, attach Policies, and gate access to Models, Agents, and MCP Servers through those parent entities' `acls` field.

Consumers are managed through the {{site.ai_gateway}} entity API surface in both deployment modes:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumers
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/consumers
{% endtable %}

## Authentication type

The `type` field declares which credential family the Consumer authenticates with. Supported values are:

* `api-key`: the Consumer authenticates with one or more API key Credentials.
* `oauth`: the Consumer authenticates with one or more OAuth Credentials whose `custom_id` maps to the OAuth provider's identifier.

The `type` of every Credential issued to the Consumer must match the Consumer's `type`. See the [Consumer Credential entity](/ai-gateway/entities/consumer-credential/) reference for credential management.

## Consumer Group membership

You can assign a Consumer to one or more Consumer Groups through the `consumer_groups` array. Each entry references a Consumer Group by `name` or `id`.

Consumer Groups are managed through their own entity surface. See the [Consumer Group entity](/ai-gateway/entities/consumer-group/) reference.

## Attach Policies

A Policy is an {{site.ai_gateway}} entity that triggers an action using a plugin. You can attach a Policy to a Consumer and the underlying plugin will run in the request lifecycle when this Consumer is identified. To attach a Policy, add the Policy's `name` or `id` to the Consumer's `policies` array.

You can attach multiple Policies to a single Consumer. Each Policy is an independent instance.

For the supported plugin types and how Policies attach to other entities, see the [Policy entity](/ai-gateway/entities/policy/) reference.

## Set up a Consumer

The following example creates an AI Consumer assigned to a single Consumer Group. Credentials are issued separately through the [Consumer Credential entity](/ai-gateway/entities/consumer-credential/).

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
