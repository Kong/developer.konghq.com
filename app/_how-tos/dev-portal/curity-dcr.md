---
title: Automatically create and manage Dev Portal applications in Curity with Dynamic Client Registration
permalink: /how-to/curity-dcr/
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Curity.
content_type: how_to

products:
    - gateway
    - dev-portal

works_on:
    - konnect
automated_tests: false
entities: []

tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - curity
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: How do I automatically create and manage Dev Portal applications in Curity?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in Curity. First, configure the token issuer, create a client, and enable DCR for the client in Curity. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR.

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
    - title: Curity
      include_content: prereqs/curity
      icon_url: /assets/icons/third-party/curity.png
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

## Create a token service profile in Curity

To use Dynamic Client Registration (DCR) with Curity as the identity provider (IdP), you need to prepare three key configurations in Curity: configuring the token issuer, creating a client, and enabling DCR for the client.

To begin configuring Curity, log in to your Curity dashboard and follow these steps:

1. Select the **Profiles** tab on the dashboard.

2. Select an existing **Token Profile** in the **Profiles** diagram, or create a new one if necessary.

Complete the following sections using the **Token Profile** you selected.

## Configure the token issuer

1. In Curity, select **Token Service > Token Issuers** from the menu.

2. Enable the **Use Access Token as JWT** setting.

3. Add a new token issuer by clicking **New Token Issuer**.

4. Fill in the following values for the token issuer, and click **create**:
    * Name: `userinfo`
    * Issuer Type: `jwt`
    * Purpose Type: `userinfo`

5. In the "Edit Custom Token Issuer" form, select the desired values for **Tokens Data Source ID**, **Signing Key**, and **Verification KeyStore**.

## Create a client

1. In Curity, select **Token Service > Clients** from the menu.

2. Click **New Client**.

3. Assign a unique and descriptive name to the client, and make a note of it for future reference.

4. In the overview diagram, click **Capabilities** to add a capability to the **client**.

5. Select **Client Credentials**, then click **Next**.

6. Set the **Authentication Method** to `secret`, generate a secret, copy it for later use, and click **Next**.

   {:.warning}
   > **Important:** Store the secret in a secure location, as it will not be visible after this step.

## Enable Dynamic Client Registration in Curity

1. In Curity, select **Token Service > General > Dynamic Registration** from the menu.

2. Click **Enable Dynamic Client Registration**.

3. Make sure both **Non-Templatized** and **Dynamic Client Management** are enabled, then click **Next**.

4. Choose the desired client data source, then click **Next**.

5. Select `authenticate-client-by` as the **Authentication Method**, enter the name of the client created earlier, and click **Next**.

6. Select the nodes you want to enable DCR on and click **next**.

## Configure the Dev Portal

After configuring Curity, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Curity DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

This tutorial uses the {{site.konnect_short_name}} UI to configure DCR, but you can also use the [Application Registration API](/api/konnect/application-auth-strategies/v2/#/operations/).

1. Log in to {{site.konnect_short_name}} and select [Dev Portal](https://cloud.konghq.com/portals/) from the menu.

2. Navigate to [**Application Auth**](https://cloud.konghq.com/portals/application-auth) to see the authentication strategies for your API Products.

3. Click the **DCR Providers** tab to see all existing DCR providers.

4. Click [**New DCR Provider**](https://cloud.konghq.com/portals/application-auth/dcr-provider/create) to create a new Curity configuration:
   1. Enter a name for internal reference within {{site.konnect_short_name}}. This name and the provider type won't be visible to developers on the Dev Portal.
   1. Enter the **Issuer URL** of your Curity authorization server, formatted as `https://CURITY_INSTANCE_DOMAIN/oauth/v2/oauth-anonymous/.well-known/openid-configuration`.
   1. Select Curity as the **Provider Type**. 
   1. Enter the **Client ID** of the admin client created in Curity above into the **Initial Client ID** field. Then, enter the saved **Client Secret** into the **Initial Client Secret** field.
      {:.info}
      > **Note:**The Initial Client Secret will be stored in isolated, encrypted storage and will not be accessible through any Konnect API.
   1. Save your DCR provider. You should now see it in the list of DCR providers.

7. Navigate to the **Auth Strategy** tab, then click [**New Auth Strategy**](https://cloud.konghq.com/portals/application-auth/auth-strategy/create) to create an auth strategy that uses the DCR provider:

   1. Provide a name for internal use within {{site.konnect_short_name}} and a display name for visibility on your Portal.
   1. In the **Auth Type** dropdown menu select DCR. 
   1. In the **DCR Provider** dropdown, select the name of the DCR provider config you just created. Your **Issuer URL** will be prepopulated with the Issuer URL you added to the DCR provider.
   1. If you are using the Curity configuration described in the previous sections, enter the `sub` into the **Claims** field and leave the **Scopes** field empty. If you configured Curity differently, then ensure you add the correct **Scopes** and **Claims**.

      {:.info}
      > **Note:**  Avoid using the `openid` scope with client credentials as it restricts the use. If no scopes are specified, `openid` will be the default.

   1. Select the relevant **Auth Methods** you need (`client_credentials`, `bearer`, `session`), and click **Save**.

## Apply the Curity DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. Navigate to your Dev Portal in {{site.konnect_short_name}} and click **Published APIs** in the sidebar.

1. Click **Publish API**, select the API you want to publish, and select your Curity auth strategy for the **Authentication strategy**.

1. Click **Publish API**.

## Validate

{% include konnect/dcr-validate.md %}