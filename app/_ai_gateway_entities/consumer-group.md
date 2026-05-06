---
title: AI Consumer Groups
content_type: reference
entities:
  - ai-consumer-group
products:
  - ai-gateway
description: Consumer Groups for {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumerGroup
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
  - text: Consumer entity
    url: /ai-gateway/entities/consumer/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: "{{site.base_gateway}} Consumer Group entity"
    url: /gateway/entities/consumer-group/
faqs:
  - q: How is an {{site.ai_gateway}} Consumer Group different from a {{site.base_gateway}} Consumer Group?
    a: |
      The runtime entity is a regular Kong Consumer Group. The {{site.ai_gateway}} surface adds
      the entity convention (`display_name`, `name`, `labels`) and a required `policies` array
      for attaching plugin instances at the group scope.

  - q: Can I edit the underlying Kong Consumer Group that {{site.ai_gateway}} generates?
    a: |
      No. The generated Kong Consumer Group is protected from direct modification through the
      standard `/consumer-groups` Admin API. Update the AI Consumer Group instead.

  - q: How do I assign a Consumer to a Consumer Group?
    a: |
      Set the `consumer_groups` array on the Consumer entity to reference this group by
      `name` or `id`. Membership is managed from the Consumer side.
      See the [Consumer entity](/ai-gateway/entities/consumer/) reference.

  - q: Can a Consumer belong to multiple Consumer Groups?
    a: |
      Yes. The Consumer's `consumer_groups` array accepts one or more references.

  - q: How do I attach Policies to a Consumer Group?
    a: |
      Add the Policy's `name` or `id` to the Consumer Group's `policies` array.
      The plugin runs when a member of the group is identified during a request.
      See the [Policy entity](/ai-gateway/entities/policy/) reference.

      Unlike Model, Agent, and MCP Server, on-prem does not expose a nested
      `/ai/consumer-groups/{id}/policies` endpoint. The reference-array mechanism is the only
      way to attach a Policy to a Consumer Group in either deployment mode.

  - q: How do I gate access to a Model, Agent, or MCP Server with a Consumer Group?
    a: |
      Add the Consumer Group's name to the parent entity's `acls.allow` or `acls.deny` list.
      ACLs accept Consumer, Consumer Group, and Authenticated Group names.
      See the [Model entity](/ai-gateway/entities/model/) reference.
---

## What is a Consumer Group?

A Consumer Group is the {{site.ai_gateway}} entity that represents a collection of Consumers grouped for the purpose of applying shared Policies and access controls.

Use Consumer Groups to scope group-wide behavior, such as rate limits, prompt guards, or content moderation, without configuring each Consumer individually. Consumer Groups also appear in the `acls` field of Model, Agent, and MCP Server entities, where they gate access to those parent entities.

Consumer Groups are managed through the {{site.ai_gateway}} entity API surface in both deployment modes:

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
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumer-groups
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/consumer-groups
{% endtable %}

## Membership

A Consumer Group doesn't list its members directly. Membership is set on the Consumer entity through the Consumer's `consumer_groups` array. Each entry references a Consumer Group by `name` or `id`. A single Consumer can belong to multiple Consumer Groups.

For the Consumer-side configuration, see the [Consumer entity](/ai-gateway/entities/consumer/) reference.

## Attach Policies

Policies attached to a Consumer Group run when a member of that group is identified during a request. To attach a Policy, add its `name` or `id` to the Consumer Group's `policies` array.

You can attach multiple Policies to a single Consumer Group. Each Policy is an independent plugin instance, so attaching the same plugin type twice with different configurations creates two separate plugin entries.

For the supported plugin types and how Policies attach to other entities, see the [Policy entity](/ai-gateway/entities/policy/) reference.

## Use in parent entity ACLs

The `acls` field on Model, Agent, and MCP Server entities accepts Consumer Group names alongside Consumer and Authenticated Group names. Add a Consumer Group to a parent entity's `acls.allow` list to permit its members access, or to `acls.deny` to block them.

ACLs are evaluated at the Service level of the parent entity's derived primitives. Consumer Group membership is resolved after the request is authenticated and the Consumer is identified.

## Set up a Consumer Group

The following example creates an AI Consumer Group with one attached Policy that applies a shared rate limit to its members.

{% entity_example %}
type: consumer-group
data:
  display_name: Internal Teams
  name: internal-teams
  policies:
    - rate-limit-internal-teams
{% endentity_example %}

## Schema

{% entity_schema %}
