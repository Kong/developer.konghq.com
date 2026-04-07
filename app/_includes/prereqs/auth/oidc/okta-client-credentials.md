You need an [Okta](https://login.okta.com/) admin account with a developer organization.

#### Add a custom scope

1. Go to **Security > API > Authorization Servers**.
1. Click `default`.
1. Go to the **Scopes** tab.
1. Click **Add Scope**.
1. Name: `api:access`
1. Display phrase: `Access protected APIs`
1. Check **Set as a default scope**.
1. Click **Create**.

#### Add an access policy

1. In the same `default` authorization server, go to the **Access Policies** tab.
1. Click **Add Policy**.
1. Name: `API Access`
1. Assign to: **All clients**
1. Click **Create Policy**.

#### Add a rule to the policy

1. Inside the `API Access` policy, click **Add Rule**.
1. Rule Name: `Allow API Access`
1. Grant type: check **Client Credentials**.
1. Scopes requested: **Any scopes**
1. Click **Create Rule**.

#### Create a web application

1. Go to **Applications > Applications > Create App Integration**.
1. Sign-in method: **OIDC - OpenID Connect**
1. Application type: **Web Application**
1. App integration name: `Kong Gateway`
1. Grant types: check **Client Credentials**.
1. Assignments: **Skip group assignment for now**
1. Click **Save**.
1. Copy the **Client ID** and **Client Secret**.

#### Export environment variables

1. Go to **Security > API > Authorization Servers**.
1. Click the `default` server.
1. Copy the **Issuer** URI (for example, `https://your-org.okta.com/oauth2/default`).
1. Export the following environment variables:

    ```sh
    export DECK_OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
    export DECK_OKTA_CLIENT_ID='your-client-id'
    export DECK_OKTA_CLIENT_SECRET='your-client-secret'
    ```
