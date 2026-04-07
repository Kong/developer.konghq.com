This tutorial requires [Keycloak](http://www.keycloak.org/) (version 26 or later) as the authorization server for MCP OAuth2 token exchange.

#### Install and run Keycloak

1. Run Keycloak using Docker:

    ```sh
    docker run -p 127.0.0.1:8080:8080 \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      quay.io/keycloak/keycloak start-dev
    ```

1. Open the admin console at `http://localhost:8080/admin/master/console/`.

#### Configure the frontend URL

{{site.base_gateway}} runs inside Docker and validates the `iss` claim in tokens against the configured `authorization_servers`. Set the Keycloak frontend URL to `http://host.docker.internal:8080` so that the `iss` claim in issued tokens matches the URL that {{site.base_gateway}} uses to reach Keycloak.

1. Ensure `host.docker.internal` resolves on your host machine. On macOS or Linux, add it to `/etc/hosts` if it is not already present:

    ```sh
    sudo sh -c 'echo "127.0.0.1 host.docker.internal" >> /etc/hosts'
    ```

    On Windows, Docker Desktop adds this entry automatically.

1. In the admin console, open **Realm settings**.
1. In the **General** tab, set **Frontend URL** to `http://host.docker.internal:8080`.
1. Click **Save**.

#### Create the MCP client

This client represents the application or agent that requests access to the MCP server.

1. In the sidebar, open **Clients**, then click **Create client**.
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
      * Client ID: `mcp-client`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Direct access grants** is checked.
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->

#### Create the gateway client

This client represents {{site.base_gateway}}. It performs token introspection and token exchange.

1. In the sidebar, open **Clients**, then click **Create client**.
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
      * Client ID: `mcp-gateway`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Standard flow** and **Standard Token Exchange** are checked.
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->

#### Add an audience mapper to the MCP client

Add a protocol mapper to `mcp-client` so that tokens it obtains include `mcp-gateway` in the `aud` claim. Keycloak requires the exchanging client to be present in the subject token's audience. Without this mapper, the token exchange request fails with "Client is not within the token audience".

1. In the sidebar, open **Clients** and select `mcp-client`.
1. Open the **Client scopes** tab.
1. Click the `mcp-client-dedicated` scope.
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
    value: "`add-mcp-gateway-audience`"
  - field: "**Included Client Audience**"
    value: "`mcp-gateway`"
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

1. In the sidebar, open **Clients** and select `mcp-client`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_MCP_CLIENT_ID='mcp-client'
   export DECK_MCP_CLIENT_SECRET='<mcp-client secret from Keycloak>'
   ```

1. In the sidebar, open **Clients** and select `mcp-gateway`. Open the **Credentials** tab and copy the client secret.
1. Export the following environment variables:

   ```sh
   export DECK_MCP_GATEWAY_CLIENT_ID='mcp-gateway'
   export DECK_MCP_GATEWAY_CLIENT_SECRET='<mcp-gateway secret from Keycloak>'
   export DECK_KEYCLOAK_ISSUER='http://host.docker.internal:8080/realms/master'
   export DECK_KEYCLOAK_INTROSPECTION_URL='http://host.docker.internal:8080/realms/master/protocol/openid-connect/token/introspect'
   export DECK_KEYCLOAK_TOKEN_URL='http://host.docker.internal:8080/realms/master/protocol/openid-connect/token'
   ```
