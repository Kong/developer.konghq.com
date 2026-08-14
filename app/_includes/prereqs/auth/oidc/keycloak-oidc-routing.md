This tutorial requires an identity provider (IdP). If you don't have one, you can use [Keycloak](http://www.keycloak.org/).
The steps will be similar in other standard identity providers.

For this tutorial, you need three clients: one for the OpenID Connect plugin to use when validating tokens, and two representing the API callers that will be routed to different backends.

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

   The `KC_HOSTNAME=http://localhost:8080` parameter ensures Keycloak always uses `localhost:8080` as its token issuer regardless of which URL it's accessed through.
   This is required because {{site.base_gateway}} runs inside Docker and accesses Keycloak via the container name `keycloak:8080`, but the `iss` claim in issued tokens must use `localhost:8080` for the plugin to recognize them.

1. Export your issuer URL, JWKS endpoint, and Keycloak host to environment variables.
   For example, using Docker and the default `master` realm:

   ```sh
   export DECK_ISSUER='http://localhost:8080/realms/master'
   export DECK_JWKS_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
   export KEYCLOAK_HOST='localhost'
   ```

   Because we're using Docker for this demo, we must configure a few networking parameters:
   * `DECK_ISSUER` and `KEYCLOAK_HOST` use `localhost` because that's how you access Keycloak from your machine.
   * `DECK_JWKS_ENDPOINT` uses the container name `keycloak` because {{site.base_gateway}} runs inside Docker and reaches Keycloak over the shared `kong-quickstart-net` network.

   In your own setup, especially running outside of a container, you may not need `DECK_JWKS_ENDPOINT`.

1. Open the admin console.

   The default URL is `http://localhost:8080/admin/master/console/`.

#### Create the plugin client

This client is used by the OpenID Connect plugin to connect to Keycloak for token validation.

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
      * Client ID: `kong`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure **Service accounts roles** is checked
{% endtable %}
<!--vale on-->

1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret** and export it along with the client ID:

   ```sh
   export DECK_CLIENT_ID='kong'
   export DECK_CLIENT_SECRET='YOUR-KONG-CLIENT-SECRET'
   ```

#### Create the caller clients

These clients represent the API callers. Each one authenticates to Keycloak with the client credentials grant. The `client_id` claim in each token is what Datakit uses to select the upstream.

Create the first caller client:

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
      * Client ID: `caller-a`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure **Service accounts roles** is checked
{% endtable %}
<!--vale on-->

1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret** and export it:

   ```sh
   export CALLER_A_SECRET='YOUR-CALLER-A-SECRET'
   ```

Create the second caller client:

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
      * Client ID: `caller-b`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure **Service accounts roles** is checked
{% endtable %}
<!--vale on-->

1. Open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret** and export it:

   ```sh
   export CALLER_B_SECRET='YOUR-CALLER-B-SECRET'
   ```
