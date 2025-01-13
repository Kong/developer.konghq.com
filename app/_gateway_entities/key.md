---
title: Keys
content_type: reference
entities:
  - key

description: A Key object holds a representation of asymmetric keys in various formats.

related_resources:
  - text: Keyring entity
    url: /gateway/entities/keyring/
  - text: Key-set entity
    url: /gateway/entities/key-set/

api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config 
  - gateway/admin-oss

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

schema:
  api: gateway/admin-ee
  path: /schemas/Key

---

@todo

A Key object holds a representation of asymmetric keys in various formats. When Kong or a Kong plugin requires a specific public or private key to perform certain operations, it can use this entity.