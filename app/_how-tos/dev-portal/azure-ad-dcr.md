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

prereqs:
  skip_product: true
  inline:
    - title: "{{site.konnect_product_name}}"
      include_content: prereqs/products/konnect-account-only
      icon_url: /assets/icons/gateway.svg
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-dcr-roles
      icon_url: /assets/icons/gateway.svg
    - title: Dev Portal
      include_content: prereqs/dev-portal-app-reg
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

8. In the **Overview** view, make a note of your Directory (tenant) ID and Application (client) ID.

## Configure the Dev Portal

After configuring Azure, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Auth0 DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

This tutorial uses the {{site.konnect_short_name}} UI to configure DCR, but you can also use the [Application Registration API](/api/konnect/application-auth-strategies/v2/#/operations/).

1. Log in to {{site.konnect_short_name}} and select [Dev Portal](https://cloud.konghq.com/portals/) from the menu.

2. Navigate to [**Application Auth**](https://cloud.konghq.com/portals/application-auth) to see the authentication strategies for your API Products.

3. Click the **DCR Providers** tab to see all existing DCR providers.

4. Click [**New DCR Provider**](https://cloud.konghq.com/portals/application-auth/dcr-provider/create) to create a new Azure configuration:
   1. Enter a name for internal reference within {{site.konnect_short_name}}. This name and the provider type won't be visible to developers on the Dev Portal.
   1. Enter the **Issuer URL** of your Azure tenant, formatted as: `https://sts.windows.net/YOUR_TENANT_ID`. *Do not* include a trailing slash at the end of the URL.
   1. Select Azure as the **Provider Type**. 
   1. Enter your Application (Client) ID from Azure into the **Initial Client ID** field, and the client secret of the Azure admin application into the **Initial Client Secret** field.
      
      {:.info}  
      > **Note:** The Initial Client Secret will be stored in isolated, encrypted storage and will not be accessible through any Konnect API.
   1. Save your DCR provider. You should now see it in the list of DCR providers.

7. Navigate to the **Auth Strategy** tab, then click [**New Auth Strategy**](https://cloud.konghq.com/portals/application-auth/auth-strategy/create) to create an auth strategy that uses the DCR provider:

   1. Provide a name for internal use within {{site.konnect_short_name}} and a display name for visibility on your Portal.
   1. In the **Auth Type** dropdown menu select DCR. 
   1. In the **DCR Provider** dropdown, select the name of the DCR provider config you just created. Your **Issuer URL** will be prepopulated with the Issuer URL you added to the DCR provider.
   1. In the **Credential Claims** field, enter `appid`.
   1. Select the relevant **Auth Methods** you need (`client_credentials`, `bearer`, `session`), and click **Save**.

## Apply the Azure DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. Navigate to your Dev Portal in {{site.konnect_short_name}} and click **Published APIs** in the sidebar.

1. Click **Publish API**, select the API you want to publish, and select your Azure auth strategy for the **Authentication strategy**.

1. Click **Publish API**.

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