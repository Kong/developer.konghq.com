<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant kong as Kong Gateway
    participant ai as AI LLM service
    participant backend as Backend service
    activate client
    activate kong
    client->>kong: Sends a request
    deactivate client
    activate ai
    kong->>ai: Sends client's request for transformation
    ai->>kong: Transforms request
    deactivate ai
    activate backend
    kong->>backend: Sends transformed request to backend
    backend->>kong: Returns response to Kong Gateway
    deactivate backend
    activate ai
    kong->>ai: Sends response to AI service
    ai->>kong: Transforms response
    deactivate ai
    activate client
    kong->>client: Returns transformed response to client
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->

> _**Figure 1**: The diagram shows the journey of a consumer's request through {{site.base_gateway}} to the 
backend service, where it is transformed by both an AI LLM service and Kong's AI Request Transformer and the AI Response Transformer plugins._