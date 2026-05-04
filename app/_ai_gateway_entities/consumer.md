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
  - text: "{{site.base_gateway}} Consumer entity"
    url: /gateway/entities/consumer/
faqs:
  - q: How is an {{site.ai_gateway}} Consumer different from a {{site.base_gateway}} Consumer?
    a: |
      The runtime entity is a regular Kong Consumer. The {{site.ai_gateway}} surface uses the
      {{site.ai_gateway}} entity convention (`display_name`, `name`, `labels`), requires an
      authentication `type` field, accepts inline Consumer Group assignment, and lets you reference
      Policies and embed credentials directly on the Consumer.

  - q: Can I edit the underlying Kong Consumer that {{site.ai_gateway}} generates?
    a: |
      No. The generated Kong Consumer is protected from direct modification through the standard
      `/consumers` Admin API. Update the AI Consumer instead.

  - q: How do I add credentials to an AI Consumer?
    a: |
      For `type: apikey`, set `config.credentials[].api_key` on the Consumer.
      Each entry can also set a `ttl` in seconds.

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

A Consumer is the {{site.ai_gateway}} entity that represents an downstream client of the AI APIs you publish through {{site.ai_gateway}}. 

You can use Consumers and Consumer Groups to authenticate clients, attach Policies, and gate access to Models, Agents, and MCP Servers through those parent entities' `acls` field.

<!-- THIS IS A PROVISIONAL FLOW, TO BE VERIFIED -->

The following diagram shows how a Consumer participates in an {{site.ai_gateway}} request. The client passes {{site.ai_gateway}} credentials for a Model, an Auth Policy on that Model identifies the Consumer, and the identified Consumer is then available to other Policies on the Model before the request reaches the upstream provider.

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

Consumers are managed through the {{site.ai_gateway}} entity API surface in either deployment modes:

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

<!-- TODO: confirm what `type: oauth` does at runtime. The spec lists the value but doesn't define behavior or any oauth-specific fields under `config`. -->

## Credentials

For Consumers of `type: apikey`, you can declare credentials inline on the Consumer's `config.credentials` array. Each entry has:

* `api_key`: the API key value the client presents.
* `ttl`: optional time-to-live in seconds. Once elapsed, the credential is no longer valid.

Multiple credentials can be declared per Consumer. Rotating a key means adding a new entry and removing the old one.

## External identity mapping

The `config.custom_id` field stores an external identifier for the Consumer, such as an OIDC Client ID. This field is optional and informational. {{site.ai_gateway}} does not use it for authentication or routing.

## Consumer Group membership

You can assign a Consumer to one or more Consumer Groups through the `consumer_groups` array. Each entry references a Consumer Group by `name` or `id`.

Consumer Groups are managed through their own entity surface. <!-- TODO: link to Consumer Group entity reference once available. -->

## Attach Policies

A Policy is an {{site.ai_gateway}} Entity that triggers an action using a plugin. You can attach a Policy to a Consumer and the underlying plugin will run in the request lifecycle when this Consumer is identified. To attach a Policy add the Policy's `name` or `id` to the Consumer's `policies` array.

You can add multiple Policies to a single Consumer. Each Policy is an independent instance.

For the supported plugin types and how Policies attach to other entities, see the [Policy entity](/ai-gateway/entities/policy/) reference.

## Set up a Consumer

The following example creates an AI Consumer with one API key credential, assigned to a single Consumer Group.

{% entity_example %}
type: consumer
data:
  display_name: Mobile App - Production
  name: mobile-app-production
  type: apikey
  consumer_groups:
    - internal-teams
  policies: []
  config:
    credentials:
      - api_key: sk-387788hd3xnej
        ttl: 86400
{% endentity_example %}

## Schema

{% entity_schema %}