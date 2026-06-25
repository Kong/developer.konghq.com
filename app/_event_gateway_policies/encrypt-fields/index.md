---
title: Encrypt Fields
name: Encrypt Fields
content_type: plugin
description: Encrypt fields of Kafka records.
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayParsedRecordEncryptFieldsPolicy

api_specs:
  - konnect/event-gateway

icon: graph.svg

phases:
  - produce

policy_target: virtual_cluster

categories:
  - security

related_resources:
  - text: Decrypt Fields policy
    url: /event-gateway/policies/decrypt-fields/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Static keys
    url: /event-gateway/entities/static-key/
  - text: Encrypt and decrypt Kafka message fields with {{site.event_gateway}}
    url: /event-gateway/encrypt-kafka-message-fields-with-event-gateway/
  - text: Encrypt and decrypt Kafka message fields dynamically with {{site.event_gateway}}
    url: /event-gateway/encrypt-kafka-message-fields-dynamic/

min_version:
  event-gateway: '1.2'
---

The Encrypt Fields policy is used to encrypt fields of Kafka messages that have been validated to conform to a schema.

This policy uses AES-256-GCM for encryption, therefore keys must be 256 bits long.

Use the Encrypt Fields policy together with the [Decrypt Fields policy](/event-gateway/policies/decrypt-fields/), which decrypts fields of a message using the same referenced key, to enforce standards for encryption across {{site.event_gateway}} clients.

## Use cases

Common use cases for the Encrypt Fields policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Encrypt a message field using a static key](/event-gateway/policies/encrypt-fields/examples/encrypt-with-static-key/)"
    description: Encrypt a message field using a static key.

  - use_case: "[Encrypt a message field using an AWS key source](/event-gateway/policies/encrypt-fields/examples/encrypt-with-aws/)"
    description: Encrypt a message field using an AWS key source.

  - use_case: "[Encrypt a message field using a dynamic list of field paths](/event-gateway/policies/encrypt-fields/examples/encrypt-with-dynamic-paths/)"
    description: Encrypt a message field using a dynamic list of field paths

{% endtable %}
<!--vale on-->

## How it works

This policy runs during the [produce phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-produce/) has taken place.

{% include_cached /knep/encrypt-decrypt-diagram.md %}

{% include_cached /knep/how-encrypt-works.md %}

### Key sources

{% include_cached /knep/key-sources.md name=page.name %}

