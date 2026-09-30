---
title: Record Transcode Produce
name: Record Transcode Produce
content_type: plugin
description: "Convert an already schema-validated record value into a different serialization format before it is produced to the backend cluster."
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: konnect/event-gateway
  path: /schemas/EventGatewayParsedRecordTranscodeProducePolicy

api_specs:
  - konnect/event-gateway

related_resources:
  - text: Record Transcode Consume policy
    url: /event-gateway/policies/record-transcode-consume/
  - text: Schema Validation Produce policy
    url: /event-gateway/policies/schema-validation-produce/
  - text: Schema registries
    url: /event-gateway/entities/schema-registry/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Policies
    url: /event-gateway/entities/policy/

phases:
  - produce

policy_target: virtual_cluster

categories:
  - transformations

icon: graph.svg

min_version:
  event-gateway: '1.3'
---

The Record Transcode Produce policy converts an already schema-validated record value into a different serialization format before {{site.event_gateway_short}} produces it to the backend cluster.
It runs on a record that was already parsed by a [Schema Validation Produce policy](/event-gateway/policies/schema-validation-produce/), so you must nest it under that policy.

This policy supports converting between JSON and Avro.

Use this policy to change the format of a record before {{site.event_gateway_short}} writes it to the backend cluster.
This change is irreversible, because the cluster never receives the record in its original format.
To convert the format of a record only for the client that reads it, and keep the stored record unchanged, use the [Record Transcode Consume policy](/event-gateway/policies/record-transcode-consume/) instead.

## Use cases

Common use cases for the Record Transcode Produce policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Example: Convert JSON records to Avro before they reach the cluster](/event-gateway/policies/record-transcode-produce/examples/convert-json-to-avro/)"
    description: |
      Convert a client's JSON records to Avro using an inline schema, so the backend cluster only stores Avro data.
  - use_case: "[Example: Convert records for a specific topic to Avro](/event-gateway/policies/record-transcode-produce/examples/convert-topic-to-avro-on-condition/)"
    description: |
      Use a `condition` to convert records produced to a single topic to Avro, and leave records on other topics unchanged.
{% endtable %}
<!--vale on-->

## How it works

This policy runs in the [produce phase](/event-gateway/entities/policy/#phases), after [schema validation](/event-gateway/policies/schema-validation-produce/) parses the record.

1. A Kafka client produces a record and sends it to {{site.event_gateway_short}}.
1. The parent Schema Validation policy parses the record value.
1. The Record Transcode Produce policy converts the record value into the configured `output_format`.
   
   If the record value already matches `output_format`, the policy leaves it unchanged.
1. {{site.event_gateway_short}} sends the record to the backend cluster, which stores the converted value.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: produce record
  egw->>egw: parse record (Schema Validation)
  egw->>egw: convert record value to output_format

  egw->>broker: send record with converted value
{% endmermaid %}
<!--vale on-->

## Configuring the target schema

Set `output_format` to `json` or `avro`. Converting to Avro requires `schema_source`, because Avro needs a schema to serialize the record value. 
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

The Record Transcode Produce policy supports the following failure modes:

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
    description: Sends the record to the backend cluster without converting it.
  - failure: "`mark`"
    description: |
      Sends the record to the backend cluster without converting it, and adds a `kong/policy-failure-<id>` header.
      The value of the header is the reason for the failure.
{% endtable %}

Conversion fails when the record value can't be converted to `output_format`, or when the converted value doesn't satisfy the schema referenced by `schema_source`.

## Policy order

This policy needs the parsed record value, so nest it directly under the [Schema Validation Produce policy](/event-gateway/policies/schema-validation-produce/) that parses it.

This policy doesn't support nested policies of its own.

See the reference for [nested policies](/event-gateway/entities/policy/#policy-nesting) for more detail.
