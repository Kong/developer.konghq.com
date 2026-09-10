---
title: Mask Fields Consume
name: Mask Fields Consume
content_type: plugin
description: Redact string fields of parsed Kafka records during the consume phase
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayParsedRecordMaskFieldsConsumePolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Mask Fields Produce policy
    url: /event-gateway/policies/mask-fields-produce/
  - text: Schema Validation Consume policy
    url: /event-gateway/policies/schema-validation-consume/
  - text: Decrypt Fields policy
    url: /event-gateway/policies/decrypt-fields/
  - text: Mask sensitive fields in Kafka messages with {{site.event_gateway}}
    url: /event-gateway/mask-kafka-message-fields/

phases:
  - consume

policy_target: virtual_cluster

categories:
  - security

icon: graph.svg

min_version:
  event-gateway: '1.3'
---

The Mask Fields Consume policy redacts `string` fields of Kafka records during the consume phase.
It runs on a record that a [Schema Validation Consume policy](/event-gateway/policies/schema-validation-consume/) parsed, so you must nest it under that policy.

Use this policy to redact a value only for the client that reads it.
The record in the backend cluster does not change, so systems that are permitted to see the original value keep their access to it.
To redact a value before {{site.event_gateway_short}} writes it to the cluster, use the [Mask Fields Produce policy](/event-gateway/policies/mask-fields-produce/) instead.

Select the fields to redact as a static list of paths, or as a single expression that returns a list of paths.
Each entry pairs a set of paths with the strategy that redacts them.

## Use cases

Common use cases for the Mask Fields Consume policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Mask a field for consumers only](/event-gateway/policies/mask-fields-consume/examples/mask-email-on-consume/)"
    description: |
      Redact an email field for the client that reads it, and keep the stored record unchanged.
  - use_case: "[Tutorial: Mask sensitive fields in Kafka messages](/event-gateway/mask-kafka-message-fields/)"
    description: |
      Redact the name, email, and SSN fields of customer records, so consumers can use a production topic while personal data stays hidden.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-consume/) parses the record.

1. A Kafka client sends a request to consume records to {{site.event_gateway_short}}.
1. The backend cluster returns the records, which hold the original values.
1. The parent Schema Validation policy parses the record value.
1. The Mask Fields Consume policy replaces the value of each selected field with a masked value.
1. {{site.event_gateway_short}} returns the masked record to the client. The stored record does not change.

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

The Mask Fields Consume policy supports the following failure modes:

{% table %}
columns:
  - title: Failure mode
    key: failure
  - title: Description
    key: description
rows:
  - failure: "`skip`"
    description: Does not deliver the record to the client.
  - failure: "`error`"
    description: Does not deliver the batch to the client.
  - failure: "`passthrough`"
    description: Delivers the record to the client without a mask.
  - failure: "`mark`"
    description: |
      Delivers the record to the client without a mask, and adds a `kong/policy-failure-<id>` header.
      The value of the header is the reason for the failure.
{% endtable %}

For a redaction policy, use `skip`.
Use `error` sparingly, because an error on a batch makes clients stop at the problematic offset, and an operator must intervene to skip it.
Do not use `passthrough` or `mark`, because both deliver the original value to the client.

## Policy order

This policy needs the original value, so the order is important when a field is also encrypted.
Let the [Decrypt Fields policy](/event-gateway/policies/decrypt-fields/) decrypt the fields before you mask them.

See the reference for [nested policies](/event-gateway/entities/policy/#policy-nesting) for more detail.
