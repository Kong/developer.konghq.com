---
title: Schema Validation
name: Schema Validation
content_type: reference
description: Validate records against a schema
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/SchemaValidationPolicy

api_specs:
  - event-gateway/knep

beta: true

phases:
  - produce
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

This policy is used to validate records using a provided schema.

Common use cases for the Schema Validation policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Validate all topics](/event-gateway/policies/schema-validation/examples/validate-all-topics/)"
    description: Ensure that every topic is validated against a schema.
  - use_case: "[Validate all messages for a topic](/event-gateway/policies/schema-validation/examples/validate-all-messages-for-topic/)"
    description: Ensure that all messages produced for a specific topic are validated against a schema.
  - use_case: "[Ensure that every topic has a schema](/event-gateway/policies/schema-validation/examples/ensure-every-topic-has-schema/)"
    description: In a migration scenario where topics might start without a schema, ensure that every topic eventually has a schema.

{% endtable %}
<!--vale on-->
