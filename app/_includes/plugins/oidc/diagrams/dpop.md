<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>({{site.base_gateway}})
    participant upstream as Upstream <br>(backend service,<br> e.g. httpbin)
    participant idp as Authentication Server <br>(e.g. Keycloak)
    activate client
    client->>client: generate key pair
    client->>idp: POST /oauth2/token<br>DPoP:$PROOF
    deactivate client
    activate idp
    idp-->>client: DPoP bound access token ($AT)
    activate client
    deactivate idp
    client->>kong: GET https://example.com/resource<br>Authorization: DPoP $AT<br>DPoP: $PROOF
    activate kong
    deactivate client
    kong->>kong: validate $AT and $PROOF
    kong->>upstream: proxied request <br> GET https://example.com/resource<br>Authorization: Bearer $AT
    deactivate kong
    activate upstream
    upstream-->>kong: upstream response
    deactivate upstream
    activate kong
    kong-->>client: response
    deactivate kong
{% endmermaid %}
<!--vale on-->