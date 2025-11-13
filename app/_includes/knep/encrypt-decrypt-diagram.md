1. A Kafka client produces a message and sends it to {{site.event_gateway_short}}.
1. {{site.event_gateway_short}} encrypts the specified values using the provided key.
1. {{site.event_gateway_short}} sends the encrypted message to the Kafka broker, which processes it using the key.
1. {{site.event_gateway_short}} decrypts the specified values using the provided key, then sends the message to the client.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant client as Client
  participant egw as {{site.event_gateway_short}}
  participant broker as Event broker

  client->>egw: produce message
  egw->>egw: encrypt message
  egw->>broker: send encrypted message
  broker->>egw: consume message
  egw->>egw: decrypt message
  egw->>client: send message

{% endmermaid %}
<!--vale on-->