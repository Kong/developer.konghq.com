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
