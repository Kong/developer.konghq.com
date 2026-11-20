The following diagram shows the request and response flow when the {{include.name}} Policy inspects both directions:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Policy as {{include.name}} Policy
    participant Svc as {{include.service}}
    participant Model as AI Model
    participant LLM as Upstream LLM provider

    Client->>Policy: Send request
    Policy->>Svc: Send request body
    Svc->>Policy: Return verdict
    alt Request blocked
        Policy->>Client: Return error, request is not sent upstream
    else Request allowed
        Policy->>Model: Forward request
        Model->>LLM: Send request
        LLM->>Model: Return response
        Model->>Policy: Forward response
        Policy->>Svc: Send response body
        Svc->>Policy: Return verdict
        alt Response blocked
            Policy->>Client: Return error
        else Response allowed
{% if include.masking %}            Policy->>Policy: Mask content if configured
{% endif %}            Policy->>Client: Return response
        end
    end
{% endmermaid %}
<!--vale on-->

> _Figure 1: Request and response flow with the {{include.name}} Policy._
