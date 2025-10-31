This policy is used to validate messages using a provided schema during the {{include.phase}} phase.

Common use cases for the Schema Validation policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Validate all topics against a Confluent schema](/event-gateway/policies/{{include.slug}}/examples/validate-all-topics-confluent/)"
    description: |
      Ensure that every topic is validated against a Confluent schema registry.
  - use_case: "[Validate all topics against JSON](/event-gateway/policies/{{include.slug}}/examples/validate-all-topics-json/)"
    description: |
      Ensure that every topic is validated against an inferred JSON schema.
  - use_case: "[Validate all messages for a topic](/event-gateway/policies/{{include.slug}}/examples/validate-all-messages-for-topic/)"
    description: |
      Ensure that all messages for a specific topic are validated against a schema.
{% endtable %}
<!--vale on-->

## How it works

{% if include.phase == "produce" %}

This policy runs in the [produce phase](/event-gateway/entities/policy/#phases).

Here's how schema validation gets applied:

1. A Kafka client produces a message and sends it to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} passes the message to a schema registry, which validates the payload against a schema.
   * If the message passes validation, it gets passed along the Kafka broker, which processes it and sends a response.
   * If the message fails validation, the request is either rejected and dropped, or marked as incorrect and passed to the broker.
1. If the message is passed along, the broker processes the message as usual, and returns a response.

{% elsif include.phase == "consume" %}

This policy runs in the [consume phase](/event-gateway/entities/policy/#phases).

Here's how schema validation gets applied:

1. A Kafka client produces a message and sends it to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} passes the message to a Kafka broker.
1. The Kafka broker returns a response to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} passes the message to a schema registry, which validates the payload against a schema.
   * If the message passes validation, it gets passed back to the client.
   * If the message fails validation, the response is either rejected and dropped, or marked as incorrect and passed to the client.

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
