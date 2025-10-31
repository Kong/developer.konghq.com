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
  path: /schemas/EventGatewayEncryptPolicy

api_specs:
  - event-gateway/knep

icon: graph.svg

phases:
  - produce

policy_target: virtual_cluster

related_resources:
  - text: Decrypt policy
    url: /event-gateway/policies/decrypt/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
---

This policy can be used to encrypt portions of Kafka records.
Use this policy to enforce standards for encryption across {{site.event_gateway}} clients. 

The Encrypt policy uses AES-128-GCM for encryption, therefore keys must be 128 bits long.

Use this policy together with the [Decrypt policy](/event-gateway/policies/decrypt/), which decrypts portions of a message using the same referenced key.

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
  - use_case: "[Encrypt portions of a message based on a static key](/event-gateway/policies/encrypt/examples/encrypt-with-static-key/)"
    description: Encrypt a specific key or value based on a key reference name.

  - use_case: "[Encrypt a message using an AWS key source](/event-gateway/policies/encrypt/examples/encrypt-with-aws/)"
    description: Encrypt all defined keys or values using an AWS key source.

{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [produce phase](/event-gateway/entities/policy/#phases).

{% include_cached /knep/encrypt-decrypt-diagram.md %}

## Key sources

{% include_cached /knep/key-sources.md name=page.name %}
