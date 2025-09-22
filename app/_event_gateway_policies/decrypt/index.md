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
