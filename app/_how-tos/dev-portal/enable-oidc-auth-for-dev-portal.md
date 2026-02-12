---
title: Enable self-managed OIDC auth with Okta in Dev Portal
permalink: /how-to/enable-oidc-auth-for-dev-portal/
description: Learn how to allow Dev Portal developers to self-manage OIDC apps in Okta.
content_type: how_to

products:
    - gateway
    - dev-portal

works_on:
    - konnect
entities: []

automated_tests: false

tools:
    - deck
    # - konnect-api

tags:
    - application-registration
    - openid-connect
    - authentication
    - okta
search_aliases:
    - OpenID Connect

tldr:
    q: How do I allow Dev Portal developers to self-manage OIDC apps in Okta?
    a: |
      In Okta, you'll need your authorization server issuer URL and create the following:
      * A claim
      * An OIDC app with client credentials for the grant type
      * A custom scope and access policy that uses the client credentials grant and your Okta app

      In {{site.konnect_short_name}}, configure an OIDC auth strategy with your Okta issuer URL, your Okta claim name, `client_credentials` for the `auth_methods`, and your custom Okta scope. Any developers who register an application with an API with this authentication strategy applied to it can authenticate by sending `Authorization: Basic $OKTA_CLIENT_ID:$OKTA_CLIENT_SECRET` as a header, where `$OKTA_CLIENT_ID:$OKTA_CLIENT_SECRET` are base64 encoded.

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-auth-strategy-roles
      icon_url: /assets/icons/gateway.svg
    - title: Configure a Dev Portal
      include_content: prereqs/dev-portal-configure
      icon_url: /assets/icons/dev-portal.svg
    - title: Register a Dev Portal developer account
      content: |
        Register a test developer account with your Dev Portal by navigating to your Dev Portal and clicking **Sign up**:
        ```sh
        open https://$PORTAL_URL/
        ```
        
        For the purpose of this tutorial, we've set our Dev Portal to automatically approve developer registrations. 
      icon_url: /assets/icons/dev-portal.svg
    - title: Publish an API
      include_content: prereqs/publish-api
      icon_url: /assets/icons/dev-portal.svg
    - title: Okta
      include_content: prereqs/okta-sso
      icon_url: /assets/icons/okta.svg
related_resources:
  - text: Application registration
    url: /dev-portal/application-registration/
  - text: About Dev Portal OIDC authentication
    url: /dev-portal/auth-strategies/#dev-portal-oidc-authentication
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
  - text: Enable key authentication for Dev Portal apps
    url: /how-to/enable-key-auth-for-dev-portal/
cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg


faqs:
  - q: My published API is private in Dev Portal, how do I allow developers to see it?
    a: If an API is published as private, you must enable Dev Portal RBAC and [developers must sign in](/dev-portal/developer-signup/) to see APIs.

next_steps:
  - text: Learn how to manage application registration requests
    url: /dev-portal/access-and-approval/
---

## Copy the Okta issuer URL

Using your Okta credentials, log in to the Okta portal and click **Security > API** in the sidebar. The default Issuer URI should be displayed in the **Authorization Servers** tab. If you are using an authorization server that you configured, copy the issuer URL for that authorization server.

Export your issuer URL as an environment variable:
```sh
export ISSUER_URL='YOUR-ISSUER-URL'
```

## Add a claim in Okta

To map an application from the Dev Portal to Okta, you have to create a claim.

1. Click **Security > API** in the sidebar.

3. Select the authorization server that you want to configure.

4. Click the **Claims** tab, and then click **Add Claim**.

5. Enter a name for this claim, and enter `app.clientId` for **Value**. You can leave the **Value type** as "Expression", and include it in any scope.

1. Export the name of your claim in Okta as an environment variable:
   ```sh
   export OKTA_CLAIM_NAME='YOUR-OKTA-CLAIM-NAME'
   ```

## Create an application in Okta

When self-managed OIDC is enabled in Dev Portal, developers must create an application in Okta themselves.

1. In Okta, navigate to **Applications > Applications** in the sidebar.
1. Click **Create App Integration**.
1. Select **OIDC - OpenID Connect**.
1. Select **Web Application**.
1. Click **Client credentials** for the grant type.
1. Export the client ID and client secret of your Okta app:
   ```sh
   export OKTA_CLIENT_ID='YOUR-OKTA-APP-CLIENT-ID'
   export OKTA_CLIENT_SECRET='YOUR-OKTA-APP-CLIENT-SECRET'
   ```

## Add scopes and access policies in Okta

Because we're using the `client_credentials` auth method, you must create a custom Okta scope and access policy. 

1. Click **Security > API** in the sidebar.

3. Select the authorization server that you want to configure.

4. Click the **Scopes** tab, and click **Add Scope**.

1. Add a scope called `api.access`. 

1. On the Access Policy tab, create a new access policy and assign your Okta application you just created.

1. Add a new rule and configure the following settings:
   * **Grant type:** Client Credentials
   * **Scopes requested:** `api.access` 

## Configure Okta OIDC application authentication in Dev Portal

[Configure Okta OIDC application authentication](/api/konnect/application-auth-strategies/v2/#/operations/create-app-auth-strategy) using the `/v2/application-auth-strategies` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
status_code: 201
method: POST
body:
    name: Okta OIDC
    display_name: Okta OIDC
    strategy_type: openid_connect
    configs:
        openid-connect:
            issuer: $ISSUER_URL
            credential_claim: 
            - $OKTA_CLAIM_NAME
            auth_methods: 
            - client_credentials
            scopes: 
            - api.access
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of the Okta OIDC auth strategy:

```sh
export AUTH_STRATEGY_ID='YOUR-AUTH-STRATEGY-ID'
```

## Apply the Okta OIDC auth strategy to an API

Now that the application auth strategy is configured, you can [apply it to an API](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal) using the `/v3/apis/{apiId}/publications/{portalId}` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
body:
    auth_strategy_ids: 
    - $AUTH_STRATEGY_ID
{% endkonnect_api_request %}
<!--vale on-->

This request will also publish the API to the specified Dev Portal.

## Create an app in Dev Portal

To use your Okta OIDC credentials to authenticate with an app, you must first create an app in Dev Portal with the [test developer account you created previously](/how-to/enable-oidc-auth-for-dev-portal/#create-a-dev-portal-developer-account).

1. Navigate to your Dev Portal and log in with the test developer account:
   ```sh
   open https://$PORTAL_URL
   ```
   You should see `MyAPI` in the list of APIs.
1. To register an app with the API, click **View APIs**.
1. Click **Use this API**.
1. In the pop-up dialog, enter a name for the app and your client ID for your Okta application.
1. Click **Save**.

## Validate the password grant

Now, validate the setup by accessing the `example-route` Route and passing the user credentials in `Basic username:password` format. When you use the Okta OIDC authentication strategy, you use your Okta client ID as the username and your Okta client secret as the password, but they must be base64 encoded.

First, encode your credentials and export them:
```sh
echo -n "$OKTA_CLIENT_ID:$OKTA_CLIENT_SECRET" | base64
```
```sh
export ENCODED_CREDENTIALS='YOUR-ENCODED-CREDENTIALS'
```

Now, you can validate that Okta OIDC authentication was successfully enabled by sending a request with your encoded Okta credentials to the `example-route` Route:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
headers:
  - "Authorization: Basic $ENCODED_CREDENTIALS"
display_headers: true
{% endvalidation %}




