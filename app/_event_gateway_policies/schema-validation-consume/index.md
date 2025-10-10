---
title: Schema Validation Consume
name: Schema Validation Consume
content_type: reference
description: Validate records against a schema during the consume phase
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/SchemaValidationPolicy
  # path: /schemas/EventGatewayProduceSchemaValidationPolicy - replace with this path

api_specs:
  - event-gateway/knep

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

{% include_cached /knep/schema-validation.md name=page.name slug=page.slug phase="consume" %}
