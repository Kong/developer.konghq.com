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
    client->>kong: Service with access token
    deactivate client
    kong->>kong: load access token
    activate idp
    kong->>idp: IdP/introspect with <br/>client credentials and access token
    deactivate kong
    idp->>idp: authenticate client <br/>and introspect access token
    activate kong
    idp->>kong: return introspection response
    deactivate idp
    kong->>kong: verify introspection response
    activate httpbin
    kong->>httpbin: request with <br/>access token
    httpbin->>kong: response
    deactivate httpbin
    activate client
    kong->>client: response
    deactivate kong
    deactivate client
{% endmermaid %}
<!--vale on-->