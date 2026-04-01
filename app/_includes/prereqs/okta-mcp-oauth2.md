You need an [Okta](https://login.okta.com/) admin account with a developer organization.

Complete the following steps to configure Okta for MCP OAuth2 authentication. This setup creates two application registrations: a **Web Application** (used by {{site.base_gateway}} for token introspection) and a **Native Application** (used by MCP Inspector for the authorization code flow).

### Add a custom scope

1. Go to **Security > API > Authorization Servers**.
2. Click `default`.
3. Go to the **Scopes** tab.
4. Click **Add Scope**.
5. Name: `mcp:access`
6. Display phrase: `Access MCP tools`
7. Check **Set as a default scope**.
8. Click **Create**.

### Add an access policy

1. In the same `default` authorization server, go to the **Access Policies** tab.
2. Click **Add Policy**.
3. Name: `MCP Access`
4. Assign to: **All clients**
5. Click **Create Policy**.

### Add a rule to the policy

1. Inside the `MCP Access` policy, click **Add Rule**.
2. Rule Name: `Allow MCP`
3. Grant type: check **Client Credentials**, **Authorization Code**, and **Device Authorization**.
4. User is: **Any user assigned the app**
5. Scopes requested: **Any scopes**
6. Click **Create Rule**.

Export your Okta authorization server URL and introspection endpoint. To find these values:

1. Go to **Security > API > Authorization Servers**.
2. Click the `default` server.
3. Copy the **Issuer** URI (for example, `https://your-org.okta.com/oauth2/default`). This is the authorization server URL.
4. Append `/v1/introspect` to the Issuer URI to get the introspection endpoint.

```sh
export DECK_OKTA_AUTH_SERVER='https://your-org.okta.com/oauth2/default'
export DECK_OKTA_INTROSPECTION_ENDPOINT='https://your-org.okta.com/oauth2/default/v1/introspect'
```

### Create the web application (used by {{site.base_gateway}} for introspection)

1. Go to **Applications > Applications > Create App Integration**.
2. Sign-in method: **OIDC - OpenID Connect**
3. Application type: **Web Application**
4. App integration name: `Kong MCP Gateway`
5. Grant types: check **Client Credentials** and **Authorization Code**.
6. Sign-in redirect URIs: Select **Allow wildcard * in login URI redirect** set to any valid URL (for example, `http://127.0.0.1/*/callback`). {{site.ai_gateway}} does not use the redirect flow for this app, but Okta requires the field.
7. Assignments: **Skip group assignment for now**
8. Click **Save**.
9. Copy the **Client ID** and **Client Secret**. These go into the {{site.base_gateway}} `ai-mcp-oauth2` Plugin config.
10. Go to the **Assignments** tab, click **Assign > Assign to People**, and assign your user.
11. Export the credentials:

    ```sh
    export DECK_OKTA_CLIENT_ID='your-kong-web-app-client-id'
    export DECK_OKTA_CLIENT_SECRET='your-kong-web-app-client-secret'
    ```

### Create the native application (used by MCP Inspector)

1. Go to **Applications > Applications > Create App Integration**.
2. Sign-in method: **OIDC - OpenID Connect**
3. Application type: **Native Application**
4. App integration name: `MCP Inspector`
5. Grant types: check **Authorization Code**.
6. Sign-in redirect URIs: `http://localhost:6274/oauth/callback/debug`
7. Assignments: assign your user.
8. Click **Save**.
9. Copy the **Client ID**. This is the Client ID you enter in MCP Inspector. No secret is needed for this public client.

{:.info}
> The two applications serve different purposes. The **Web Application** Client ID and Client Secret go into the {{site.base_gateway}} `ai-mcp-oauth2` Plugin config for token introspection. The **Native Application** Client ID is what you enter in MCP Inspector when connecting to the OAuth-protected MCP endpoint.
