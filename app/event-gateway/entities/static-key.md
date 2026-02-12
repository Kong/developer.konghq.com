---
title: "Static keys"
content_type: reference
layout: gateway_entity

description: |
    Static encryption keys are resources that can be used by the Encrypt and Decrypt policies to encrypt and decrypt Kafka messages.
related_resources:
  - text: "Encrypt policy"
    url: /event-gateway/policies/encrypt/
  - text: "Decrypt policy"
    url: /event-gateway/policies/decrypt/
  - text: Encrypt and decrypt Kafka messages with {{site.event_gateway}}
    url: /event-gateway/encrypt-kafka-messages-with-event-gateway/
tools:
    - konnect-api

works_on:
  - konnect

schema:
    api: konnect/event-gateway
    path: /schemas/EventGatewayStaticKey

api_specs:
    - konnect/event-gateway

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## Static keys

Static keys are resources that you can use in the [Encrypt](/event-gateway/policies/encrypt) and [Decrypt](/event-gateway/policies/decrypt) policies to encrypt and decrypt messages.

A static key can contain a secret (Base64-encoded key) or a reference to a secret as a template string expression.

* If the value is provided as plain text, it is encrypted at rest and omitted from API responses.
* If provided as an expression, the expression itself is stored and returned by the API, e.g. `${vault.env["MY_ENV_VAR"]}`.

## Set up a static key

{% entity_example %}
type: static_key
data:
  name: my-key
  value: $MY_KEY
{% endentity_example %}

## Schema

{% entity_schema %}
