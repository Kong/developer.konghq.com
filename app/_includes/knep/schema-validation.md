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
      Ensure that all messages produced for a specific topic are validated against a schema.
{% endtable %}
<!--vale on-->

## Schema registry

The {{include.name}} policy uses a schema registry for validation. 
You'll need to create a schema registry before enabling this policy. 

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
  - validation: "`json`"
    description: |
      Simple JSON parsing without a schema.
{% endtable %}

To create a schema registry, make a POST request to the `/schema-registries` endpoint of the {{site.event_gateway_short}} control plane API.
For example, to create a Confluent schema registry:

<!--vale off-->
{% konnect_api_request %}
url: /v1/event-gateways/$EVENT_GATEWAY_ID/schema-registries
status_code: 201
method: POST
body:
  name: my-schema-registry
  type: confluent
  config:
    schema_type: avro
    endpoint: endpoint
    timeout_seconds: 10
    authentication:
      type: basic
      username: username
      password: "${env[\"MY_SECRET\"]}"
{% endkonnect_api_request %}
<!--vale on-->