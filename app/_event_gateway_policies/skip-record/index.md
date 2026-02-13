---
title: Skip Records
name: Skip Records
content_type: plugin
description: Skip the processing of a record
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewaySkipRecordPolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

The Skip Records policy ensures that only valid and relevant records continue through the policy execution chain. 
If the record is skipped, it is dropped from the message and not forwarded to the client or the cluster.

## Use cases

Common use cases for the Skip Record policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Skip records with a specific name pattern](/event-gateway/policies/skip-record/examples/skip-based-on-name/)"
    description: Identify records with a specific suffix and skip forwarding them.
  - use_case: "[Tutorial: Filter Kafka records by classification headers](/event-gateway/filter-records-by-classification/)"
    description: Filter out internal logs for users who aren't on a specific team.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases).

1. {{site.event_gateway_short}} consumes messages from a Kafka broker.
1. {{site.event_gateway_short}} checks records against a pattern.
  * If the record matches a defined pattern, it does not forward the message.
  * If the record doesn't match the pattern, it applies further policies in the chain.


<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant broker as Event broker
  participant egw as {{site.event_gateway_short}}
  participant client as Client


  broker->>egw: consume message
  egw->>egw: check message validity
  
  alt If message matches <br> name pattern

  egw--xclient: skip passing to client

  else If message doesn't match <br> name pattern
  egw ->> egw: apply other policies
  egw->>client: pass to client

  end

{% endmermaid %}
<!--vale on-->

## Nested policies 

{% include_cached /knep/nested-policy.md name=page.name slug=page.slug %}
