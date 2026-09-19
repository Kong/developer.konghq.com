---
title: Record Transcode Consume
name: Record Transcode Consume
content_type: plugin
description: "Convert an already schema-validated record value into a different serialization format before it is returned to the consumer."
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayParsedRecordTranscodeConsumePolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Record Transcode Produce policy
    url: /event-gateway/policies/record-transcode-produce/
  - text: Schema Validation Consume policy
    url: /event-gateway/policies/schema-validation-consume/
  - text: Schema registries
    url: /event-gateway/entities/schema-registry/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Consume Kafka records as JSON with {{site.event_gateway}}
    url: /event-gateway/consume-kafka-records-as-json-with-event-gateway/

phases:
  - consume

policy_target: virtual_cluster

categories:
  - transformations

icon: graph.svg

min_version:
  event-gateway: '1.3'
---

The Record Transcode Consume policy converts an already schema-validated record value into a different serialization format before {{site.event_gateway_short}} returns it to the consumer.
It runs on a record that was parsed by a [Schema Validation Consume policy](/event-gateway/policies/schema-validation-consume/), so you must nest it under that policy.

This policy supports converting between JSON, Avro, and Protobuf.

Use this policy to change the format of a record only for the client that reads it.
The record in the backend cluster doesn't change, so systems that are permitted to see the original format keep their access to it.
To convert the format of a record before {{site.event_gateway_short}} writes it to the backend cluster, use the [Record Transcode Produce policy](/event-gateway/policies/record-transcode-produce/) instead.

## Use cases

Common use cases for the Record Transcode Consume policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Convert Avro records to JSON for a consumer](/event-gateway/policies/record-transcode-consume/examples/convert-avro-to-json/)"
    description: |
      Convert Avro records read from the backend cluster to JSON using a schema registry reference, so a consumer that only understands JSON can read them.
  - use_case: "[Example: Convert records for a specific topic to JSON](/event-gateway/policies/record-transcode-consume/examples/convert-topic-to-json-on-condition/)"
    description: |
      Use a `condition` to convert records consumed from a single topic to JSON, and leave records on other topics unchanged.
  - use_case: "[Example: Convert Protobuf records to JSON for a consumer](/event-gateway/policies/record-transcode-consume/examples/convert-protobuf-to-json/)"
    description: |
      Convert Protobuf records read from the backend cluster to JSON using a schema registry reference, so a consumer that only understands JSON can read them.
  - use_case: "[Tutorial: Consume Kafka records as JSON](/event-gateway/consume-kafka-records-as-json-with-event-gateway/)"
    description: |
      Store records as Avro in the backend cluster, and convert them to JSON for a consumer that doesn't run a Schema Registry client.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-consume/) parses the record.

1. A Kafka client sends a request to consume records to {{site.event_gateway_short}}.
1. The backend cluster returns the records, which hold the original values.
1. The parent Schema Validation policy parses the record value.
1. The Record Transcode Consume policy converts the record value into the configured `output_format`.
   
   If the record value already matches `output_format`, the policy leaves it unchanged.
1. {{site.event_gateway_short}} returns the converted record to the client. The stored record doesn't change.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: consume request
  egw->>broker: fetch records
  broker->>egw: return records with original values
  egw->>egw: parse record (Schema Validation)
  egw->>egw: convert record value to output_format

  egw->>client: return record with converted value
{% endmermaid %}
<!--vale on-->

## Configuring the target schema

Set `output_format` to `json`, `avro`, or `protobuf`. 
Converting to Avro or Protobuf requires `schema_source`, because both formats need a schema to serialize the record value. 
Converting to JSON can optionally use `schema_source` to validate the converted value.

`schema_source` accepts one of the following types:

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - type: "`reference`"
    description: |
      Looks up an existing schema in a [schema registry](/event-gateway/entities/schema-registry/) using a `subject` and `version` that you compute with an expression. For example, `subject: ${context.topic.name + '-value'}` and `version: ${'latest'}`.
  - type: "`inline`"
    description: |
      Embeds the raw schema text (for example, an Avro JSON schema) directly in the policy configuration.
{% endtable %}
<!--vale on-->

When converting to Protobuf, `schema_source` must also set `message_name` to the fully qualified name of the Protobuf message to serialize the record value as. A single Protobuf schema can define multiple messages, so {{site.event_gateway_short}} can't infer which one to use.

Leave `schema_source` unset if you don't need a schema for the output data, for example when converting to JSON without validating the result.

### Recording the schema reference

`schema_ref_destination` determines whether and how {{site.event_gateway_short}} records a reference to the output schema on the converted record:

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - type: "`confluent_format`"
    description: |
      Prefixes the structured data bytes with a reference to the schema, following the [Confluent wire format](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#wire-format).
  - type: "`record_header`"
    description: |
      Puts the schema reference in a record header. The header name defaults to `__value_schema_id`, which is compatible with Confluent's serializer, but you can change it.
  - type: "`none`"
    description: Doesn't persist the schema reference anywhere.
{% endtable %}
<!--vale on-->

## Failure modes

The Record Transcode Consume policy supports the following failure modes:

{% table %}
columns:
  - title: Failure mode
    key: failure
  - title: Description
    key: description
rows:
  - failure: "`skip`"
    description: Doesn't deliver the record to the client.
  - failure: "`error`"
    description: Doesn't deliver the batch to the client.
  - failure: "`passthrough`"
    description: Delivers the record to the client without converting it.
  - failure: "`mark`"
    description: |
      Delivers the record to the client without converting it, and adds a `kong/policy-failure-<id>` header.
      The value of the header is the reason for the failure.
{% endtable %}

Conversion fails when the record value can't be converted to `output_format`, or when the converted value doesn't satisfy the schema referenced by `schema_source`.

Use `error` sparingly, because an error on a batch makes clients stop at the problematic offset, and an operator must intervene to skip it.

## Policy order

This policy needs the parsed record value, so nest it directly under the [Schema Validation Consume policy](/event-gateway/policies/schema-validation-consume/) that parses it.

This policy doesn't support nested policies of its own.

See the reference for [nested policies](/event-gateway/entities/policy/#policy-nesting) for more detail.
