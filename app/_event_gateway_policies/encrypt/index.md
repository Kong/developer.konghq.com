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

phases:
  - produce

policy_target: virtual_cluster

related_resources:
  - text: Decrypt policy
    url: /event-gateway/policies/decrypt/
---

This policy can be used to encrypt portions of Kafka records.

## Use cases

Common use cases for the Encrypt policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Encrypt a specific key from a source](/event-gateway/policies/encrypt/examples/encrypt-a-key/)"
    description: Decrypt a key based on a specific key reference name.

  - use_case: "[Encrypt all keys](/event-gateway/policies/encrypt/examples/encrypt-everything/)"
    description: Define a static key source and encrypt all keys that come from that source.

{% endtable %}
<!--vale on-->
