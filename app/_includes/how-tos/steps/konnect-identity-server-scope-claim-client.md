## Create an auth server in Kong Identity

Before you can configure the authentication plugin, you must first create an auth server in Kong Identity. We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "Auth server for the Appointment dev environment"
extract_body:
  - name: 'id'
    variable: AUTH_SERVER_ID
  - name: 'issuer'
    variable: ISSUER_URL
{% endkonnect_api_request %}

Export the auth server ID and issuer URL:
```sh
export AUTH_SERVER_ID='YOUR-AUTH-SERVER-ID'
export ISSUER_URL='YOUR-ISSUER-URL'
```

## Configure the auth server with scopes 

Configure a scope in your auth server using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes 
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "my-scope"
  description: "Scope to test Kong Identity"
  default: false
  include_in_metadata: false
  enabled: true
extract_body:
  - name: 'id'
    variable: SCOPE_ID
capture: SCOPE_ID
jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->


## Configure the auth server with custom claims

Configure a custom claim using the [`/v1/auth-servers/$AUTH_SERVER_ID/claims` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClaim):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims 
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "test-claim"
  value: test
  include_in_token: true
  include_in_all_scopes: false
  include_in_scopes: 
  - $SCOPE_ID
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

You can also configure dynamic custom claims with [dynamic claim templating](/kong-identity/#dynamic-claim-templates) to generate claims during runtime.

## Create a client in the auth server

The client is the machine-to-machine credential. In this tutorial, {{site.konnect_short_name}} will autogenerate the client ID and secret, but you can alternatively specify one yourself. 

Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
extract_body:
  - name: 'client_secret'
    variable: CLIENT_SECRET
  - name: 'id'
    variable: CLIENT_ID
{% endkonnect_api_request %}
<!--vale on-->

Export your client secret and client ID:
```sh
export CLIENT_SECRET='YOUR-CLIENT-SECRET'
export CLIENT_ID='YOUR-CLIENT-ID'
```