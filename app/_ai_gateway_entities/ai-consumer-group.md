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
  - q: How is an AI Consumer Group different from a {{site.base_gateway}} Consumer Group?
    a: |
      The {{site.ai_gateway}} surface adds
      the entity convention ([`display_name`](#schema-aigateway-consumer-group-display-name), [`name`](#schema-aigateway-consumer-group-name), [`labels`](#schema-aigateway-consumer-group-labels)) and a required [`policies`](#schema-aigateway-consumer-group-policies) array
      for attaching AI Policies at the group scope.

  - q: Can I edit the underlying Kong Consumer Group that {{site.ai_gateway}} generates?
    a: |
      No. The generated Kong Consumer Group is protected from direct modification through the
      standard `/consumer-groups` Admin API. Update the AI Consumer Group instead.

  - q: How do I assign an AI Consumer to an AI Consumer Group?
    a: |
      You add an AI Consumer to an AI Consumer Group through the AI Consumer Group entity.
      See the [AI Consumer entity](/ai-gateway/entities/ai-consumer/) reference.

  - q: Can an AI Consumer belong to multiple AI Consumer Groups?
    a: |
      Yes. The AI Consumer's `consumer_groups` array accepts one or more references.

  - q: How do I attach AI Policies to an AI Consumer Group?
    a: |
      Add the AI Policy's `name` or `id` to the AI Consumer Group's [`policies`](#schema-aigateway-consumer-group-policies) array.
      The AI Policy runs when a member of the group is identified during a request.
      See the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

  - q: How do I gate access to an AI Model, AI Agent, or AI MCP Server with an AI Consumer Group?
    a: |
      Add the AI Consumer Group's name to the parent entity's `acls.allow` or `acls.deny` list.
      ACLs accept AI Consumer, AI Consumer Group, and Authenticated Group names.
      See the [AI Model entity](/ai-gateway/entities/ai-model/) reference.
---

## What is an AI Consumer Group?

An AI Consumer Group is the {{site.ai_gateway}} entity that represents a collection of AI Consumers grouped for the purpose of applying shared AI Policies and access controls.

By grouping AI Consumers together, you eliminate the need to manage AI Policies and access controls individually, providing a scalable, efficient approach to AI governance. With AI Consumer Groups, you can scope AI Policies to specifically defined groups, making configurations and customizations more flexible.

For example, you could define three groups (Bronze, Gold, and Enterprise) and attach an AI Rate Limiting Advanced AI Policy to each with different token quotas and cost budgets. Without AI Consumer Groups, you would attach a separate AI Rate Limiting Advanced AI Policy to each individual AI Consumer — in production, that could be thousands of individual AI Policy attachments instead of three group-level ones.

<!-- vale off -->
{% mermaid %}
flowchart LR
    A((AI Consumers 1-5))

    B("<b>AI Consumer Group Gold</b><br/>AI Consumer 1, AI Consumer 2, AI Consumer 5")

    C("<b>AI Consumer Group Bronze</b><br/>AI Consumer 3, AI Consumer 4")

    D["AI Rate Limiting Advanced<br/>1M tokens/hour<br/>AND<br/>$100/hour budget"]
    E["AI Rate Limiting Advanced<br/>100K tokens/hour<br/>AND<br/>$10/hour budget"]
    F("<b>AI Model</b><br/>GPT-4")
    H["OpenAI<br/>Service"]

    A--> B & C
    subgraph id1 ["AI Gateway"]
    direction LR
    B --> D --> F
    C --> E --> F
    end

    F --> H
{% endmermaid %}
<!-- vale on -->

## Manage AI Consumer Groups

AI Consumer Groups can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/consumer-groups`

For configuration examples and step-by-step setup instructions, see [Set up an AI Consumer Group](#set-up-an-ai-consumer-group) below.

## Use cases for using AI Consumer Group

Common use cases for AI Consumer Groups:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "Subscription tier management"
    description: "Create AI Consumer Groups for different subscription tiers (for example, Bronze, Gold, Enterprise). Assign different rate limits, model access restrictions, and token quotas to each tier without configuring individual AI Consumers."
  - use_case: "Team-based access control"
    description: "Organize AI Consumers by team or department. Gate access to specific [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), or [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) at the group level, so teams only access the resources they need."
  - use_case: "AI safety and governance AI Policies"
    description: "Apply group-level AI Policies for prompt validation, PII detection, and content filtering. For example, apply stricter guardrails to public-facing groups while allowing more permissive configurations for internal teams. See the [AI Policies hub](/ai-gateway/policies/) for available policy types."
  - use_case: "Cost and quota management"
    description: "Enforce per-group token limits, rate limits, and usage quotas. Track spending and resource usage by AI Consumer Group to manage AI API costs at scale."
  - use_case: "Centralized AI Policy management"
    description: "Attach AI Policies once at the group level rather than managing them on every individual AI Consumer. Simplifies configuration and ensures consistency across all group members."
{% endtable %}
<!-- vale on -->

## Membership

To organize AI Consumers by team, department, or tier, add them to an AI Consumer Group. Membership is managed through the [AI Consumer entity](/ai-gateway/entities/ai-consumer/) — set the `consumer_groups` array on any AI Consumer to add it to one or more AI Consumer Groups. A single AI Consumer can belong to multiple AI Consumer Groups, allowing flexible organizational schemes.

## Attach AI Policies

To apply the same AI Policies (rate limits, prompt validation, PII detection) to multiple consumers at once, attach them to the AI Consumer Group. When a member of the group makes a request, {{site.ai_gateway}} applies all attached AI Policies before routing the request. Add an AI Policy's `name` or `id` to the AI Consumer Group's [`policies`](#schema-aigateway-consumer-group-policies) array.

You can attach multiple AI Policies to a single AI Consumer Group with different configurations, and each runs independently. For supported policy types and how AI Policies attach to other entities, see the [AI Policy entity](/ai-gateway/entities/ai-policy/) reference.

## Use in parent entity ACLs

To restrict access to specific [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), or [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) by AI Consumer Group (for example, allowing only Gold tier AI Consumers to access premium models), use ACLs. The `acls` field on these entities accepts AI Consumer Group names alongside AI Consumer and Authenticated Group names. Add an AI Consumer Group to a parent entity's `acls.allow` list to permit its members access, or to `acls.deny` to block them.

AI Consumer Group membership is resolved after the request is authenticated and the AI Consumer is identified.

## Set up an AI Consumer Group

The following example creates an AI Consumer Group. You can attach AI Policies through the {{site.konnect_short_name}} UI or by adding their `name` or `id` to the `policies` array.

{% entity_example %}
type: consumer_group
data:
  display_name: Internal Teams
  name: internal-teams
  policies: []
{% endentity_example %}

## Schema

{% entity_schema %}
