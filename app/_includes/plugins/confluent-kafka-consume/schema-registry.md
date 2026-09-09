The {{include.name}} plugin supports integration with Confluent Schema Registry for AVRO and JSON schemas. 

Schema registries provide a centralized repository for managing and validating schemas for data formats like AVRO and JSON.
Integrating with a schema registry allows the plugin to validate and serialize/deserialize messages in a standardized format.

Using a schema registry with {{site.base_gateway}} provides several benefits:

* **Data validation**: Ensures messages conform to a predefined schema before being processed.
* **Schema evolution**: Manages schema changes and versioning.
* **Interoperability**: Enables seamless communication between different services using standardized data formats.
* **Reduced overhead**: Minimizes the need for custom validation logic in your applications.

To learn more about Kong's supported schema registry, see:

* [Confluent Schema Registry Documentation](https://docs.confluent.io/platform/current/schema-registry/index.html)
* [AVRO Specification](https://avro.apache.org/docs/++version++/specification/)

### How schema registry validation works

{% if include.workflow == 'producer' %}

When a producer plugin is configured with a schema registry, the following workflow occurs:

<!--vale off-->
{% mermaid %}
sequenceDiagram
autonumber
    participant Client
    participant Kong as {{include.name}} plugin
    participant Registry as Schema Registry
    participant Kafka
    
    activate Client
    activate Kong
    Client->>Kong: Send request
    deactivate Client
    activate Registry
    Kong->>Registry: Fetch schema from registry
    Registry-->>Kong: Return schema
    deactivate Registry
    Kong->>Kong: Validate message against schema
    Kong->>Kong: Serialize using schema
    activate Kafka
    Kong->>Kafka: Forward to Kafka
    deactivate Kong
    deactivate Kafka
{% endmermaid %}
<!--vale on-->

If validation fails, the request is rejected with an error message.

{% elsif include.workflow == 'consumer' %}

When a consumer plugin is configured with a schema registry, the following workflow occurs:

<!--vale off-->
{% mermaid %}
sequenceDiagram
autonumber
    participant Kafka
    participant Kong as {{include.name}} plugin
    participant Registry as Schema Registry
    participant Client
    
    activate Kafka
    activate Kong
    Kafka->>Kong: Send message
    deactivate Kafka
    Kong->>Kong: Extract schema ID
    activate Registry
    Kong->>Registry: Fetch schema from registry
    Registry-->>Kong: Return schema
    deactivate Registry
    Kong->>Kong: Deserialize using schema
    activate Client
    Kong->>Client: Return response to client
    deactivate Kong
    deactivate Client
{% endmermaid %}
<!--vale on-->

{% endif %}

### Configure schema registry

To configure Schema Registry with the {{include.name}} plugin, use the [`config.schema_registry`](./reference/#schema--config-schema-registry) parameter in your plugin configuration. 

For sample configuration values, see:
* [Schema registry configuration example](./examples/schema-registry/)
{% if include.slug == 'confluent-consume' %}
* [Schema registry with OAuth2 configuration example](./examples/schema-registry-oauth2/) {% new_in 3.12 %}
{% endif %}

{% if include.workflow == 'producer' %}
### Accept plain JSON for Avro schemas {% new_in 3.16 %}

By default, an Avro schema requires every union-typed value to be wrapped in a single-key object that names the union branch. 
For example, a field declared as `["null", "string"]` must be sent as `{"string": "hello"}` or `{"null": null}`.
This forces HTTP clients to understand Avro's wire encoding to call your API.

Set `payload_encoding: simple_json` on the [`value_schema`](./reference/#schema--config-schema-registry-confluent-value-schema-payload-encoding) or the [`key_schema`](./reference/#schema--config-schema-registry-confluent-key-schema-payload-encoding) to let the {{include.name}} plugin accept plain JSON instead, and resolve union branches against the schema itself:

{% table %}
columns:
  - title: Value
    key: value
  - title: Resolution
    key: resolution
rows:
  - value: "`null`, or a nullable field is omitted"
    resolution: "Encoded as the union's `null` branch."
  - value: "A value matching exactly one non-null branch"
    resolution: "Encoded as that branch."
  - value: |
      A value matching more than one non-null branch (for example a JSON number against `["int", "long"]` or `["float", "double"]`)
    resolution: |
      Encoded using the first matching branch, in the order the branches are declared in the schema. 
      An integer that doesn't fit in a 32-bit signed range is always encoded as `long`, even if `int` is declared first.
  - value: "A value that doesn't match any branch of the union"
    resolution: "The request is rejected with an error that includes the JSON path and the branches that were considered."
{% endtable %}

This resolution applies at every level of the payload, including fields inside nested records, arrays, and maps. 
Logical types (for example timestamps, decimals, or UUIDs) are passed through unchanged once their union is resolved.

If a record field is omitted from the request body, the plugin falls back to the field's schema `default`, if one exists.
Otherwise, the field must be nullable, or the plugin rejects the request as missing a required field.

Because an Avro-tagged value like `{"string": "hello"}` already matches a single branch by name, `simple_json` accepts it as-is. 
This lets you migrate clients from `avro_json` to `simple_json` one at a time, instead of all at once.

For a sample configuration, see [Simple JSON encoding for Avro schemas](./examples/schema-registry-simple-json/).
{% endif %}





