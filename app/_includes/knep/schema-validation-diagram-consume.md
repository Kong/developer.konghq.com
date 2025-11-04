<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant schema as Schema registry
  participant broker as Kafka broker

  client->>egw: Fetch new messages
  egw->>broker: Forward
  broker->>egw: Deliver message to consume

  opt Schema not cached
    egw->>schema: Fetch schema
    schema-->>egw: Return schema
  end

  egw->>egw: Validate payload against schema

  alt Validation passed
    egw->>client: Forward
  else Validation failed
    alt Failure mode: skip
      egw->>egw: Drop message
    else Failure mode: mark
      egw->>client: Forward (marked invalid)
    end
  end

{% endmermaid %}
<!--vale on-->
