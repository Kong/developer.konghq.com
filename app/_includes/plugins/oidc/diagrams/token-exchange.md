{% mermaid %}
sequenceDiagram
    participant C as Client<br>(e.g. mobile app)
    participant K as API Gateway <br>with OIDC plugin
    participant A as Authorization server<br>(e.g. Keycloak)
    participant U as Upstream<br>(backend service,<br>e.g. httpbin)

    C->>K: Request with subject token
    activate K
    note over K: Validate subject token<br>(iss, exp, nbf)
    K->>A: Token exchange request
    activate A
    A-->>K: Exchanged access token
    deactivate A
    K->>K: Validate exchanged token
    K->>U: Proxy request with exchanged token
    activate U
    U-->>K: Response
    deactivate U
    K-->>C: Response
    deactivate K
{% endmermaid %}