
This guide requires and OIDC provider. In this example, we'll use Okta, but the steps are similar in any standard OIDC provider. See [Microsoft Entra ID](/how-to/configure-oidc-with-azure/), or run [Keycloak locally](https://www.keycloak.org/getting-started/getting-started-docker) and expose it with a tunnel.

You need an [Okta](https://login.okta.com/) admin account with a developer organization. If you prefer a different provider, 

1. In the Okta admin console, go to **Applications > Applications** and click **Create App Integration**.
1. Select **OIDC - OpenID Connect** and click **Next**.
1. Select **Web Application** and click **Next**.
1. In the **App integration name** field, enter a name such as `Dev Portal`.
1. Under **Grant type**, make sure **Authorization Code** is checked.
1. Under **Sign-in redirect URIs**, add your {{ site.dev_portal }} callback URL. Use the hostname you configured for your portal, for example: `https://portal.example.dev/callback`.
1. Click **Save**.
1. From the app's **General** tab, copy the **Client ID** and **Client Secret**.
1. Go to **Security > API > Authorization Servers** and copy the **Issuer** URI of the `default` server, for example, `https://your-org.okta.com/oauth2/default`.
1. Export the following environment variables:

   ```bash
   export OIDC_ISSUER_URL='YOUR_OKTA_ISSUER_URL'
   export OIDC_CLIENT_ID='YOUR_CLIENT_ID'
   export OIDC_CLIENT_SECRET='YOUR_CLIENT_SECRET'
   ```
