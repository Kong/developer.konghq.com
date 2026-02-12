This policy is used to validate messages using a provided schema during the {{include.phase}} phase.

Common use cases for the Schema Validation policy:

{% if include.phase == "produce" %}

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Validate messages against a Confluent Schema Registry](/event-gateway/policies/{{include.slug}}/examples/validate-all-confluent/)"
    description: |
      Ensure that all messages produced to any topic are validated against a Confluent Schema Registry, and mark messages that don't conform.
  - use_case: "[Example: Validate messages for subset of topics against JSON](/event-gateway/policies/{{include.slug}}/examples/validate-subset-json/)"
    description: |
      Ensure that all messages produced to topics with a specific prefix are valid JSONs, and reject messages that don't conform.
  - use_case: "[Example: Validate messages for a topic](/event-gateway/policies/{{include.slug}}/examples/validate-a-topic/)"
    description: |
      Ensure that all messages produced to a topic are validated against a schema, and reject messages that don't conform.
  - use_case: "[Tutorial: Filter Kafka records by classification headers](/event-gateway/filter-records-by-classification/)"
    description: Parses JSON records so that a nested [Modify Headers policy](/event-gateway/policies/modify-headers/) can add a header to specific records.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [produce phase](/event-gateway/entities/policy/#phases).

Here's how schema validation gets applied:

1. A Kafka client produces a message and sends it to {{site.event_gateway_short}}.
1. If not present already, {{site.event_gateway_short}} pulls the schema from a schema registry.
   {{site.event_gateway_short}} then validates the payload against the schema.
   * If the message passes validation, it gets passed along the Kafka broker, which processes it and sends a response.
   * If the message fails validation, the request is either rejected or marked as incorrect and passed to the broker.
1. If the message is passed along, the broker processes the message as usual, and returns a response.

{% elsif include.phase == "consume" %}
<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Validate messages against a Confluent Schema Registry](/event-gateway/policies/{{include.slug}}/examples/validate-all-confluent/)"
    description: |
      Ensure that all messages consumed from a topic are validated against a Confluent Schema Registry, and skip messages that don't conform.
  - use_case: "[Example: Validate messages for subset of topics against JSON](/event-gateway/policies/{{include.slug}}/examples/validate-subset-json/)"
    description: |
      Ensure that all messages consumed from topics with a specific prefix are valid JSONs, and skip messages that don't conform.
  - use_case: "[Example: Validate messages for a topic](/event-gateway/policies/{{include.slug}}/examples/validate-a-topic/)"
    description: |
      Ensure that all messages consumed from a topic are validated against a schema, and reject messages that don't conform.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases).

Here's how schema validation gets applied:

1. A Kafka client sends a request to consume a messages to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} passes the message to a Kafka broker.
1. The Kafka broker returns a response with a message to {{site.event_gateway_short}}.
1. If not present already, {{site.event_gateway_short}} pulls the schema from a schema registry.
   {{site.event_gateway_short}} then validates the payload against the schema.
   * If the message passes validation, it gets passed back to the client.
   * If the message fails validation, the message is either dropped or marked as incorrect and passed to the client.

{% endif %}

{% include_cached /knep/schema-validation-diagram-{{include.phase}}.md %}

## Validation types

The {{page.name}} policy supports the following validation options:

{% table %}
columns:
  - title: Validation option
    key: validation
  - title: Description
    key: description
rows:
  - validation: "`confluent_schema_registry`" 
    description: |
      Validates messages against the [Confluent schema registry](https://docs.confluent.io/platform/current/schema-registry/index.html).

      To use a Confluent schema registry for validation, first [create a schema registry resource](/event-gateway/entities/schema-registry/), then reference it in this policy.
  - validation: "`json`"
    description: |
      Simple JSON parsing without a schema.
{% endtable %}

## Failure modes

The {{page.name}} policy supports the following failure modes in case the validation fails:

{% if include.phase == "produce" %}

{% table %}
columns:
  - title: Failure mode
    key: failure
  - title: Description
    key: description
rows:
  - failure: "`reject`"
    description: |
      Rejects the batch that contains invalid message.
  - failure: "`mark`"
    description: |
      Passes the message to the broker. {{site.event_gateway_short}} adds additional headers to the message.
      `kong/sverr-key` if the key validation failed, `kong/sverr-value` if value validation failed.
      The value of the header is the ID of a client that produced invalid message.
{% endtable %}

{% elsif include.phase == "consume" %}

{% table %}
columns:
  - title: Failure mode
    key: failure
  - title: Description
    key: description
rows:
  - failure: "`skip`"
    description: |
      Skips the message from being delivered to the client.
  - failure: "`mark`"
    description: |
      {{site.event_gateway_short}} adds additional headers to the message before delivering it to the client.
      `kong/sverr-key` if the key validation failed, `kong/sverr-value` if value validation failed.
      The value of the header is the ID of a client that consumes invalid message.
{% endtable %}

{% endif %}

## Nested policies

This policy can serve as a parent policy. 
{%- if include.phase == 'produce' %}
You can nest [Modify Headers](/event-gateway/policies/modify-headers/examples/nested-policy/) policies within it.
{%- elsif include.phase == 'consume' %}
You can nest [Modify Headers](/event-gateway/policies/modify-headers/examples/nested-policy/) and [Skip Records](/event-gateway/policies/skip-record/examples/nested-policy/) policies within it.
{% endif %}

See the reference for [nested policies](/event-gateway/entities/policy/#policy-nesting) for more detail.

## Observability

{{site.event_gateway_short}} emits a `kong_keg_kafka_schema_validation_attempt_count` metric with the following labels:
* `part` - part of the record that was validated. Available values: `key` or `value`
* `result` - result of the validation. Available values: `success` or `fail`
* `topic` - name of the topic

Message rejection details are emitted at the DEBUG log level.
To enable DEBUG level logs set the `KEG__OBSERVABILITY__LOG_FLAGS` environment variable to `info,keg=debug`.
