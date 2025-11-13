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





