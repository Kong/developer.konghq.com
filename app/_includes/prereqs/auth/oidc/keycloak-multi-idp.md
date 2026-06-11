This tutorial requires two identity providers (IdPs).
If you don't have them, you can simulate two separate IdPs using two Keycloak realms.
The steps will be similar with other standard identity providers.

#### Install and run Keycloak

1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.

    For example, you can use the Keycloak Docker image. The following command attaches Keycloak to the same network as {{site.base_gateway}} so that the OIDC plugin can reach it:

    ```sh
    docker run -p 127.0.0.1:8080:8080 \
      --name keycloak \
      --network kong-quickstart-net \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      -e KC_HOSTNAME=http://localhost:8080 \
      quay.io/keycloak/keycloak start-dev
    ```

    The parameter `KC_HOSTNAME=http://localhost:8080` ensures Keycloak always uses `localhost:8080` as its token issuer regardless of which URL it's accessed through.
    This is required because {{site.base_gateway}} runs inside Docker and accesses Keycloak via the container name `keycloak:8080`, but the `iss` claim in issued tokens must use `localhost:8080` for the plugin to recognize them.

1. Export your environment variables. For example, using Docker and the `master` and `realm-b` realms:

   ```sh
   export DECK_REALM_A_ISSUER='http://localhost:8080/realms/master'
   export DECK_REALM_B_ISSUER='http://localhost:8080/realms/realm-b'
   export DECK_REALM_A_JWKS='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
   export DECK_REALM_B_JWKS='http://keycloak:8080/realms/realm-b/protocol/openid-connect/certs'
   export KEYCLOAK_HOST='localhost'
   ```

   Because we're using Docker for this demo, we have to configure a few networking parameters:
   * `DECK_REALM_A_ISSUER` and `DECK_REALM_B_ISSUER` use `localhost` because that's how you access Keycloak from your machine.
   * `DECK_REALM_A_JWKS` and `DECK_REALM_B_JWKS` use the container name `keycloak` because {{site.base_gateway}} runs inside Docker and reaches Keycloak over the shared `kong-quickstart-net` network.

   In your own setup, especially running outside of a container, you may not need `DECK_REALM_A_JWKS` and `DECK_REALM_B_JWKS`.

1. Open the Keycloak admin console.

    The default URL is `http://localhost:8080/admin/master/console/`.

1. Log in with the credentials you defined when you launched Keycloak.
For this example, the credentials are username `admin` and password `admin`.

#### Configure the first IdP

The `master` realm acts as the first identity provider.
Create a client for `realm-a`:

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
      * Client ID: `client-a`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Service accounts roles** is checked.
{% endtable %}
<!--vale on-->

Find the credentials for `client-a`:

1. In the sidebar, open **Clients**, and select `client-a`.
1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Export the client secret to an environment variable:

   ```sh
   export DECK_CLIENT_A_SECRET='YOUR-CLIENT-SECRET'
   ```

#### Configure the second IdP

Create a second Keycloak realm to simulate a second identity provider:

1. In the sidebar click **Manage realms**.
1. Click **Create realm**.
1. Set **Realm name** to `realm-b`.
1. Click **Create**.

Create a client for `realm-b`:

1. Make sure you're in the `realm-b` realm (check the top-left dropdown).
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
      * Client ID: `client-b`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Service accounts roles** is checked.
{% endtable %}
<!--vale on-->

Find the credentials for `client-b`:

1. In the sidebar, open **Clients**, and select `client-b`.
1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Export the client secret to an environment variable:

   ```sh
   export DECK_CLIENT_B_SECRET='YOUR-CLIENT-SECRET'
   ```
