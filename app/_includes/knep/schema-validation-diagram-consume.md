<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant broker as Event broker
  participant egw as {{site.event_gateway_short}}
  participant schema as Schema registry
  participant client as Client

  broker->>egw: consume message
  
  alt well formatted data
  egw ->> schema: #123; "username": "johndoe",<br/>"age": 30 #125;

  schema->>schema: check against schema
  schema->>egw: successful validation
  egw->>client: pass message

  else bad data
  egw ->> schema: "#123; bad-data #125;"
  schema->>schema: check against schema
  schema -x egw: failed validation
  egw->>broker: warning or error response
  end

{% endmermaid %}
<!--vale on-->