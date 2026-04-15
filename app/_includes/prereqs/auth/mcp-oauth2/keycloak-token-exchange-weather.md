This tutorial requires [Keycloak](http://www.keycloak.org/) (version 26 or later) as the authorization server for MCP OAuth2 token exchange.

This setup is intentionally separate from the JWK validation guide. It uses a dedicated realm and separate clients so it doesn't interfere with any existing MCP OAuth2 configuration.

#### Install and run Keycloak

Run Keycloak using Docker on the same network as {{site.ai_gateway}}:

    ```sh
    docker run -p 127.0.0.1:8080:8080 \
      --name keycloak \
      --network kong-quickstart-net \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      -e KC_HOSTNAME=http://localhost:8080 \
      quay.io/keycloak/keycloak start-dev --features=token-exchange
    ```

1. Open the admin console at `http://localhost:8080/admin/master/console/`.

#### Create the isolated realm

1. In the top-left realm menu, click **Create realm**.
1. Set the realm name to `token-exchange`.
1. Click **Create**.

#### Create the MCP client

This client represents the application or agent that requests access to the MCP server.

1. In the `token-exchange` realm sidebar, open **Clients**, then click **Create client**.
1. Configure the client:

<!--vale off-->
{% table %}
columns:
  - title: Section
    key: section
  - title: Settings
    key: settings
rows:
  - section: "**General settings**"
    settings: |
      * Client type: **OpenID Connect**
      * Client ID: `token-exchange-client`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Direct access grants** is checked.
{% endtable %}
<!--vale on-->

#### Create the gateway client

This client represents {{site.base_gateway}}. It performs token introspection and token exchange.

1. In the `token-exchange` realm sidebar, open **Clients**, then click **Create client**.
1. Configure the client:

<!--vale off-->
{% table %}
columns:
  - title: Section
    key: section
  - title: Settings
    key: settings
rows:
  - section: "**General settings**"
    settings: |
      * Client type: **OpenID Connect**
      * Client ID: `token-exchange-gateway`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Standard Token Exchange** is checked.
{% endtable %}
<!--vale on-->

#### Create an optional audience scope for token exchange

Create an optional client scope that adds `token-exchange-gateway` to the `aud` claim. Keycloak requires the exchanging client to be present in the subject token's audience. Without this mapper, the token exchange request fails with "Client is not within the token audience".

1. In the sidebar, open **Client scopes**, then click **Create client scope**.
1. Set the name to `add-token-exchange-gateway-audience`.
1. Click **Save**.
1. Open the **Mappers** tab.
1. Click **Configure a new mapper** and select **Audience**.
1. Configure the mapper:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "**Name**"
    value: "`add-token-exchange-gateway-audience`"
  - field: "**Included Client Audience**"
    value: "`token-exchange-gateway`"
  - field: "**Add to access token**"
    value: "**on**"
{% endtable %}
<!--vale on-->

1. In the sidebar, open **Clients** and select `token-exchange-client`.
1. Open the **Client scopes** tab.
1. Click **Add client scope**.
1. Check `add-token-exchange-gateway-audience`, click **Add**, and set it as **Optional**.

#### Create a test user

1. In the sidebar, open **Users**, then click **Add user**.
1. Set the username to `alex`.
1. Click **Create**.
1. Open the **Credentials** tab and click **Set password**.
1. Set the password to `doe` and disable **Temporary Password**.

#### Export environment variables

1. In the sidebar, open **Clients** and select `token-exchange-client`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_TOKEN_EXCHANGE_CLIENT_ID='token-exchange-client'
   export DECK_TOKEN_EXCHANGE_CLIENT_SECRET='<token-exchange-client secret from Keycloak>'
   ```

1. In the sidebar, open **Clients** and select `token-exchange-gateway`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_TOKEN_EXCHANGE_GATEWAY_CLIENT_ID='token-exchange-gateway'
   export DECK_TOKEN_EXCHANGE_GATEWAY_CLIENT_SECRET='<token-exchange-gateway secret from Keycloak>'
   export DECK_TOKEN_EXCHANGE_KEYCLOAK_ISSUER='http://localhost:8080/realms/token-exchange'
   export DECK_TOKEN_EXCHANGE_KEYCLOAK_INTROSPECTION_URL='http://keycloak:8080/realms/token-exchange/protocol/openid-connect/token/introspect'
   export DECK_TOKEN_EXCHANGE_KEYCLOAK_TOKEN_URL='http://keycloak:8080/realms/token-exchange/protocol/openid-connect/token'
   export KEYCLOAK_HOST='localhost'
   ```
