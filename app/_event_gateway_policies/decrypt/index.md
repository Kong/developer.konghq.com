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
  path: /schemas/EventGatewayDecryptPolicy

api_specs:
  - event-gateway/knep

related_resources:
  - text: Encrypt policy
    url: /event-gateway/policies/encrypt/

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

The Decrypt policy decrypts portions of Kafka messages that were previously encrypted using the referenced key.
Use this policy to enforce standards for decryption across {{site.event_gateway}} clients.

The Decrypt policy uses AES-128-GCM for decryption, therefore keys must be 128 bits long.

Use this policy together with the [Encrypt policy](/event-gateway/policies/encrypt/), which encrypts portions of a message using the same referenced key.

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
  - use_case: "[Decrypt using a static key](/event-gateway/policies/decrypt/examples/decrypt-with-static-key/)"
    description: Decrypt a key or value based on a key reference name.

  - use_case: "[Decrypt using an AWS key source](/event-gateway/policies/decrypt/examples/decrypt-with-aws/)"
    description: Decrypt a keys or value using an AWS key source.

{% endtable %}
<!--vale on-->

## Key sources

{% include_cached /knep/key-sources.md name=page.name %}

