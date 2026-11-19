You need an [Okta](https://login.okta.com/) admin account with a developer organization.
{{site.kong_harnesses}} signs developers in to an Okta app with the authorization code flow and PKCE.
The sign-in fails if Okta doesn't issue a refresh token, because {{site.kong_harnesses}} uses it to renew the access token.

Complete the following steps in the Okta Admin Console.

#### Create the native application

1. Go to **Applications > Applications**.
1. Click **Create App Integration**.
1. For the **Sign-in method**, select **OIDC - OpenID Connect**.
1. For the **Application type**, select **Native Application**.
1. Click **Next**.
1. In the **App integration name** field, enter `kong-harnesses`.
1. For the **Grant type**, make sure that **Authorization Code** is selected, and select **Refresh Token**.
1. In the **Sign-in redirect URIs** field, replace the default value with `http://localhost:9876/callback`.
1. For the **Assignments** settings, select **Limit access to selected groups**, and enter a group that you are a member of.
1. Click **Save**.
1. On the **General** tab, check that **Proof Key for Code Exchange (PKCE)** is selected, and copy the **Client ID**.

#### Check the authorization server

This guide uses the Okta `default` authorization server, which issues access tokens for the audience `api://default`.

1. Go to **Security > API > Authorization Servers**, and click `default`.
1. On the **Scopes** tab, check that `openid`, `profile`, `email` and `offline_access` are listed.
   {{site.kong_harnesses}} requests these scopes, and Okta issues a refresh token only for `offline_access`.
1. On the **Access Policies** tab, check that a policy for all clients, or for the `kong-harnesses` app, has a rule that allows the **Authorization Code** grant type and these scopes.

If no rule allows them, add a policy for the app:

1. On the **Access Policies** tab, click **Add New Access Policy**.
1. In the **Name** field, enter `kong-harnesses`.
1. In the **Assign to** settings, select **The following clients**, and enter `kong-harnesses`.
1. Click **Create Policy**.
1. Click **Add Rule**.
1. In the **Rule Name** field, enter `kong-harnesses sign-in`.
1. In the **Grant type** settings, select **Authorization Code**.
1. For **User is**, select **Any user assigned the app**.
1. For **Scopes requested**, select **Any scopes**.
1. Keep the access token lifetime at 1 hour.
   {{site.kong_harnesses}} refuses access tokens that are valid for more than 1 hour, unless the profile allows a longer lifetime.
1. Click **Create Rule**.

#### Export the issuer URL and client ID

1. On the **Settings** tab of the `default` server, copy the **Issuer** URI.
1. Export the values:

   ```sh
   export ISSUER_URL='https://YOUR_OKTA_DOMAIN/oauth2/default'
   export OKTA_CLIENT_ID='YOUR_CLIENT_ID'
   ```
