<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>(Kong)
    participant idp as IdP <br>(e.g. Keycloak)
    participant httpbin as Upstream <br>(upstream service,<br> e.g. httpbin)
    activate client
    activate kong
    client->>kong: Service with<br>refresh token
    deactivate client
    kong->>kong: load refresh token
    activate idp
    kong->>idp: IdP/token with<br>client credentials and<br>refresh token
    deactivate kong
    idp->>idp: authenticate client and<br>verify refresh token
    activate kong
    idp->>kong: return tokens
    deactivate idp
    kong->>kong: verify tokens
    activate httpbin
    kong->>httpbin: request with access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->
