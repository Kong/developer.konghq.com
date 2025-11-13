<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant schema as Schema registry
  participant broker as Kafka broker

  client->>egw: Produce message

  opt Schema not cached
    egw->>schema: Fetch schema
    schema-->>egw: Return schema
  end

  egw->>egw: Validate payload against schema

  alt Validation passed
    egw->>broker: Forward
  else Validation failed
    alt Failure mode: reject
      egw -x client: Reject the message
    else Failure mode: mark
      egw->>broker: Forward (marked invalid)
    end
  end

{% endmermaid %}
<!--vale on-->
