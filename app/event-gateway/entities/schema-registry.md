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

works_on:
  - konnect

schema:
    api: event-gateway/knep
    path: /schemas/SchemaRegistry

api_specs:
    - event-gateway/knep

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

## Schema

{% entity_schema %}
