---
title: Keyring
content_type: reference
entities:
  - keyring

description: |
  Keyring is the mechanism for storing sensitive data fields, such as consumer secrets, in an encrypted format within the database. 
  This provides for encryption-at-rest security controls in a {{site.base_gateway}} cluster.

related_resources:
  - text: Key entity
    url: /gateway/entities/key/
  - text: Key-set entity
    url: /gateway/entities/key-set/

tier: enterprise

api_specs:
  - gateway/admin-ee

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

schema:
  api: gateway/admin-ee
  path: /schemas/Keyring

---

@todo

Keyring is the mechanism for storing sensitive data fields, such as consumer secrets, in an encrypted format within the database. 
This provides for encryption-at-rest security controls in a {{site.base_gateway}} cluster.

[FAQ: why choose keyring encryption over vaults? what are the benefits/differences?]