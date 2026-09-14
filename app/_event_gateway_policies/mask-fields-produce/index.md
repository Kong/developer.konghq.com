---
title: Mask Fields Produce
name: Mask Fields Produce
content_type: plugin
description: Redact string fields of parsed Kafka records during the produce phase
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayParsedRecordMaskFieldsProducePolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Mask Fields Consume policy
    url: /event-gateway/policies/mask-fields-consume/
  - text: Schema Validation Produce policy
    url: /event-gateway/policies/schema-validation-produce/
  - text: Encrypt Fields policy
    url: /event-gateway/policies/encrypt-fields/
  - text: Mask sensitive fields in Kafka messages with {{site.event_gateway}}
    url: /event-gateway/mask-kafka-message-fields/

phases:
  - produce

policy_target: virtual_cluster

categories:
  - security

icon: graph.svg

min_version:
  event-gateway: '1.3'
---

The Mask Fields Produce policy redacts `string` fields of Kafka records during the produce phase.
It runs on a record that a [Schema Validation Produce policy](/event-gateway/policies/schema-validation-produce/) parsed, so you must nest it under that policy.

Use this policy to redact a value before {{site.event_gateway_short}} writes it to the backend cluster.
The cluster never receives the original value, so this change is irreversible.
To redact a value for the client that reads it, and keep the stored record unchanged, use the [Mask Fields Consume policy](/event-gateway/policies/mask-fields-consume/) instead.

Select the fields to redact as a static list of paths, or as a single expression that returns a list of paths.
Each entry pairs a set of paths with the strategy that redacts them.

## Use cases

Common use cases for the Mask Fields Produce policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Mask a field before it reaches the cluster](/event-gateway/policies/mask-fields-produce/examples/mask-ssn-on-produce/)"
    description: |
      Redact an SSN field before {{site.event_gateway_short}} writes the record, so the cluster never stores the original value.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [produce phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-produce/) parses the record.

1. A Kafka client produces a record and sends it to {{site.event_gateway_short}}.
1. The parent Schema Validation policy parses the record value.
1. The Mask Fields Produce policy replaces the value of each selected field with a masked value.
1. {{site.event_gateway_short}} sends the record to the backend cluster, which stores the masked value.

This policy masks `string` fields only:
* A selected field that is not present in the record is ignored.
* A selected field that is not a `string` is a policy failure. The `failure_mode` setting controls the result.

{:.warning}
> Masking can break client-side validation. For example, a client that validates the format of an SSN can reject a masked value.
Make sure your clients accept masked values before you enable this policy.

## Masking strategies

Each entry in `mask_fields` uses one of the following strategies:

<!--vale off-->
{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Description
    key: description
rows:
  - strategy: "`keep_chars`"
    description: |
      Keeps the number of leading characters in `first` and the number of trailing characters in `last`.
      Replaces the middle of the value with `phrase`, which is required.

      If `first` plus `last` is equal to or more than the length of the value, the policy replaces the whole value with `phrase`.
      The policy never shows more characters than the original value. Because `phrase` has a fixed length, the masked value does not reveal the length of the original.
  - strategy: "`email`"
    description: |
      Masks an email address. Applies a separate strategy to `local_part` and to `domain`, and both are required.

      `local_part` accepts `keep_chars` or `replace`. `domain` accepts `keep_chars`, `replace`, or `keep_all`, which keeps the whole domain.
  - strategy: "`replace`"
    description: |
      Replaces the whole value with `phrase`. Use this strategy when no character of the original value can show.
{% endtable %}
<!--vale on-->

## Failure modes

The Mask Fields Produce policy supports the following failure modes:

{% table %}
columns:
  - title: Failure mode
    key: failure
  - title: Description
    key: description
rows:
  - failure: "`reject`"
    description: Rejects the record batch that holds the record.
  - failure: "`passthrough`"
    description: Sends the record to the backend cluster without a mask.
  - failure: "`mark`"
    description: |
      Sends the record to the backend cluster without a mask, and adds a `kong/policy-failure-<id>` header.
      The value of the header is the reason for the failure.
{% endtable %}

For a redaction policy, use `reject`.
Do not use `passthrough` or `mark`, because both write the original value to the cluster.

## Policy order

This policy needs the original value, so the order is important when a field is also encrypted.
Mask the fields before the [Encrypt Fields policy](/event-gateway/policies/encrypt-fields/) encrypts them.

See the reference for [nested policies](/event-gateway/entities/policy/#policy-nesting) for more detail.
