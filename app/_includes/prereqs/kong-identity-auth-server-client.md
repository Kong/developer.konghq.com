You need a Kong Identity auth server and client application to authenticate requests.

{% navtabs 'ki-auth-server-client' %}
{% navtab "Look up existing" %}
Look up your existing auth server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers?filter[name][eq]=ai-cost-management-auth-server
status_code: 200
method: GET
extract_body:
  - name: 'data.[0].id'
    variable: AUTH_SERVER_ID
  - name: 'data.[0].issuer'
    variable: ISSUER_URL
capture:
  - variable: AUTH_SERVER_ID
    jq: ".data[0].id"
  - variable: ISSUER_URL
    jq: ".data[0].issuer"
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "Set up new" %}
Create an authorization server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
body:
  name: "ai-cost-management-auth-server"
  description: "Auth server for AI Cost Management attribution"
  audience: "ai-cost-management"
extract_body:
  - name: 'id'
    variable: AUTH_SERVER_ID
  - name: 'issuer'
    variable: ISSUER_URL
capture:
  - variable: AUTH_SERVER_ID
    jq: ".id"
  - variable: ISSUER_URL
    jq: ".issuer"
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}

A client requests a token under an OAuth2 scope.
Configure one using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope), so the client and the AI Auth Strategy can both be granted it:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
body:
  name: "ai-cost-management-access"
  description: "Scope for AI Cost Management attribution clients"
  default: false
  include_in_metadata: false
  enabled: true
extract_body:
  - name: 'id'
    variable: SCOPE_ID
capture:
  - variable: SCOPE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

A client's secret is only returned once, at creation, so this guide creates a new client rather than reusing one whose secret you might not have saved.

Create a client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
body:
  name: "ai-cost-management-kong-identity-client"
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  access_token_duration: 300
  grant_types:
    - client_credentials
  response_types:
    - token
  redirect_uris: []
  login_uri: ""
extract_body:
  - name: 'id'
    variable: CLIENT_ID
  - name: 'client_secret'
    variable: CLIENT_SECRET
capture:
  - variable: CLIENT_ID
    jq: ".id"
  - variable: CLIENT_SECRET
    jq: ".client_secret"
{% endkonnect_api_request %}
<!--vale on-->
