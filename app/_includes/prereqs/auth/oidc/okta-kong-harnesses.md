You need an [Okta developer organization](https://developer.okta.com/signup/) and an admin account in it.
{{site.kong_harnesses}} signs developers in to an Okta app with the authorization code flow and PKCE.
The sign-in fails if Okta doesn't issue a refresh token, because {{site.kong_harnesses}} uses it to renew the access token.
For the settings that every identity provider needs, see [Register {{site.kong_harnesses}} in your identity provider](/kong-harnesses/identity-provider/).

Complete the following steps in the Okta Admin Console.

#### Create the native application

1. Go to **Applications > Applications**.
1. Click **Create App Integration**.
1. For the **Sign-in method**, select **OIDC - OpenID Connect**.
1. For the **Application type**, select **Native Application**.
1. Click **Next**.
1. In the **App integration name** field, enter `kong-harnesses`.
1. For the **Grant type**, make sure that **Authorization Code** and **Refresh Token** are selected.
1. In the **Sign-in redirect URIs** field, replace the default value with `http://localhost:9876/callback`.
1. For the **Assignments** settings, select **Limit access to selected groups**, and enter a group that you are a member of, such as `Everyone`.
1. Click **Save**.
1. On the **General** tab, check that **Proof Key for Code Exchange (PKCE)** is selected, and copy the **Client ID**.

#### Check the authorization server

This guide uses the Okta `default` authorization server with the audience `api://default`.

1. Go to **Security > API > Authorization Servers**, and click `default`.
1. On the **Settings** tab, check that the **Audience** is `api://default`.
   If it's different, use that value in place of `api://default` in this guide.
1. On the **Scopes** tab, check that `openid`, `profile`, `email` and `offline_access` are listed.
   {{site.kong_harnesses}} requests these scopes, and Okta issues a refresh token only when the request includes `offline_access` and the app has the **Refresh Token** grant type.
1. On the **Access Policies** tab, find the first rule that matches the `kong-harnesses` app, your user, the **Authorization Code** grant type and these scopes.
   Okta checks policies in their order on this tab, and rules in their order in each policy.
1. Check that the access token lifetime of that rule is more than 6 minutes and at most 1 hour, because {{site.kong_harnesses}} refuses other lifetimes by default.

If no rule matches, or the lifetime of the first matching rule is outside this range, add a policy for the app:

1. On the **Access Policies** tab, click **Add New Access Policy**, or **Add Policy** if the list is empty.
1. In the **Name** field, enter `kong-harnesses`.
1. In the **Description** field, enter `Sign-in policy for kong-harnesses`.
1. In the **Assign to** settings, select **The following clients**, enter `kong-harnesses`, and select the app from the list.
1. Click **Create Policy**.
1. Click **Add Rule**.
1. In the **Rule Name** field, enter `kong-harnesses sign-in`.
1. In the **Grant type** settings, select **Authorization Code**.
1. For **User is**, select **Any user assigned the app**.
1. For **Scopes requested**, select **Any scopes**.
1. Keep the access token lifetime at 1 hour.
1. Click **Create Rule**.
1. On the **Access Policies** tab, drag the `kong-harnesses` policy to the top of the list.

#### Export the issuer URL and client ID

1. On the **Settings** tab of the `default` server, copy the **Issuer** URI.
1. Export the issuer URL and client ID as environment variables:

   ```sh
   export ISSUER_URL='https://YOUR_OKTA_DOMAIN/oauth2/default'
   export OKTA_CLIENT_ID='YOUR_CLIENT_ID'
   ```
