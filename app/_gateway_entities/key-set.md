---
title: Key Sets
content_type: reference
entities:
  - key-set

description: A Key Set is a collection of {{site.base_gateway}} Keys.

related_resources:
  - text: Key entity
    url: /gateway/entities/key/

tools:
  - admin-api
  - konnect-api

api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config 
  - gateway/admin-oss

schema:
  api: gateway/admin-ee
  path: /schemas/Key-set

---

## What is a Key Set?

A Key Set is a collection of {{site.base_gateway}} Keys.

You can assign one or many keys to a JSON Web Key Set. This can be useful to logically group multiple Keys to use for a specific application or service. Key Sets allow you to give a plugin access to a specific list of Keys.

## Schema

{% entity_schema %}

## Set up a Key Set

{% entity_example %}
type: key
data:
  name: example-key-set
{% endentity_example %}