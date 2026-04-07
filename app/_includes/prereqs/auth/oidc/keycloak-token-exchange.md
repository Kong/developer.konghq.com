This tutorial requires an identity provider (IdP). If you don't have one, you can use [Keycloak](http://www.keycloak.org/). 
The steps will be similar in other standard identity providers.

For this tutorial, you will need two clients. We'll create both in Keycloak.

#### Install and run Keycloak

1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.

    For example, you can use the Keycloak Docker image. The following command attaches Keycloak to the same network as {{site.base_gateway}} so that the OIDC plugin can reach it:

    ```
    docker run -p 127.0.0.1:8080:8080 \
      --name keycloak \
      --network kong-quickstart-net \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      -e KC_HOSTNAME=http://localhost:8080 \
      quay.io/keycloak/keycloak start-dev --features=token-exchange
    ```

1. Export your issuer URL, Keycloak host, and endpoint URLs to environment variables. For example, using Docker and the default `master` realm:

   ```sh
   export DECK_ISSUER='http://localhost:8080/realms/master'
   export DECK_JWKS_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
   export DECK_TOKEN_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/token'
   export KEYCLOAK_HOST='localhost'
   ```

   Because we're using Docker for this demo, we have to configure a few networking parameters:
   * `DECK_ISSUER` and `KEYCLOAK_HOST` use `localhost` because that's how you access Keycloak from your machine. 
   * `DECK_JWKS_ENDPOINT` and `DECK_TOKEN_ENDPOINT` use the container name `keycloak` because {{site.base_gateway}} runs inside Docker and reaches Keycloak over the shared `kong-quickstart-net` network.
   * `KC_HOSTNAME=http://localhost:8080` ensures Keycloak always uses `localhost:8080` as its token issuer regardless of which URL it's accessed through. This is required because {{site.base_gateway}} performs token exchange via `keycloak:8080`, and Keycloak must recognize the subject token's `iss` claim (`localhost:8080`) as its own issuer.

   In your own setup, especially running outside of a container, you may not need `DECK_JWKS_ENDPOINT` and `DECK_TOKEN_ENDPOINT`.

1. Open the admin console.

    The default URL of the console is `http://localhost:8080/admin/master/console/`.

#### Create and configure first client

Create the first client:

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
      * Client ID: `client-1`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Direct access grants** is checked.
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->

Find the credentials for the first client:

1. In the sidebar, open **Clients**, and select `client-1`.
1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Export the client ID and secret to environment variables:

   ```
   export DECK_CLIENT_ID_1='client-1'
   export DECK_CLIENT_SECRET_1='YOUR-CLIENT-SECRET'
   ```

#### Create and configure second client

Create the second client:

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
      * Client ID: `client-2`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Standard flow** and **Standard Token Exchange** are checked.
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->

Find the credentials for the second client:

1. In the sidebar, open **Clients**, and select `client-2`.
1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Export the client ID and secret to environment variables:

   ```
   export DECK_CLIENT_ID_2='client-2'
   export DECK_CLIENT_SECRET_2='YOUR-CLIENT-SECRET'
   ```

#### Configure client scopes

1. In the sidebar, open **Client scopes**, then click **Create client scope**.
1. Give the scope a unique name: `add-client-2-as-audience`.
1. Save the scope.
1. Click the **Mappers** tab.
1. Click **Configure a new mapper** and select **Audience**.
1. Configure the mapper:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Settings
    key: settings
rows:
  - field: "**Name**"
    settings: "`aud-client-2`"
  - field: "**Included client audience**"
    settings: "`client-2`"
{% endtable %}
<!--vale on-->

#### Apply scope to client

1. In the sidebar, open **Clients** and click `client-1`.
1. Click **Client scopes**.
1. Click **Add client scope**.
1. In the modal, check `add-client-2-as-audience`.
1. Click **Add** and set the scope as "Optional".

#### Set up user

1. Switch to the Users menu and add a user.
1. Open the user's **Credentials** tab and add a password. Be sure to disable **Temporary Password**.

   In this guide, we're going to use an example user named `alex` with the password `doe`.
