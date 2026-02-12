<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant schema as Schema registry
  participant broker as Kafka broker

  client->>egw: Produce message

  opt If schema isn't cached
    egw->>schema: Fetch schema
    schema-->>egw: Return schema
  end

  egw->>egw: Validate payload against schema

  alt If validation passed
    egw->>broker: Forward
  else If validation failed
    alt If failure mode: reject
      egw -x client: Reject the message
    else If failure mode: mark
      egw->>broker: Forward (marked invalid)
    end
  end

{% endmermaid %}
<!--vale on-->
