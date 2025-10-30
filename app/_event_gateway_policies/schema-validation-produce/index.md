---
title: Schema Validation Produce
name: Schema Validation Produce
content_type: reference
description: Validate records against a schema during the produce phase
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EventGatewayProduceSchemaValidationPolicy

api_specs:
  - event-gateway/knep

phases:
  - produce

policy_target: virtual_cluster

icon: graph.svg
---

{% include_cached /knep/schema-validation.md name=page.name slug=page.slug phase="produce" %}

