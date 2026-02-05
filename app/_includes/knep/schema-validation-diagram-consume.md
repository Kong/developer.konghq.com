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

  opt If schema isn't cached
    egw->>schema: Fetch schema
    schema-->>egw: Return schema
  end

  egw->>egw: Validate payload against schema

  alt If validation passed
    egw->>client: Forward
  else If validation failed
    alt If failure mode: skip
      egw->>egw: Drop message
    else If failure mode: mark
      egw->>client: Forward (marked invalid)
    end
  end

{% endmermaid %}
<!--vale on-->
