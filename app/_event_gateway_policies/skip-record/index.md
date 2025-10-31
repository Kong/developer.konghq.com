---
title: Skip Records
name: Skip Records
content_type: reference
description: Skip the processing of a record
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EventGatewaySkipRecordPolicy

api_specs:
  - event-gateway/knep

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
If the record is skipped, it won't be processed any further.

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
  - use_case: "[Skip records with a specific name pattern](/event-gateway/policies/skip-record/examples/skip-based-on-name/)"
    description: Identify records with a specific suffix and skip processing them.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases).

1. {{site.event_gateway_short}} consumes messages from a Kafka broker.
1. {{site.event_gateway_short}} checks records against a pattern.
  * If the record matches a defined pattern, it skips processing the record and passes it on.
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
  
  alt message matches name pattern

  egw->>client: skip processing and pass to client

  else message doesn't match name pattern
  egw ->> egw: apply other policies
  egw->>client: pass to client

  end

{% endmermaid %}
<!--vale on-->