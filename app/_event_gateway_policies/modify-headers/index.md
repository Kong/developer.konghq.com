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

icon: graph.svg
---

This policy is used to set or remove record headers.

## Example configuration

Example configurations for the Modify Headers policy.

### Remove and replace a header

The following example removes a header named `example-header1` and replaces it with `example-header2`:

```yaml
policies:
  - name: modify-headers
    type: modify_headers
    spec:
      actions:
      - type: remove
        remove:
        - key: example-header
        set:
        - key: example-header2
          value: example
```