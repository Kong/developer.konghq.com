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
      * Client ID: `kong`
  - section: "**Capability config**"
    settings: |
      * Enable **Client authentication**.
      * Click the **Service accounts roles** checkbox.
{% endtable %}
<!--vale on-->

#### Create a claim

1. In your client, click the **Client scopes** tab.
1. Click the **kong-dedicated** client scope.
1. Click **Configure a new mapper**.
1. Select **Hardcoded claim**.
1. In the **Name** field, enter `tier`.
1. In the **Token Claim Name** field, enter `tier`.
1. In the **Claim value** field, enter `gold`.
1. Click **Save**.  

#### Set up keys and credentials
1. In your client, open the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.

#### Export to environment variables
Export your client secret and issuer URL to environment variables so that you can pass them more securely.
For example:

```sh
export DECK_ISSUER='http://host.docker.internal:8080/realms/master'
export CLIENT_SECRET='UNT3GPzCKI7zUbhAmFSUGbj4wmiBDGiW'
```
