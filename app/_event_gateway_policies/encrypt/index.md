---
title: Encrypt
name: Encrypt
content_type: plugin
description: Encrypt portions of Kafka records
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayEncryptPolicy

api_specs:
  - konnect/event-gateway

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
  - text: Static keys
    url: /event-gateway/entities/static-key/
  - text: Encrypt and decrypt Kafka messages with {{site.event_gateway}}
    url: /event-gateway/encrypt-kafka-messages-with-event-gateway/
---

This encrypt policy is used to encrypt portions of Kafka messages.
The Encrypt policy uses AES-256-GCM for encryption, therefore keys must be 256 bits long.

Use this policy together with the [Decrypt policy](/event-gateway/policies/decrypt/), which decrypts portions of a message using the same referenced key, to enforce standards for encryption across {{site.event_gateway}} clients. 

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
  - use_case: "[Encrypt a message using a static key](/event-gateway/policies/encrypt/examples/encrypt-with-static-key/)"
    description: Encrypt a message value using a static key.

  - use_case: "[Encrypt a message using an AWS key source](/event-gateway/policies/encrypt/examples/encrypt-with-aws/)"
    description: Encrypt a message value using an AWS key source.

{% endtable %}
<!--vale on-->

## How it works

This policy runs during the [produce phase](/event-gateway/entities/policy/#phases).

{% include_cached /knep/encrypt-decrypt-diagram.md %}

{% include_cached /knep/how-encrypt-works.md %}

### Key sources

{% include_cached /knep/key-sources.md name=page.name %}