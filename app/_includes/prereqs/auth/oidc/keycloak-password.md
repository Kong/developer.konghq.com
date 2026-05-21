This tutorial requires an identity provider (IdP). If you don't have one, you can use [Keycloak](http://www.keycloak.org/). The steps will be similar in other standard identity providers.

#### Create a client

1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.

    For example, you can use the Keycloak Docker image:

    ```
    docker run -p 127.0.0.1:8080:8080 \
      -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
      -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
      quay.io/keycloak/keycloak start-dev
    ```
1. Open the admin console.

    The default URL of the console is `http://$YOUR_KEYCLOAK_HOST:8080/admin/master/console/`.
    
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
      * Client ID: any unique name, for example `kong`
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Standard flow**, **Direct access grants**, and **Service accounts roles** are checked.
  - section: "**Login settings**"
    settings: "**Valid redirect URIs**: `http://localhost:8000/*`"
{% endtable %}
<!--vale on-->

#### Set up keys and credentials
1. In your client, open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.
1. Switch to the Users menu and add a user.
1. Open the user's **Credentials** tab and add a password. Be sure to disable **Temporary Password**.

In this guide, we're going to use an example user named `alex` with the password `doe`.

#### Export to environment variables
Export your client secret, client ID, and issuer URL to environment variables so that you can pass them more securely.
For example:

```sh
export DECK_ISSUER='http://host.docker.internal:8080/realms/master'
export DECK_CLIENT_ID='kong'
export DECK_CLIENT_SECRET='UNT3GPzCKI7zUbhAmFSUGbj4wmiBDGiW'
```
