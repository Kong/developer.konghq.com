---
title: AI Consumer Groups
content_type: reference
entities:
  - ai-consumer-group
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-consumer-group/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Consumer Groups for {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumerGroup
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.base_gateway}} Consumer Group entity"
    url: /gateway/entities/consumer-group/
faqs:
  - q: How is an {{site.ai_gateway}} Consumer Group different from a {{site.base_gateway}} Consumer Group?
    a: |
      The runtime entity is a regular Kong Consumer Group. The {{site.ai_gateway}} surface adds
      the entity convention ([`display_name`](#schema-aigateway-consumer-group-display-name), [`name`](#schema-aigateway-consumer-group-name), [`labels`](#schema-aigateway-consumer-group-labels)) and a required [`policies`](#schema-aigateway-consumer-group-policies) array
      for attaching policies at the group scope.

  - q: Can I edit the underlying Kong Consumer Group that {{site.ai_gateway}} generates?
    a: |
      No. The generated Kong Consumer Group is protected from direct modification through the
      standard `/consumer-groups` Admin API. Update the AI Consumer Group instead.

  - q: How do I assign a Consumer to a Consumer Group?
    a: |
      You add a Consumer to a Consumer Group through the Consumer Group entity.
      See the [Consumer entity](/ai-gateway/entities/ai-consumer/) and
      [Consumer Group entity](/ai-gateway/entities/ai-consumer-group/) references.

  - q: Can a Consumer belong to multiple Consumer Groups?
    a: |
      Yes. The Consumer's `consumer_groups` array accepts one or more references.

  - q: How do I attach Policies to a Consumer Group?
    a: |
      Add the Policy's `name` or `id` to the Consumer Group's [`policies`](#schema-aigateway-consumer-group-policies) array.
      The policy runs when a member of the group is identified during a request.
      See the [Policy entity](/ai-gateway/entities/ai-policy/) reference.

  - q: How do I gate access to an AI Model, AI Agent, or AI MCP Server with an AI Consumer Group?
    a: |
      Add the AI Consumer Group's name to the parent entity's `acls.allow` or `acls.deny` list.
      ACLs accept AI Consumer, AI Consumer Group, and Authenticated Group names.
      See the [AI Model entity](/ai-gateway/entities/ai-model/) reference.
---

## What is an AI Consumer Group?

An AI Consumer Group is the {{site.ai_gateway}} entity that represents a collection of AI Consumers grouped for the purpose of applying shared AI Policies and access controls.

Use AI Consumer Groups to scope group-wide behavior, such as rate limits, prompt guards, or content moderation, without configuring each AI Consumer individually. AI Consumer Groups can appear in the `acls` field of AI Model, AI Agent, and AI MCP Server entities, where they gate access to those parent entities.

AI Consumer Groups can be created and managed through the {{site.konnect_short_name}} UI, the {{site.ai_gateway}} API, or decK:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumer-groups
{% endtable %}

## Membership

Membership is managed through the [AI Consumer entity](/ai-gateway/entities/ai-consumer/). Add an AI Consumer to one or more AI Consumer Groups by setting the `consumer_groups` array on the AI Consumer. A single AI Consumer can belong to multiple AI Consumer Groups.

For AI Consumer configuration details, see the [AI Consumer entity](/ai-gateway/entities/ai-consumer/) reference.

## Attach AI Policies

AI Policies attached to an AI Consumer Group run when a member of that group is identified during a request. To attach an AI Policy, add its `name` or `id` to the AI Consumer Group's [`policies`](#schema-aigateway-consumer-group-policies) array.

You can attach multiple AI Policies to a single AI Consumer Group with different configurations, and each runs independently.

For supported policy types and how AI Policies attach to other entities, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

## Use in parent entity ACLs

The `acls` field on AI Model, AI Agent, and AI MCP Server entities accepts AI Consumer Group names alongside AI Consumer and Authenticated Group names. Add an AI Consumer Group to a parent entity's `acls.allow` list to permit its members access, or to `acls.deny` to block them.

AI Consumer Group membership is resolved after the request is authenticated and the AI Consumer is identified.

## Set up an AI Consumer Group

The following example creates an AI Consumer Group with one attached AI Policy that applies a shared rate limit to its members.

{% entity_example %}
type: consumer_group
data:
  display_name: Internal Teams
  name: internal-teams
  policies:
    - rate-limiting
{% endentity_example %}

## Schema

{% entity_schema %}
