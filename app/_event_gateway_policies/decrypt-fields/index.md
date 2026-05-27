---
title: Decrypt fields
name: Decrypt fields
content_type: plugin
description: Decrypt fields of Kafka message that were previously encrypted using the referenced key
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
  - text: Encrypt fields policy
    url: /event-gateway/policies/encrypt-fields/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Static keys
    url: /event-gateway/entities/static-key/
  - text: Encrypt and decrypt Kafka message fields with {{site.event_gateway}}
    url: /event-gateway/encrypt-kafka-message-fields-with-event-gateway/

phases:
  - consume

policy_target: virtual_cluster

categories:
  - security

icon: graph.svg
---

The Decrypt policy decrypts fields of Kafka messages that were previously encrypted using a referenced key.  
Use this policy to enforce consistent decryption standards across {{site.event_gateway}} clients.

This policy uses **AES-256-GCM** for decryption, which requires keys to be **256 bits** in length.

Use this policy together with the [Encrypt fields policy](/event-gateway/policies/encrypt-fields/), which encrypts fields of a message using the same referenced key.

## Use cases

Common use cases for the Decrypt fields policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Decrypt a field using a static key](/event-gateway/policies/decrypt-fields/examples/decrypt-with-static-key/)"
    description: Decrypt a message field based on a key reference name.

  - use_case: "[Example: Decrypt a field using an AWS key source](/event-gateway/policies/decrypt-fields/examples/decrypt-with-aws/)"
    description: Decrypt a message field using an AWS key source.

{% endtable %}
<!--vale on-->

## How it works

This policy runs during the [consume phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-consume/) has taken place.

{% include_cached /knep/encrypt-decrypt-diagram.md %}

{% include_cached /knep/how-encrypt-works.md %}

### Key sources

{% include_cached /knep/key-sources.md name=page.name %}

