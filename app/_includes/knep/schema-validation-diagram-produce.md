<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant schema as Schema registry
  participant broker as Event broker

  client ->> egw: produce message
  alt well formatted data
  egw ->> schema: #123; "username": "johndoe",<br/>"age": 30 #125;

  schema->>schema: check against schema
  schema->>egw: successful validation
  egw->>broker: pass message

  else bad data
  egw ->> schema: "#123; bad-data #125;"
  schema->>schema: check against schema
  schema -x egw: failed validation
  egw->>client: warning or error
  end

{% endmermaid %}
<!--vale on-->