This guide requires an OIDC provider. In this example, we'll use [Keycloak](https://www.keycloak.org/), but the steps are similar in any standard OIDC provider.
Because {{site.konnect_short_name}} is cloud-hosted, it needs to reach your Keycloak instance over the public internet, so set up the ngrok tunnel prerequisite first.

#### Run Keycloak

Run Keycloak with its hostname set to your ngrok tunnel, so the tokens it issues use that URL as the issuer.
`KC_PROXY_HEADERS` tells Keycloak to trust the forwarded headers ngrok sends, so it reports `https` in the issuer instead of the `http` it sees internally:

```sh
docker run -p 127.0.0.1:8080:8080 \
  --name keycloak \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e KC_HOSTNAME=$NGROK_HOST \
  -e KC_PROXY_HEADERS=xforwarded \
  quay.io/keycloak/keycloak start-dev
```

Export your issuer URL, using the default `master` realm:

```sh
export OIDC_ISSUER_URL="$NGROK_HOST/realms/master"
```

#### Create a client for the client credentials grant

Get an admin access token from Keycloak's built-in `admin-cli` client, using the `password` grant with the admin credentials you set above:

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/realms/master/protocol/openid-connect/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: password
  client_id: admin-cli
  username: admin
  password: admin
extract_body:
  - name: access_token
    variable: ADMIN_ACCESS_TOKEN
capture:
  - variable: ADMIN_ACCESS_TOKEN
    jq: ".access_token"
status_code: 200
{% endhttp_request %}
<!--vale on-->

Create a client with service accounts enabled, using the [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/index.html#_clients):

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/admin/realms/master/clients
method: POST
headers:
  - 'Authorization: Bearer $ADMIN_ACCESS_TOKEN'
body:
  clientId: ai-cost-management
  protocol: openid-connect
  publicClient: false
  serviceAccountsEnabled: true
  clientAuthenticatorType: client-secret
status_code: 201
{% endhttp_request %}
<!--vale on-->

Export the client ID:

```sh
export OIDC_CLIENT_ID='ai-cost-management'
```

Keycloak's client create response has no body, so look up the client's internal ID by its `clientId`:

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/admin/realms/master/clients?clientId=$OIDC_CLIENT_ID
method: GET
headers:
  - 'Authorization: Bearer $ADMIN_ACCESS_TOKEN'
extract_body:
  - name: '[0].id'
    variable: KEYCLOAK_CLIENT_UUID
capture:
  - variable: KEYCLOAK_CLIENT_UUID
    jq: ".[0].id"
status_code: 200
{% endhttp_request %}
<!--vale on-->

Fetch the generated client secret:

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/admin/realms/master/clients/$KEYCLOAK_CLIENT_UUID/client-secret
method: GET
headers:
  - 'Authorization: Bearer $ADMIN_ACCESS_TOKEN'
extract_body:
  - name: value
    variable: OIDC_CLIENT_SECRET
capture:
  - variable: OIDC_CLIENT_SECRET
    jq: ".value"
status_code: 200
{% endhttp_request %}
<!--vale on-->

#### Set an email on the service account

Enabling service accounts creates a Keycloak user named `service-account-<clientId>` to represent this client.
Look up that user:

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/admin/realms/master/users?username=service-account-$OIDC_CLIENT_ID
method: GET
headers:
  - 'Authorization: Bearer $ADMIN_ACCESS_TOKEN'
extract_body:
  - name: '[0].id'
    variable: KEYCLOAK_SERVICE_ACCOUNT_USER_ID
capture:
  - variable: KEYCLOAK_SERVICE_ACCOUNT_USER_ID
    jq: ".[0].id"
status_code: 200
{% endhttp_request %}
<!--vale on-->

Set an email on the service account user that matches a row in your org structure file, so automatic user provisioning can link the principal it creates to that row:

<!--vale off-->
{% http_request %}
url: $NGROK_HOST/admin/realms/master/users/$KEYCLOAK_SERVICE_ACCOUNT_USER_ID
method: PUT
headers:
  - 'Authorization: Bearer $ADMIN_ACCESS_TOKEN'
  - 'Content-Type: application/json'
body:
  email: jordan.lee@example.com
  emailVerified: true
status_code: 204
{% endhttp_request %}
<!--vale on-->

{:.info}
> This client has one service account, so every token it issues carries the same `sub` and `email`.
> Every request authenticated through it resolves to the same principal, Jordan Lee.
> A real deployment authenticates each caller with their own token instead, so each one resolves to their own principal.
