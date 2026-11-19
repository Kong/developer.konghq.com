You need an [Okta](https://login.okta.com/) admin account with a developer organization.
{{site.kong_harnesses}} signs developers in to an Okta app with the authorization code flow and PKCE, and renews their access tokens with a refresh token.

Complete the following steps in the Okta Admin Console.

#### Create the native application

1. Go to **Applications > Applications**.
1. Click **Create App Integration**.
1. For the **Sign-in method**, select **OIDC - OpenID Connect**.
1. For the **Application type**, select **Native Application**.
1. Click **Next**.
1. In the **App integration name** field, enter `kong-harnesses`.
1. For the **Grant type**, make sure that **Authorization Code** is selected, and select **Refresh Token**.
   Without the **Refresh Token** grant, developers must sign in again each time their access token expires.
1. In the **Sign-in redirect URIs** field, enter `http://localhost:9876/callback`.
1. For the **Assignments** settings, select **Limit access to selected groups**, and enter a group that you are a member of.
1. Click **Save**.
1. On the **General** tab, check that **Proof Key for Code Exchange (PKCE)** is selected, and copy the **Client ID**.

#### Check the authorization server

This guide uses the `default` authorization server.
Its audience is `api://default`.

1. Go to **Security > API > Authorization Servers**, and click `default`.
1. On the **Scopes** tab, check that `openid`, `profile`, `email` and `offline_access` are listed.
   {{site.kong_harnesses}} requests these scopes, and Okta issues a refresh token only for `offline_access`.
1. On the **Access Policies** tab, check that a policy for all clients, or for the `kong-harnesses` app, has a rule that allows the **Authorization Code** grant type and these scopes.

#### Export the issuer URL and client ID

1. On the **Settings** tab of the `default` server, copy the **Issuer** URI.
1. Export the values:

   ```sh
   export ISSUER_URL='https://YOUR_OKTA_DOMAIN/oauth2/default'
   export OKTA_CLIENT_ID='YOUR_CLIENT_ID'
   ```
