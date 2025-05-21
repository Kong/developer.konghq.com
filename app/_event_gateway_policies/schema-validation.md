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

icon: /assets/icons/graph.svg
---

This policy is used to validate records using a provided schema.

## Schema

{% entity_schema %}

## Example configuration

```yaml
policies:
  - name: validate-schemas
    type: schema_validation
    spec:
      record_key:
        schema_registry_name: schema_registry_name
        failure_action: reject
      record_value:
        schema_registry_name: schema_registry_name
        failure_action: reject
```