---
title: Modify Headers
name: Modify Headers
content_type: plugin
description: Set or remove record headers
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayModifyHeadersPolicy

related_resources:
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/

api_specs:
  - konnect/event-gateway

phases:
  - produce
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

The Modify Headers policy can set or remove headers on requests.

## Use cases

Common use cases for the Modify Headers policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Remove and replace a header](/event-gateway/policies/modify-headers/examples/remove-and-replace-header/)"
    description: Remove a specific header and replace it with a custom header of your choice.
  - use_case: "[Example: Add a header based on a condition](/event-gateway/policies/modify-headers/examples/add-header-based-on-condition/)"
    description: If a record fits a specific condition, add a custom header of your choice.
  - use_case: "[Tutorial: Filter Kafka records by classification headers](/event-gateway/filter-records-by-classification/)"
    description: Use a [Schema Validation policy](/event-gateway/policies/schema-validation-produce/) to parse JSON records, and use a nested Modify Headers policy to add a header to specific records.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [produce or consume phase](/event-gateway/entities/policy/#phases).

For produced messages:
1. A Kafka client produces messages and sends them to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} adjusts the headers before passing messages to the broker.

For consumed messages:
1. {{site.event_gateway_short}} consumes messages from a Kafka broker.
1. {{site.event_gateway_short}} adjusts the headers before passing messages to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: produce message
  egw->>egw: remove or add headers
  
  egw->>broker: send message

  broker->>egw: consume message
  egw->>egw: remove or add headers

  egw->>client: pass message with new headers

{% endmermaid %}
<!--vale on-->

## Nested policies 

{% include_cached /knep/nested-policy.md name=page.name slug=page.slug %}
