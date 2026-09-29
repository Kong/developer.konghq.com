You need an [Okta](https://login.okta.com/) admin account with a developer organization.

#### Add a custom scope

1. Go to **Security > API > Authorization Servers**.
1. Click `default`.
1. Click to the **Scopes** tab.
1. Click **Add Scope**.
1. In the **Name** field, enter `api:access`.
1. In the **Display phrase** field, enter `Access protected APIs`.
1. Select the **Set as a default scope** checkbox.
1. Click **Create**.

#### Add an access policy

1. In the same `default` authorization server, click the **Access Policies** tab.
1. Click **Add New Access Policy**.
1. In the **Name** field, enter `API Access`.
1. In the **Assign to** settings, select **All clients**.
1. Click **Create Policy**.

#### Add a rule to the policy

1. From the `API Access` policy, click **Add Rule**.
1. In the **Rule Name** field, enter `Allow API Access`.
1. Grant type: check **Client Credentials**.
1. Scopes requested: **Any scopes**
1. Click **Create Rule**.

#### Create a web application

1. Go to **Applications > Applications > Create App Integration**.
1. For the **Sign-in method**, select **OIDC - OpenID Connect**.
1. For the **Application type**, select **Web Application**.
1. In the **App integration name** field, enter `{{site.ai_gateway}}`.
1. For the **Grant types** settings, click the **Client Credentials** checkbox.
1. For the **Assignments** settings, select **Skip group assignment for now**.
1. Click **Save**.
1. Copy the **Client ID** and **Client Secret**.

#### Export environment variables

1. Go to **Security > API > Authorization Servers**.
1. Click the `default` server.
1. Copy the **Issuer URI** (for example, `https://your-org.okta.com/oauth2/default`).
1. Export the following environment variables:

    ```sh
    export OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
    export OKTA_CLIENT_ID='your-client-id'
    export OKTA_CLIENT_SECRET='your-client-secret'
    ```
