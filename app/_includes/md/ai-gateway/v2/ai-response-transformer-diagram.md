<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant kong as {{site.ai_gateway}}
    participant backend as Backend service
    participant ai as AI LLM service
    activate client
    activate kong
    client->>kong: Sends a prompt
    deactivate client
    activate backend
    kong->>backend: Forwards the request unchanged
    backend->>kong: Returns the response to {{site.ai_gateway}}
    deactivate backend
    activate ai
    kong->>ai: Sends the response for transformation
    ai->>kong: Returns the transformed response
    deactivate ai
    activate client
    kong->>client: Returns the transformed response to the client
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

> _**Figure 1**: The diagram shows the journey of a consumer's prompt through {{site.ai_gateway}} to the 
backend service, where the response is transformed by an AI LLM service using Kong's AI Response Transformer Policy._
