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
    client->>kong: Service with<br>access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/userinfo<br>with client credentials<br>and access token
    deactivate kong
    idp->>idp: authenticate client and<br>verify token
    activate kong
    idp->>kong: return user info <br>response
    deactivate idp
    kong->>kong: verify response<br>status code (200)
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