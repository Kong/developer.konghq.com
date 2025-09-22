---
title: Encrypt
name: Encrypt
content_type: reference
description: Encrypt portions of Kafka records
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/EncryptPolicy

api_specs:
  - event-gateway/knep

beta: true

icon: graph.svg

related_resources:
  - text: Decrypt policy
    url: /event-gateway/policies/decrypt/
---

This policy can be used to encrypt portions of Kafka records.

## Example configuration

Example configurations for the Encrypt policy.

### Encrypt a key

Encrypt a specific key:
```yaml
policies:
  - name: encrypt-keys
    type: encrypt
    spec:
      failure:
        mode: error
      key_sources:
      - type: ref_name
        ref_name: ref_name
      encrypt:
      - type: key
        id: id
```

### Encrypt everything

Encrypt everything in a specific `key_source` location:

```yaml
key_sources:
  - name: aws
    type: aws
    aws:
      credentials:
        type: env
policies:
  - name: encrypt-everything
    type: encrypt
    spec:
      failure:
        mode: passthrough # | error
      key_sources:
        - type: static
          static:
            id: "user-chosen-id"
            source:
              type: string # | file
              string: |
                cT4Q34DDB25hU9lumzrXtw==...
        - type: ref_name
          ref_name: aws
      encrypt:
       - type: keys
         id: "aws://arn:aws:kms:us-east-1:123456789012:key/password-key-id"
       - type: values
         id: "static://user-chosen-id"
```