---
title: Key Sets
content_type: reference
entities:
  - key-set

products:
  - gateway

description: A Key Set is a collection of {{site.base_gateway}} Keys.

related_resources:
  - text: Key entity
    url: /gateway/entities/key/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway/control-plane-resource-limits/


tools:
  - deck
  - admin-api
  - konnect-api

api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config 

schema:
  api: gateway/admin-ee
  path: /schemas/KeySet

works_on:
  - on-prem
  - konnect
---

## What is a Key Set?

A Key Set is a collection of {{site.base_gateway}} [Keys](/gateway/entities/key/).

You can assign one or many Keys to a Key Set. This can be useful to logically group multiple Keys to use for a specific application or service. Key Sets allow you to give a plugin access to a specific list of Keys.

Key Sets can be used with the following plugins:
- [ACME](/plugins/acme/), with the `config.account_key.key_set` parameter
- [JWE Decrypt](/plugins/jwe-decrypt/), with the `config.key_sets` parameter
- [JWT Signer](/plugins/jwt-signer/), with the `config.access_token_keyset` parameter

## Schema

{% entity_schema %}

## Set up a Key Set

{% entity_example %}
type: key-set
data:
  name: example-key-set
{% endentity_example %}