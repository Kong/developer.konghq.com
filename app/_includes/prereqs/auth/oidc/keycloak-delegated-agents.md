This tutorial needs an identity provider that can issue a token for a user and a client at the same time: `sub` identifies the user the request is made for, and `azp` identifies the client the agent authenticates as.
A client credentials token can't do this, because its subject is the client itself.
This tutorial uses [Keycloak](http://www.keycloak.org/) and its direct access grant. The steps are similar in other standard identity providers.

#### Install and run Keycloak

1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.

   For example, you can use the Keycloak Docker image.
   The following command attaches Keycloak to the same network as {{site.ai_gateway}}, so that the data plane can reach it, and publishes it on port `8081`, because the Petstore API uses `8080`:

   ```sh
   docker run -d \
     --name keycloak \
     --network kong-ai-quickstart-net \
     -p 8081:8080 \
     -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
     -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
     -e KC_HOSTNAME=http://localhost:8081 \
     quay.io/keycloak/keycloak:26.4 start-dev
   ```
   {:data-test-prereq="block"}

   `KC_HOSTNAME=http://localhost:8081` makes Keycloak issue tokens with `localhost:8081` as the `iss` claim, regardless of the URL it's reached through.
   The data plane validates that `iss` value but fetches keys over the Docker network, which is why the AI Auth Strategy sets `using_pseudo_issuer` and an explicit `jwks_endpoint` later in this tutorial.

1. Open the admin console at `http://localhost:8081/admin/master/console/` and sign in as `admin`.

#### Create the user

1. In the sidebar, open **Users**, then click **Add user**.
1. In the **Username** field, enter `dana`.
1. Click **Create**.
1. Click the **Credentials** tab.
1. Click **Set password**.
1. Set a password, toggle **Temporary** to **Off**, and save it.
1. Click the **Details** tab and copy the **ID**.

   This value is the `sub` claim of every token Keycloak issues for `dana`.

#### Create the clients

Create four clients. Three stand in for agents, and one is the client the AI Auth Strategy authenticates as.

For each of `support-agent`, `prototype-agent`, `unregistered-agent`, and `kong`:

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
      * Client ID: the client name
  - section: "**Capability config**"
    settings: |
      * Toggle **Client authentication** to **on**
      * Make sure that **Direct access grants** is checked
  - section: "**Login settings**"
    settings: "Leave the defaults"
{% endtable %}
<!--vale on-->

1. Click the **Credentials** tab, set **Client Authenticator** to **Client ID and Secret**, and copy the **Client Secret**.

#### Export environment variables

Export the Keycloak values this tutorial uses:

```sh
export KEYCLOAK_URL='http://localhost:8081'
export ISSUER='http://localhost:8081/realms/master'
export JWKS_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/certs'
export TOKEN_ENDPOINT='http://keycloak:8080/realms/master/protocol/openid-connect/token'
export USER_SUBJECT='THE-ID-YOU-COPIED-FROM-DANA'
export USER_PASSWORD='THE-PASSWORD-YOU-SET-FOR-DANA'
export CLIENT_ID='kong'
export CLIENT_SECRET='THE-KONG-CLIENT-SECRET'
export APPROVED_AGENT_CLIENT_ID='support-agent'
export APPROVED_AGENT_CLIENT_SECRET='THE-SUPPORT-AGENT-CLIENT-SECRET'
export UNAPPROVED_AGENT_CLIENT_ID='prototype-agent'
export UNAPPROVED_AGENT_CLIENT_SECRET='THE-PROTOTYPE-AGENT-CLIENT-SECRET'
export UNREGISTERED_AGENT_CLIENT_ID='unregistered-agent'
export UNREGISTERED_AGENT_CLIENT_SECRET='THE-UNREGISTERED-AGENT-CLIENT-SECRET'
```

`KEYCLOAK_URL` uses `localhost` because that's how you reach Keycloak from your machine.
`JWKS_ENDPOINT` and `TOKEN_ENDPOINT` use the `keycloak` container name, because the data plane reaches Keycloak over the shared Docker network.
