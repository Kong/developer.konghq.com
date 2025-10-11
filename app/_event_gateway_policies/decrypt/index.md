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

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

This policy is used to decrypt messages that were previously encrypted using the referenced key. 
Use this policy to enforce standards for decryption across {{site.event_gateway}} clients.

## Use cases

Common use cases for the Decrypt policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Decrypt a specific key from a source](/event-gateway/policies/decrypt/examples/decrypt-a-key/)"
    description: Decrypt a key based on a specific key reference name.

  - use_case: "[Decrypt all keys](/event-gateway/policies/decrypt/examples/decrypt-everything/)"
    description: Define a static key source and decrypt all keys that come from that source.

{% endtable %}
<!--vale on-->


