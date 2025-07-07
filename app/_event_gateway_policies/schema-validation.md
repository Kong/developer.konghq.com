---
title: Schema Validation
name: Schema Validation
content_type: reference
description: Validate records against a schema
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/SchemaValidationPolicy

api_specs:
  - event-gateway/knep

beta: true

icon: /assets/icons/graph.svg
---

This policy is used to validate records using a provided schema.

## Example configuration

Example configurations for the Schema Validation policy.

### Validate all messages for a topic

Ensure that all messages produced for a specific topic are validated against a schema:

```yaml
produce_policies:
  - match: "kafka.topic.name == \"xyz\""
    policies:
      - policy:
          type: schema_validation
          spec:
            record_value:
              schema_registry_name: my-registry
              failure_action: reject
```

### Validate all topics

Ensure that every topic is validated against a schema:

```yaml
produce_policies:
  - policies: # no match which means every topic requires a schema
      - policy:
          type: schema_validation
          spec:
            record_value:
              schema_registry_name: my-registry
              failure_action: reject
```

### Ensure that every topic has a schema

Let's say you want to migrate topics that don't have schemas and eventually ensure that every topic has a schema.

For example, assume that you have three topics without schemas: `topic-1`, `topic-2`, and `topic-3`.
Start by setting `failure_action` to `mark`, so that each invalid record is enriched with a `kong/sverr` header, which provides a client ID value.

Because we don't have policy overrides, we also need to exclude topics from the general rule. 

```yaml
produce_policies:
  - match: "kafka.topic.name == \"topic-1\" || kafka.topic.name == \"topic-2\" || kafka.topic.name == \"topic-3\""
    policies:
      - policy:
          type: schema_validation
          spec:
            record_value:
              schema_registry_name: my-registry
              failure_action: mark
  - match: "kafka.topic.name != \"topic-1\" && kafka.topic.name != \"topic-2\" && kafka.topic.name != \"topic-3\""
    policies:
      - policy:
          type: schema_validation
          spec:
            record_value:
              schema_registry_name: my-registry
              failure_action: reject
```

Now let's say that after some time, you migrated `topic-1`.
You can inspect the `kong_knep_kafka_schema_validation_failed_count{topic=topic-1}` metric to verify that clients don't produce invalid records.

If there are still invalid records, consume them from the topic looking for the `kong/sverr` header to identify a client that violates the schema.
If there are no invalid records, you can now remove `topic-1` from both expressions.

## Schema

{% entity_schema %}