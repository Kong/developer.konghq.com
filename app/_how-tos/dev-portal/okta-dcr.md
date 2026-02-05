---
title: Automatically create Dev Portal applications in Okta with Dynamic Client Registration
permalink: /how-to/okta-dcr/
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Okta.
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
    - okta
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: How do I automatically create and manage Dev Portal applications in Okta?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in Okta. First, create scopes and claims in Okta and copy your Issuer URL. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR.

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
    - title: Okta
      include_content: prereqs/okta-sso
      icon_url: /assets/icons/okta.svg
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

## Copy the Okta issuer URL

Using your Okta credentials, log in to the Okta portal and click **Security > API** in the sidebar. The default Issuer URI should be displayed in the **Authorization Servers** tab. If you are using an authorization server that you configured, copy the issuer URL for that authorization server.

## Create a token in Okta

1. Click **Security > API** in the sidebar.

3. From the **Tokens** tab, click the **Create token** button.

4. Enter a name for your token, and then copy the token value.
   {:.warning}
   > **Important:** Store the token in a secure location you can reference later, as it will only be visible as a hashed value after this step.

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

## Configure the Okta Dynamic Client Registration in Dev Portal

After configuring Okta, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Okta DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

This tutorial uses the {{site.konnect_short_name}} UI to configure DCR, but you can also use the [Application Registration API](/api/konnect/application-auth-strategies/v2/#/operations/).

1. Log in to {{site.konnect_short_name}} and select [Dev Portal](https://cloud.konghq.com/portals/) from the menu.

2. Navigate to [**Application Auth**](https://cloud.konghq.com/portals/application-auth) to see the authentication strategies for your API Products.

3. Click the **DCR Providers** tab to see all existing DCR providers.

4. Click [**New DCR Provider**](https://cloud.konghq.com/portals/application-auth/dcr-provider/create) to create a new Okta configuration:
   1. Enter a name for internal reference within {{site.konnect_short_name}}. This name and the provider type won't be visible to developers on the Dev Portal.
   1. Enter the **Issuer URL** of your authorization server and the **DCR Token** that you created in Okta. The Issuer URL and DCR token will be stored in isolated, encrypted storage and will not be readable through any Konnect API.
   1. Select Okta as the **Provider Type**. 
   1. Save your DCR provider. You should now see it in the list of DCR providers.

7. Navigate to the **Auth Strategy** tab, then click [**New Auth Strategy**](https://cloud.konghq.com/portals/application-auth/auth-strategy/create) to create an auth strategy that uses the DCR provider:

   1. Provide a name for internal use within {{site.konnect_short_name}} and a display name for visibility on your Portal.
   1. In the **Auth Type** dropdown menu select DCR. 
   1. In the **DCR Provider** dropdown, select the name of the DCR provider config you just created. Your **Issuer URL** will be prepopulated with the Issuer URL you added to the DCR provider.
   1. Enter the names of the **Scopes** and **Claims** as comma-separated values in their corresponding fields. The values should match the scopes or claims that were created in Okta.

      {:.info}
      > **Note:**  Avoid using the `openid` scope with client credentials as it restricts the use. If no scopes are specified, `openid` will be the default.

   1. Select the relevant **Auth Methods** you need (`client_credentials`, `bearer`, `session`), and click **Save**.

## Apply the Okta DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. Navigate to your Dev Portal in {{site.konnect_short_name}} and click **Published APIs** in the sidebar.

1. Click **Publish API**, select the API you want to publish, and select your Okta auth strategy for the **Authentication strategy**.

1. Click **Publish API**.

## Validate

{% include konnect/dcr-validate.md %}
