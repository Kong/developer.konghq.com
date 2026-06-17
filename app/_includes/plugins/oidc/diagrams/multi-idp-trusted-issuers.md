<!--vale off-->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as API Gateway<br>with OIDC plugin
    participant IdPA as IdP A<br>(primary issuer)
    participant IdPB as IdP B<br>(via extra_jwks_uris)
    participant U as Upstream<br>(backend service)

    C->>K: Request with bearer token
    activate K
    K->>K: Extract iss claim from token
    alt If iss matches IdP A
        K->>IdPA: Fetch JWKS (if not cached)
        IdPA-->>K: Public keys
    else If iss matches IdP B
        K->>IdPB: Fetch JWKS (if not cached)
        IdPB-->>K: Public keys
    end
    K->>K: Verify signature
    K->>K: Check iss against issuers_allowed
    K->>U: Proxy request with original token
    activate U
    U-->>K: Response
    deactivate U
    K-->>C: Response
    deactivate K
{% endmermaid %}
<!--vale on-->