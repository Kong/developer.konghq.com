---
title: Key Sets
content_type: reference
entities:
  - key-set

description: A Key Set is a collection of {{site.base_gateway}} Keys.

related_resources:
  - text: Keyring entity
    url: /gateway/entities/keyring/
  - text: Key entity
    url: /gateway/entities/key/

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config 
  - gateway/admin-oss

schema:
  api: gateway/admin-ee
  path: /schemas/Key-set

---

@todo
You can assign one or many keys to a JSON Web Key Set. This can be useful to logically group multiple keys to use for a specific application or service. Key Sets are also the preferred way to expose keys to plugins because they tell the plugin where to look for keys or have a scoping mechanism to restrict plugins to just some keys.