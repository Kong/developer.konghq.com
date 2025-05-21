---
title: Modify Headers
name: Modify Headers
content_type: reference
description: Set or remove record headers
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/ModifyHeadersPolicy

api_specs:
  - event-gateway/knep

beta: true

icon: /assets/icons/graph.svg
---

This policy is used to set or remove record headers.

## Schema

{% entity_schema %}

## Example configuration

```yaml
policies:
  - name: remove-key-headers
    type: modify_headers
    spec:
      actions:
      - type: remove
        remove:
        - key: key
        set:
        - key: key
          value: value
```