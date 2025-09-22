---
title: Decrypt
name: Decrypt
content_type: reference
description: Decrypt messages that were previously encrypted using the referenced key
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

related_resources:
  - text: Encrypt policy
    url: /event-gateway/policies/encrypt/

icon: graph.svg
---

This policy is used to decrypt messages that were previously encrypted using the referenced key. 
Use this policy to enforce standards for decryption across {{site.event_gateway}} clients.

## Example configuration

Example configurations for the Decrypt policy.

### Decrypt a key

Decrypt a specific key:

```yaml
policies:
  - name: decrypt-key
    type: decrypt
    spec:
      failure:
        mode: error
      key_sources:
      - type: ref_name
        ref_name: ref_name
      decrypt:
      - type: key
```

### Decrypt everything

Decrypt everything in a specific `key_source` location:

```yaml
key_sources:
  - name: aws
    type: aws
    aws:
      credentials:
        type: env
policies:
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

## Schema

{% entity_schema %}