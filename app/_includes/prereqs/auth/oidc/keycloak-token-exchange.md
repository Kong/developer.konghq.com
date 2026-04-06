This tutorial requires an identity provider (IdP). If you don't have one, you can use [Keycloak](http://www.keycloak.org/). 
The steps will be similar in other standard identity providers.

For this tutorial, you will need two clients. We'll create both in Keycloak.

#### Install and run Keycloak

1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.

    For example, you can use the Keycloak Docker image:

    ```
    docker run -p 8080:8080 \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      quay.io/keycloak/keycloak start-dev
    ```

1. Export your issuer URL and Keycloak host to an environment variable so that you can pass them more securely. The issuer consists of your host, port, and realm name. For example, using Docker and the default `master` realm:

   ```sh
   export DECK_ISSUER='http://host.docker.internal:8080/realms/master'
   export KEYCLOAK_HOST='host.docker.internal'
   ```

1. Open the admin console.

    The default URL of the console is `http://$KEYCLOAK_HOST:8080/admin/master/console/`.

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
