---
title: ACLs
name: ACLs
content_type: reference
description: Manage access to your virtual cluster resources.
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayACLsPolicy

api_specs:
  - konnect/event-gateway

phases:
  - cluster

icon: graph.svg

policy_target: virtual_cluster

related_resources:
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Set up Kong Event Gateway with Kong Identity OAuth
    url: /how-to/event-gateway/kong-identity-oauth/
---

The ACL (Access Control List) policy manages authorization for your [virtual cluster](/event-gateway/entities/virtual-cluster/) by defining which actions principals can perform on specific resources.

By default, when ACLs are enabled, principals have no access. You must explicitly define access rules through ACL policies.

## Use cases

Common use cases for the ACLs policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Allow read-only access to a topic](./examples/read-only-topic/)"
    description: Allow the principal to consume messages for a specific topic.
  - use_case: "[Allow consumer group management](./examples/manage-consumer-groups/)"
    description: Allow the principal to create and delete consumer groups.

{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [cluster phase](/event-gateway/entities/policy/#phases).

1. A Kafka client produces a message and sends it to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} checks the client's action against the configured ACL.
  * If the action is allowed, it passes the message onward.
  * If the action isn't allowed, the message is dropped.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: message
  egw->>egw: check action against ACL
  
  alt If action allowed

  egw->>broker: send message

  else If action blocked
  egw -x client: forbidden
  end

{% endmermaid %}
<!--vale on-->
