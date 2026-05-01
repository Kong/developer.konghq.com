---
title: Consumer
content_type: reference
entities:
  - consumer
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
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
  - text: "Kong Gateway Consumer entity"
    url: /gateway/entities/consumer/
faqs:
  - q: How is an {{site.ai_gateway}} Consumer different from a Kong Gateway Consumer?
    a: |
      The runtime entity is a regular Kong Consumer. The {{site.ai_gateway}} surface adds a required
      authentication `type` field, accepts inline Consumer Group assignment at creation, and uses the
      {{site.ai_gateway}} entity convention (`display_name`, `ref`, `labels`). The AI Consumer's `ref`
      maps to the underlying Kong Consumer's `username`. The AI Consumer surface does not expose
      `custom_id` or `tags`.

  - q: Can I edit the underlying Kong Consumer that {{site.ai_gateway}} generates?
    a: |
      No. The generated Kong Consumer is protected from direct modification through the standard
      `/consumers` Admin API. Update the AI Consumer instead.

  - q: How do I add credentials to an AI Consumer?
    a: |
      <!-- TODO: confirm whether the `type` field auto-provisions a credential, or whether credentials
      must be created separately against the underlying Kong Consumer. -->

  - q: Can a Consumer belong to multiple Consumer Groups?
    a: |
      Yes. The `consumer_groups` array accepts one or more AI Consumer Group references by `id` or `ref`.
---

## What is a Consumer?

A Consumer is the {{site.ai_gateway}} surface for an external client of the AI APIs you publish through {{site.ai_gateway}}. The underlying runtime entity is a regular {{site.base_gateway}} [Consumer](/gateway/entities/consumer/).

You use Consumers to authenticate clients, assign them to Consumer Groups, and gate access to Models, Agents, and MCP Servers through those parent entities' `acls` field.

<!-- THIS IS A PROVISIONAL FLOW, TO BE VERIFIED -->

The following diagram shows where a Consumer participates in an {{site.ai_gateway}} request. The client passes credentials to a Model, an Auth Policy on that Model identifies the Consumer, and the identified Consumer is then available to other Policies on the Model before the request reaches the upstream provider.

{% mermaid %}
flowchart LR

Client(["Client"])
Consumer(AI Consumer
entity)
Auth(Auth Policy)
Model(Model entity)
Policies("Policies
attached to Model")
Provider[Upstream
AI provider]

Client --pass
credentials--> Model
subgraph id1 ["`**AI GATEWAY**`"]
  subgraph padding[ ]

    subgraph Identify ["Consumer Identity Added"]
      direction LR
      Model --> Auth
      Auth--identify
      Consumer-->Consumer
    end
  end

  Consumer--> Policies
end
Policies --apply
per-Model policies--> Provider

style Identify stroke-dasharray: 5 5
style padding stroke:none!important,fill:none!important

{% endmermaid %}

Consumers are managed through the {{site.ai_gateway}} entity surface in both deployment modes:

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

The `type` field declares how the Consumer authenticates to {{site.ai_gateway}}. Supported values are:

* `apikey`
* `oauth`

<!-- TODO: confirm runtime semantics of the `type` field. Open question: does setting `type: apikey` auto-provision a `keyauth_credentials` entry, constrain which credentials may be added against the underlying Kong Consumer, constrain which authentication Policies may be attached, or serve as declarative metadata only? -->

## Consumer Group membership

You can assign a Consumer to one or more AI Consumer Groups inline on the `consumer_groups` array. Each entry references an AI Consumer Group by `id` or `ref`.

AI Consumer Groups themselves are managed through the AI Consumer Group surface, which is documented separately. <!-- TODO: link to AI Consumer Group entity reference once available. -->

## Set up a Consumer

The following example creates an AI Consumer assigned to a single Consumer Group.

{% entity_example %}
type: consumer
data:
  display_name: Mobile App - Production
  ref: mobile-app-production
  type: apikey
  consumer_groups:
    - ref: internal-teams
formats:
  - admin-api
  - konnect-api
{% endentity_example %}

## Schema

{% entity_schema %}