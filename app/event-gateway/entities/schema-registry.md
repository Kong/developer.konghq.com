---
title: "Schema registry"
content_type: reference
layout: gateway_entity

description: |
    Schema registries are resources that let you validate messages against the Confluent schema registry.
related_resources:
  - text: "Schema Validation - produce policy"
    url: /event-gateway/policies/schema-validation-produce/
  - text: "Schema Validation - consume policy"
    url: /event-gateway/policies/schema-validation-consume/
tools:
    - konnect-api
    - terraform
    - kongctl

works_on:
  - konnect

schema:
    api: konnect/event-gateway
    path: /schemas/SchemaRegistry

api_specs:
    - konnect/event-gateway

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a schema registry?

Schema registries are resources that you can use in [Schema Validation policies](/event-gateway/policies/)
to validate messages against the [Confluent schema registry](https://docs.confluent.io/platform/current/schema-registry/index.html).

{{site.event_gateway_short}} supports the following registry types:
* Avro
* JSON Schema

You can also set `schema_type` to `any` {% new_in 1.3 %} to accept records in any supported format, rather than a single fixed format.
With `any`, {{site.event_gateway_short}} resolves the format of each record individually. Values that carry a schema reference, in the [Confluent wire format](https://docs.confluent.io/platform/current/schema-registry/fundamentals/serdes-develop/index.html#wire-format) or in a record header, are decoded using the registry. Any other value is parsed as JSON without a schema.

## Set up a schema registry

{% entity_example %}
type: schema_registry
data:
  name: my-schema-registry
  type: confluent
  config:
    schema_type: avro
    endpoint: endpoint
    timeout_seconds: 10
    authentication:
      type: basic
      username: username
      password: $MY_PASSWORD
{% endentity_example %}

{:.info}
> **Note**: {{site.event_gateway_short}} only requires **read-only** access to the schema registry to fetch schemas for validation.

## Security considerations

A policy can compute its behavior straight from schema metadata, for example a [Mask Fields](/event-gateway/policies/mask-fields-consume/) or [Encrypt Fields](/event-gateway/policies/encrypt-fields/) selector built from `record.value.schema.metadata.tags`, or a condition that checks `record.value.schema.metadata.properties`. For those policies, the registry is a trusted input.

That means anyone with write access to the registry can change what a policy does without touching the policy itself. For example, removing a `PII` tag stops a field from being masked or encrypted. The change takes effect for every record validated against that schema version, on every virtual cluster that uses it.

Restrict write access to the registry to the same degree you'd restrict the policies it drives. Review metadata changes before they go live, and keep a registry-side audit log so changes stay traceable after the fact.

## Schema

{% entity_schema %}
