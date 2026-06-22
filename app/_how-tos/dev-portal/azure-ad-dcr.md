---
title: Automatically create and manage Dev Portal applications in Azure AD with Dynamic Client Registration
permalink: /how-to/azure-ad-dcr/
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Azure AD.
content_type: how_to

products:
    - gateway
    - dev-portal

works_on:
    - konnect
tools:
  - konnect-api
entities: []
automated_tests: false
tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - azure
search_aliases:
    - dcr
    - OpenID Connect
    - Azure Active Directory
    - Entra

tldr:
    q: How do I automatically create and manage Dev Portal applications in Azure AD?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in Azure AD. First, create an application in Azure and configure the `Application.ReadWrite.OwnedBy` and `User.Read` API permissions, select **Accounts in this organizational directory only** for the supported account types, and create a client secret. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR.
faqs:
  - q: Can developers rotate their Entra DCR credentials?
    a: Yes, developers can create multiple Entra DCR credentials and revoke old ones as needed. See [Managing credentials](/dev-portal/dynamic-client-registration/#managing-credentials) for more information.
prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-dcr-roles
      icon_url: /assets/icons/gateway.svg
    - title: Configure a Dev Portal and an API
      include_content: prereqs/dev-portal-and-api
      icon_url: /assets/icons/dev-portal.svg
    - title: Register a Dev Portal developer account
      content: |
        Register a test developer account with your Dev Portal by navigating to your Dev Portal and clicking **Sign up**:
        ```sh
        open https://$PORTAL_URL/
        ```

        For the purpose of this tutorial, we've set our Dev Portal to automatically approve developer registrations.
      icon_url: /assets/icons/dev-portal.svg
    - title: Azure AD
      content: |
        You'll need an [Azure AD account](https://portal.azure.com) for this tutorial.

        {:.info}
        > **Note:** Dynamic client registration supports Azure OAuth v1 token endpoints only.
        > v2 is not supported.
      icon_url: /assets/icons/azure.svg
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

## Configure Azure

In Azure, create the main application:

1. In Azure Active Directory, click [**App registrations**](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade) and then click **New registration**.

2. Enter a name for the application.
3. Ensure **Accounts in this organizational directory only** is selected for **Supported account types**.

4. Click **Register**.

5. On the application view, go to **API permissions**, click **Add permissions > Microsoft Graph** and select the following:
   * **Application.ReadWrite.OwnedBy**
   * **User.Read**

6. Once added, click **Grant admin consent**. An administrator with Global Admin rights is required for this step.

7. Select **Certificates & secrets** and then create a client secret and save it in a secure location. You can only view the secret once.

8. In the **Overview** view, copy your Directory (tenant) ID and Application (client) ID, then export them:

   ```sh
   export TENANT_ID='YOUR-AZURE-TENANT-ID'
   export CLIENT_ID='YOUR-AZURE-CLIENT-ID'
   export CLIENT_SECRET='YOUR-AZURE-CLIENT-SECRET'
   export ISSUER_URL="https://sts.windows.net/$TENANT_ID"
   ```

## Configure the Dev Portal

After configuring Azure, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Azure DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

1. [Create a DCR provider](/api/konnect/application-auth-strategies/v2/#/operations/create-dcr-provider) using the `/v2/dcr-providers` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/dcr-providers
status_code: 201
method: POST
body:
  name: "Azure DCR Provider"
  provider_type: azureAd
  issuer: "$ISSUER_URL"
  dcr_config:
    initial_client_id: "$CLIENT_ID"
    initial_client_secret: "$CLIENT_SECRET"
{% endkonnect_api_request %}
<!--vale on-->

1. Export the DCR provider ID from the response:

   ```sh
   export DCR_PROVIDER_ID='YOUR-DCR-PROVIDER-ID'
   ```

1. [Create an authentication strategy](/api/konnect/application-auth-strategies/v2/#/operations/create-app-auth-strategy) using the `/v2/application-auth-strategies` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
status_code: 201
method: POST
body:
  name: "Azure DCR Auth Strategy"
  display_name: "Azure DCR Auth Strategy"
  strategy_type: openid_connect
  configs:
    openid-connect:
      issuer: "$ISSUER_URL"
      credential_claim:
        - appid
      auth_methods:
        - client_credentials
        - bearer
        - session
  dcr_provider_id: "$DCR_PROVIDER_ID"
{% endkonnect_api_request %}
<!--vale on-->

1. Export the auth strategy ID from the response:

   ```sh
   export AUTH_STRATEGY_ID='YOUR-AUTH-STRATEGY-ID'
   ```

## Apply the Azure DCR auth strategy to an API

Now that the application auth strategy is configured, you can [apply it to an API](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal) using the `/v3/apis/{apiId}/publications/{portalId}` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
body:
  visibility: public
  auth_strategy_ids:
    - $AUTH_STRATEGY_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate

{% include konnect/dcr-validate.md %}

You can also request a bearer token from Azure using the following command, targeting the OAuth 2.0 v1 token endpoint:

```sh
curl --request GET \
  --url https://login.microsoftonline.com/TENANT_ID/oauth2/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=client_credentials \
  --data client_id=CLIENT_ID \
  --data 'scope=https://graph.microsoft.com/.default' \
  --data 'client_secret=CLIENT_SECRET'
```