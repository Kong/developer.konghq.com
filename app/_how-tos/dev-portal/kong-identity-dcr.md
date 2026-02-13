---
title: Automatically create Dev Portal applications in Kong Identity with Dynamic Client Registration
permalink: /how-to/kong-identity-dcr/
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Kong Identity.
content_type: how_to
products:
    - gateway
    - dev-portal

works_on:
    - konnect
entities: []
tools:
  - deck
automated_tests: false

tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - kong-identity
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: How do I automatically create and manage Dev Portal applications in Kong Identity?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in [Kong Identity](/kong-identity/). First, create an auth server for Kong Identity and copy your Issuer URL. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR. Apply the auth strategy to published APIs.

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Dev Portal
      content: |
        For this tutorial, you’ll need a Dev Portal and some Dev Portal settings, like a published API, pre-configured. These settings are essential for Dev Portal to function but configuring them isn’t the focus of this guide. If you don't have these settings already configured, follow these steps to pre-configure them:

        1. In the {{site.konnect_short_name}} sidebar, navigate to [**Dev Portal**](https://cloud.konghq.com/portals/).
        1. Click [**New portal**](https://cloud.konghq.com/portals/create).
        1. Click **Private portal**.
        1. In the **Portal name** field, enter `Test Kong Identity DCR`.
        1. Click **Create and continue**.
        1. Click **Save**.
        1. Copy and export your Dev Portal URL in your terminal:
           ```sh
           export PORTAL_URL='
           https://your-domain.us.kongportals.com'
           ```
        1. In your Dev Portal sidebar, click **Settings**.
        1. Click the **Security** tab.
        1. Enable **Auto approve applications**. 
           This auto approves developer applications in your Dev Portal and makes it easier to test. 
        1. Click **Save changes**.
        1. Click [**Dev Portal**](https://cloud.konghq.com/portals/) in the sidebar.
        1. In the Dev Portal sidebar, click [**APIs**](https://cloud.konghq.com/portals/apis/).
        1. Click **New API**.
        1. In the **API name** field, enter `test-kong-identity-dcr`.
        1. Click **Create**.
        1. Click **Gateway Service** tab.
        1. Click **Link Gateway Service**.
        1. From the **Control plane** dropdown menu, select "quickstart".
        1. From the **Gateway Service** dropdown menu, select "example-service".
        1. Click **Submit**.
        1. Navigate to your Dev Portal URL:
           ```sh
           open $PORTAL_URL
           ```
        1. Click **Sign up**.
           We'll create a test developer account that we can use to create a DCR app.
        1. Enter your name and email.
        1. Click **Create account**.
        1. If you haven't set developers to auto approval in Dev Portal, in the {{site.konnect_short_name}} sidebar, navigate to [**Dev Portal**](https://cloud.konghq.com/portals/).
        1. Click **Test Kong Identity DCR**.
        1. In the Dev Portal sidebar, click **Access and approvals**.
        1. Click your test developer.
        1. From the **Actions** dropdown menu, select "Approve". 
      icon_url: /assets/icons/dev-portal.svg
related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: About Dev Portal Dynamic Client Registration
    url: /dev-portal/dynamic-client-registration/
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
---

## Create an auth server in Kong Identity

Before you can configure DCR, you must first create an auth server in [Kong Identity](/kong-identity/). We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "Auth server for the Appointment dev environment"
{% endkonnect_api_request %}

Export the issuer URL:
```sh
export ISSUER_URL='YOUR-ISSUER-URL'
```

## Configure the Kong Identity Dynamic Client Registration in Dev Portal

After configuring Kong Identity, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Kong Identity DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

This tutorial uses the {{site.konnect_short_name}} UI to configure DCR, but you can also use the [Application Registration API](/api/konnect/application-auth-strategies/v2/#/operations/).

1. In the {{site.konnect_short_name}} sidebar, click [**Dev Portal**](https://cloud.konghq.com/portals/).
1. In the Dev Portal sidebar, click [**Application Auth**](https://cloud.konghq.com/portals/application-auth).
1. Click the **DCR provider** tab.
1. Click **New provider**.
1. In the **Name** field, enter `Kong Identity`.
1. In the **Provider Type** dropdown menu, select "Kong Identity".
1. In the **Auth Server** field, select "Appointments Dev".
1. Click **Save**.
1. Click the **Authentication strategy** tab.
1. Click **New authentication strategy**.
1. In the **Name** field, enter `Kong Identity`.
1. In the **Display name** field, enter `Kong Identity`.
1. In the **Authentication Type** dropdown menu, select "DCR".
1. In the **DCR Provider** dropdown menu, select "Kong Identity".
1. In the **Scopes** field, enter `openid`.
1. In the **Credential Claims** field, enter `sub`.
1. In the **Auth Methods** dropdown menu, select "client_credentials" and "bearer".
1. Click **Create**.

## Apply the Kong Identity DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. In the {{site.konnect_short_name}} sidebar, click [**Dev Portal**](https://cloud.konghq.com/portals/).
1. Click your Dev Portal.
1. In the Dev Portal sidebar, click **Published APIs**.
1. Click **Publish API**.
1. From the **API** dropdown menu, select "test-kong-identity-dcr". This is the API you [created in the prerequisites](#dev-portal)
1. In the **Authentication strategy** dropdown menu, select "Kong Identity". 
1. Click **Private**.
1. Click **Publish API**.

## Validate

Now that DCR is configured, you can create an application with Dynamic Client Registration by using a developer account.

1. Navigate to your Dev Portal URL:
   ```sh
   open $PORTAL_URL
   ```
1. Log in with your developer account.
1. Click **APIs**.
1. For the test-kong-identity-dcr API, click **View APIs**.
1. Click **Use this API**.
1. In the **Application name** field, enter `test-dcr`.
1. Click **Create and use API**.
1. Copy and export your client ID and secret:
   ```sh
   export CLIENT_ID='YOUR-CLIENT-ID'
   export CLIENT_SECRET='YOUR-CLIENT-SECRET'
   ```
   Make sure to store these values, as they will only be shown once.
1. Click **Copy secret and close**.
1. Create an access token with your client ID and secret:
   ```sh
   export ACCESS_TOKEN="$(curl -sS -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'grant_type=client_credentials' \
     -d "client_id=$CLIENT_ID" \
     -d "client_secret=$CLIENT_SECRET" \
     -d 'scope=openid' \
     "$ISSUER_URL/oauth/token" | jq -r '.access_token')"
   ```
1. Make an authorized request to the API:
{% capture api-request %}
{% validation request-check %}
url: '/anything'
headers:
  - 'Authorization: Bearer $ACCESS_TOKEN'
status_code: 200
{% endvalidation %}
{% endcapture %}
{{ api-request | indent: 3 }}