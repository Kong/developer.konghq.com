---
title: Schema Validation Consume
name: Schema Validation Consume
content_type: plugin
description: Validate records against a schema during the consume phase
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayConsumeSchemaValidationPolicy

related_resources:
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/

api_specs:
  - konnect/event-gateway

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

{% include_cached /knep/schema-validation.md name=page.name slug=page.slug phase="consume" %}
