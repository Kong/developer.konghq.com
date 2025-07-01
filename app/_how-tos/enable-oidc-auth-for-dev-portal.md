---
title: Automatically create Dev Portal applications in Okta with Dynamic Client Registration
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Okta.
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
    q: How do I 
    a: placeholder

prereqs:
  entities:
    services:
      - example-service
  inline:
    - title: Configure a Dev Portal
      include_content: prereqs/dev-portal-configure
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
cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

next_steps:
  - text: Learn how to manage application registration requests
    url: /dev-portal/access-and-approval/
---

## Copy the Okta issuer URL

Using your Okta credentials, log in to the Okta portal and click **Security > API** in the sidebar. The default Issuer URI should be displayed in the **Authorization Servers** tab. If you are using an authorization server that you configured, copy the issuer URL for that authorization server.

Set your issuer URL as an environment variable:
```sh
export ISSUER_URL='YOUR-ISSUER-URL'
```

## Add scopes in Okta

1. Click **Security > API** in the sidebar.

3. Select the authorization server that you want to configure.

4. Click the **Scopes** tab, and click **Add Scope**.

1. Configure the scope as needed.

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

1. In Okta, navigate to Applications > Applications in the sidebar.
1. Click Create App Integration.
1. Select **OIDC - OpenID Connect**.
1. Select **Web Application**.
1. Client credentials????
1. Export the client ID of your Okta app:
   ```sh
   export OKTA_CLIENT_ID='YOUR-OKTA-APP-CLIENT-ID'
   ```

## Configure Okta OIDC application authentication in Dev Portal

[Configure Okta OIDC application authentication](/api/konnect/application-auth-strategies/v2/#/operations/create-app-auth-strategy) using the `/v2/application-auth-strategies` endpoint:

<!--vale off-->
{% control_plane_request %}
url: /v2/application-auth-strategies
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
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
            - password
            scopes: 
            - profile
{% endcontrol_plane_request %}
<!--vale on-->

```sh
export AUTH_STRATEGY_ID='YOUR-AUTH-STRATEGY-ID'
```

## Apply the Okta OIDC auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

<!--vale off-->
{% capture publish %}
{% control_plane_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    auth_strategy_ids: 
    - $AUTH_STRATEGY_ID
{% endcontrol_plane_request %}
{% endcapture %}

{{ publish | indent: 3 }}
<!--vale on-->

<!--
## Register developer with your Dev Portal

```sh
curl --request POST \
  --url https://custom.example.com/api/v3/developer \
  --header 'Accept: application/problem+json' \
  --header 'Content-Type: application/json' \
  --header 'portalaccesstoken:  ' \
  --data '{
  "email": "dev@company.com",
  "full_name": "Dev Smith"
}'
```


## Create an app in the Dev Portal

```sh
curl --request POST \
  --url https://$PORTAL_URL/api/v3/applications \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "My App",
  "client_id": "'$OKTA_CLIENT_ID'"
}'
```
-->

## Create an app in Dev Portal

Navigate to your Dev Portal:

```sh
open https://$PORTAL_URL/apis
```

You should see `MyAPI` in the list of APIs. If an API is published as private, you must enable Dev Portal RBAC and [developers must sign in](/dev-portal/developer-signup/) to see APIs. To register an app with the API, do the following:

1. Click **View APIs**.
1. Click **Use this API**.
1. In the pop-up dialog, enter a name for the app and your client ID for your Okta application.
1. Click **Save**.

## Validate

?




