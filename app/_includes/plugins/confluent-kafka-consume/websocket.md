In `websocket` mode, the plugin maintains a bi-directional WebSocket connection with the client, 
allowing for continuous delivery of {{ include.broker }} messages to the client. 

Here's how it works:
1. Establish a WebSocket connection to the Route where the {{ include.name }} plugin is enabled and mode is set to `websocket`.
1. {{site.base_gateway}} continuously streams messages as JSON text frames.
1. Optionally, client sends acknowledgments (`client-acks`) for each message or batch to enable `at-least-once` delivery semantics.

This approach provides real-time message flow without the limitations of HTTP polling.

{% mermaid %}
sequenceDiagram
    participant Client
    participant Kong as {{site.base_gateway}}
    participant Broker as Message Broker

    Client->>Kong: Establish WebSocket connection
    Kong->>Broker: Connect to broker

    loop Continuous message delivery
        Broker->>Kong: Broker message
        Kong->>Client: Stream JSON text frame

        opt If client-acks
            Client->>Kong: Acknowledge message/batch
        end
    end

{% endmermaid %}

> _Figure 1: The diagram shows the bi-directional WebSocket flow where the {{include.name}} plugin is running in `websocket` mode, and messages are streamed as JSON text frames._

This mode provides parity with HTTP-based consumption, including support for:
* Message keys
* Topic filtering
* {{ include.broker }} authentication and TLS
* Auto or manual offset commits