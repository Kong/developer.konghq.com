---
title: Decrypt
name: Decrypt
content_type: reference
description: Reference for the Decrypt policy.
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/DecryptPolicy

api_specs:
  - event-gateway/knep

beta: true
---

This policy is used to decrypt messages that were previously encrypted using the referenced key. Use it to enforce standards for decryption across event gateway clients.

## Configuration Fields

This is where I'd like to embed the schema from the knep OpenAPI spec :)

## Example Configuration

```yaml
policies
  - name: decrypt-everything
    type: decrypt
    spec:
      failure:
        mode: passthrough # | error
      key_sources:
        - type: static
          static:
            id: "user-chosen-id"
            source:
              type: file # | string
              file: /var/key
        - type: aws
          aws:
            # AWS API auth info
      decrypt:
       - type: keys
       - type: values
```