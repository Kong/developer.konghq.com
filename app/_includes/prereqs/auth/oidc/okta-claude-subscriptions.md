You need an [Okta](https://login.okta.com/) admin account with a developer organization and two groups of users, one for subscription developers and one for company developers.

Complete the following steps in the Okta Admin Console. <!--TODO: verify steps in Okta-->

#### Create a custom authorization server

You need an Okta [custom authorization server](https://developer.okta.com/docs/concepts/auth-servers/), because the org authorization server can't issue custom scopes.

1. Go to **Security > API > Authorization Servers**.
1. Click **Add Authorization Server**.
1. In the **Name** field, enter `AI Gateway`.
1. In the **Audience** field, enter `api://ai-gateway`.
1. In the **Description** field, enter a description.
1. Click **Save**.

#### Add the company scope

1. In the `AI Gateway` authorization server, click the **Scopes** tab.
1. Click **Add Scope**.
1. In the **Name** field, enter `ai-gateway-company`.
1. In the **Display phrase** field, enter `Use company AI models`.
1. Click **Create**.

#### Create the native application

1. Go to **Applications > Applications**.
1. Click **Create App Integration**.
1. For the **Sign-in method**, select **OIDC - OpenID Connect**.
1. For the **Application type**, select **Native Application**.
1. Click **Next**.
1. In the **App integration name** field, enter `Claude Code`.
1. For the **Grant type**, make sure **Authorization Code** is selected.
1. In the **Sign-in redirect URIs** field, enter `http://localhost:9876/callback`.
1. For the **Assignments** settings, select **Limit access to selected groups**, and enter the names of both groups of developers.
1. Click **Save**.
1. On the **General** tab, copy the **Client ID**.

#### Add an access policy

1. Go to **Security > API > Authorization Servers**, and click the `AI Gateway` server.
1. Click the **Access Policies** tab.
1. Click **Add New Access Policy**.
1. In the **Name** field, enter `Claude Code`.
1. In the **Assign to** settings, select **The following clients**, and enter `Claude Code`.
1. Click **Create Policy**.

#### Add a rule for each group

1. In the `Claude Code` policy, click **Add Rule**.
1. In the **Rule Name** field, enter `Subscription developers`.
1. In the **Grant type** settings, select **Authorization Code**.
1. For **User is**, select **Assigned the app and a member of one of the following**, and enter the subscription developer group.
1. For **Scopes requested**, select **The following scopes**, and select `openid`.
1. Click **Create Rule**.
1. Click **Add Rule** again.
1. In the **Rule Name** field, enter `Company developers`.
1. In the **Grant type** settings, select **Authorization Code**.
1. For **User is**, select **Assigned the app and a member of one of the following**, and enter the company developer group.
1. For **Scopes requested**, select **The following scopes**, and select `openid` and `ai-gateway-company`.
1. Click **Create Rule**.

Don't allow `ai-gateway-company` in any other rule on this authorization server, because {{site.ai_gateway}} accepts any token from this server that has the audience and the scope.

#### Order the policies

On the **Access Policies** tab, drag the `Claude Code` policy above any policy that is assigned to **All clients**.

#### Export the issuer URL and client ID

1. On the **Settings** tab of the `AI Gateway` server, copy the **Issuer** URI.
1. Export the values:

   ```sh
   export ISSUER_URL='https://YOUR_OKTA_DOMAIN/oauth2/YOUR_AUTH_SERVER_ID'
   export OKTA_CLIENT_ID='YOUR_CLIENT_ID'
   ```
