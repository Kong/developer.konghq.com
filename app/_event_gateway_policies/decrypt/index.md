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
  api: konnect/event-gateway
  path: /schemas/EventGatewayDecryptPolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Encrypt policy
    url: /event-gateway/policies/encrypt/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/

phases:
  - consume

policy_target: virtual_cluster

icon: graph.svg
---

The Decrypt policy decrypts portions of Kafka messages that were previously encrypted using the referenced key.
Use this policy to enforce standards for decryption across {{site.event_gateway}} clients.

The Decrypt policy uses AES-128-GCM for decryption, therefore keys must be 128 bits long.

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
    description: Define an AWS key source and decrypt all keys that come from that source.

{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases).

{% include_cached /knep/encrypt-decrypt-diagram.md %}

## Key sources

{% include_cached /knep/key-sources.md name=page.name %}

