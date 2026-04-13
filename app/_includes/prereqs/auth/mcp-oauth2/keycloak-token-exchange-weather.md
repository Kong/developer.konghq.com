This tutorial requires [Keycloak](http://www.keycloak.org/) (version 26 or later) as the authorization server for MCP OAuth2 token exchange.

This setup is intentionally separate from the JWK validation guide. It uses a dedicated realm and separate clients so it doesn't interfere with any existing MCP OAuth2 configuration.

#### Install and run Keycloak

1. Make sure the Docker network used by Kong Gateway exists:

    ```sh
    docker network create kong-quickstart-net
    ```

1. Run Keycloak using Docker on the same network as Kong Gateway:

    ```sh
    docker run -p 127.0.0.1:8080:8080 \
      --name keycloak \
      --network kong-quickstart-net \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      -e KC_HOSTNAME=http://localhost:8080 \
      quay.io/keycloak/keycloak start-dev
    ```

1. Open the admin console at `http://localhost:8080/admin/master/console/`.

#### Create the isolated realm

1. In the top-left realm menu, click **Create realm**.
1. Set the realm name to `weather-exchange`.
1. Click **Create**.

#### Create the MCP client

This client represents the application or agent that requests access to the MCP server.

1. In the `weather-exchange` realm sidebar, open **Clients**, then click **Create client**.
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
      * Client ID: `weather-exchange-client`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Direct access grants** is checked.
{% endtable %}
<!--vale on-->

#### Create the gateway client

This client represents {{site.base_gateway}}. It performs token introspection and token exchange.

1. In the `weather-exchange` realm sidebar, open **Clients**, then click **Create client**.
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
      * Client ID: `weather-exchange-gateway`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Standard Token Exchange** is checked.
{% endtable %}
<!--vale on-->

#### Add an audience mapper to the MCP client

Add a protocol mapper to `weather-exchange-client` so that tokens it obtains include `weather-exchange-gateway` in the `aud` claim. Keycloak requires the exchanging client to be present in the subject token's audience. Without this mapper, the token exchange request fails with "Client is not within the token audience".

1. In the sidebar, open **Clients** and select `weather-exchange-client`.
1. Open the **Client scopes** tab.
1. Click the `weather-exchange-client-dedicated` scope.
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
    value: "`add-weather-exchange-gateway-audience`"
  - field: "**Included Client Audience**"
    value: "`weather-exchange-gateway`"
  - field: "**Add to access token**"
    value: "**on**"
{% endtable %}
<!--vale on-->

#### Create a test user

1. In the sidebar, open **Users**, then click **Add user**.
1. Set the username to `alex`.
1. Click **Create**.
1. Open the **Credentials** tab and click **Set password**.
1. Set the password to `doe` and disable **Temporary Password**.

#### Export environment variables

1. In the sidebar, open **Clients** and select `weather-exchange-client`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_WEATHER_EXCHANGE_CLIENT_ID='weather-exchange-client'
   export DECK_WEATHER_EXCHANGE_CLIENT_SECRET='<weather-exchange-client secret from Keycloak>'
   ```

1. In the sidebar, open **Clients** and select `weather-exchange-gateway`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_WEATHER_EXCHANGE_GATEWAY_CLIENT_ID='weather-exchange-gateway'
   export DECK_WEATHER_EXCHANGE_GATEWAY_CLIENT_SECRET='<weather-exchange-gateway secret from Keycloak>'
   export DECK_WEATHER_EXCHANGE_KEYCLOAK_ISSUER='http://localhost:8080/realms/weather-exchange'
   export DECK_WEATHER_EXCHANGE_KEYCLOAK_INTROSPECTION_URL='http://keycloak:8080/realms/weather-exchange/protocol/openid-connect/token/introspect'
   export DECK_WEATHER_EXCHANGE_KEYCLOAK_TOKEN_URL='http://keycloak:8080/realms/weather-exchange/protocol/openid-connect/token'
   export KEYCLOAK_HOST='localhost'
   ```
