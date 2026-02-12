---
title: Automatically create and manage Dev Portal applications in Auth0 with Dynamic Client Registration
permalink: /how-to/auth0-dcr/
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Auth0.
content_type: how_to

products:
    - gateway
    - dev-portal
automated_tests: false
works_on:
    - konnect

entities: []

tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - auth0
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: How do I automatically create and manage Dev Portal applications in Auth0?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in Auth0. First, authorize an Auth0 application so {{site.konnect_short_name}} can use the Auth0 Management API on your behalf. Next, create an API audience that {{site.konnect_short_name}} applications will be granted access to. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR.

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
    - title: Auth0
      content: |
        You'll need an [Auth0 account](https://auth0.com/) to complete this tutorial.
      icon_url: /assets/icons/third-party/auth0.svg

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
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
---

## Configure access to the Auth0 Management API

To use dynamic client registration (DCR) with Auth0 as the identity provider (IdP), there are two important configurations to prepare in Auth0. First, you must authorize an Auth0 application so {{site.konnect_short_name}} can use the Auth0 Management API on your behalf. Next, you will create an API audience that {{site.konnect_short_name}} applications will be granted access to.

{{site.konnect_short_name}} will use a client ID and secret from an Auth0 application that has been authorized to perform specific actions in the Auth0 Management API.

To get started configuring Auth0, log in to your Auth0 dashboard and complete the following:

1. From the sidebar, select **Applications > Applications**.

2. Click **Create Application**.

3. Give the application a memorable name, like "{{site.konnect_short_name}} Portal DCR Admin".

4. Select the application type **Machine to Machine Applications** and click **create**.

5. Authorize the application to access the Auth0 Management API by selecting it from the dropdown. Its URL will follow the pattern: `https://AUTH0_TENANT_SUBDOMAIN.REGION.auth0.com/api/v2/`.

6. In the **Permissions** section, select the following permissions to grant access, then click **Authorize**:
   * `read:client_grants`
   * `create:client_grants`
   * `delete:client_grants`
   * `update:client_grants`
   * `read:clients`
   * `create:clients`
   * `delete:clients`
   * `update:clients`
   * `update:client_keys`
  
   {:.info}
   > **Note:** If you’re using Developer Managed Scopes, add `read:resource_servers` to the permissions for your initial client application.

7. On the application's **Settings** tab, locate the values for **Client ID** and **Client Secret**, you'll need them in a later step.

## Configure the API audience

You can use an existing API entity if there is one already defined in Auth0 that represents the audience you are/will be serving with {{site.konnect_short_name}}  Dev Portal applications.
In most cases, it is a good idea to create a new API that is specific to your Konnect Portal applications.

To create a new API audience in Auth0:

1. In the sidebar, navigate to **Applications > APIs**.

2. Click **Create API**.

3. Enter a **Name**, such as `{{site.konnect_short_name}} Portal Applications`.

4. Set the **Identifier** to a value that represents the audience your API will serve.

5. Click **Create**.

6. Make a note of the **Identifier** value (also known as the **Audience**), you'll need it when configuring the authentication strategy in `{{site.konnect_short_name}}`.

## Configure the Dev Portal

After configuring Auth0, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Auth0 DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

This tutorial uses the {{site.konnect_short_name}} UI to configure DCR, but you can also use the [Application Registration API](/api/konnect/application-auth-strategies/v2/#/operations/).

1. Log in to {{site.konnect_short_name}} and select [Dev Portal](https://cloud.konghq.com/portals/) from the menu.

2. Navigate to [**Application Auth**](https://cloud.konghq.com/portals/application-auth) to see the authentication strategies for your API Products.

3. Click the **DCR Providers** tab to see all existing DCR providers.

4. Click [**New DCR Provider**](https://cloud.konghq.com/portals/application-auth/dcr-provider/create) to create a new Auth0 configuration:
   1. Enter a name for internal reference within {{site.konnect_short_name}}. This name and the provider type won't be visible to developers on the Dev Portal.
   1. Enter the **Issuer URL** of your Auth0 tenant, formatted as: `https://AUTH0_TENANT_SUBDOMAIN.us.auth0.com`. *Do not* include a trailing slash at the end of the URL.
      
      {:.info}
      > **Note:** You can find the value for your `AUTH0_TENANT_SUBDOMAIN` by checking the **Tenant Name** under **Settings** > **General**.
   1. Select Auth0 as the **Provider Type**. 
   1. Enter the **Client ID** of the previously created admin application in Auth0 into the **Client ID** field. Then, enter the **Client Secret** of the same application into the **Initial Client Secret** field.
   1. If you're using a custom domain for Auth0, enter the audience of the initial client as the **Client Audience**. Otherwise, leave this field blank.
   1. Optional: If you're using developer-managed scopes, select the **Use Developer Managed Scopes** checkbox.
   1. Save your DCR provider. You should now see it in the list of DCR providers.

7. Navigate to the **Auth Strategy** tab, then click [**New Auth Strategy**](https://cloud.konghq.com/portals/application-auth/auth-strategy/create) to create an auth strategy that uses the DCR provider:

   1. Provide a name for internal use within {{site.konnect_short_name}} and a display name for visibility on your Portal.
   1. In the **Auth Type** dropdown menu select DCR. 
   1. In the **DCR Provider** dropdown, select the name of the DCR provider config you just created. Your **Issuer URL** will be prepopulated with the Issuer URL you added to the DCR provider.
   1. Enter the required `openid` scope in the **Scopes** field, along with any other scopes your developers may need (e.g., `openid, read:account_information, write:account_information`). If you are using developer-managed scopes, these will be the scopes your developers can select from in the Dev Portal.
   1. Enter `azp` in the **Credential Claims** field. This will match the client ID of each Auth0 application.
   1. Enter the **Audience** value from your associated Auth0 API in the **Audience** field. If you're using developer-managed scopes, the scopes selected by the developer should belong to this audience.
   1. Select the relevant **Auth Methods** you need (`client_credentials`, `bearer`, `session`), and click **Save**.

## Apply the Auth0 DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. Navigate to your Dev Portal in {{site.konnect_short_name}} and click **Published APIs** in the sidebar.

1. Click **Publish API**, select the API you want to publish, and select your Auth0 auth strategy for the **Authentication strategy**.

1. Click **Publish API**.

## Validate

{% include konnect/dcr-validate.md %}

{:.info}
> **Note:** When using Auth0 DCR for Dev Portal, each application in Auth0 will have the following metadata. This can be viewed via the auth0 dashboard, or accessed from the Auth0 API.
>
> * `konnect_portal_id`: ID of the Portal the application belongs to
> * `konnect_developer_id`: ID of the developer in the Dev Portal that this application belongs to
> * `konnect_org_id`: ID of the Konnect Organization the application belongs to
> * `konnect_application_id`: ID of the application in the Dev Portal

<!-- commenting this out until we figure out the new/correct workflow
## Using Auth0 actions

[Auth0 actions](https://auth0.com/docs/customize/actions) allow you to customize your application in Auth0. With Auth0 actions, you can configure a custom application name in Auth0, rather than using the default name set by the developer in the Dev Portal. For example, you can set the application name to be a combination of `konnect_portal_id`, `konnect_developer_id`, and `konnect_application_id`. For certain other actions, changes can be made directly via the API object passed to `onExecuteCredentialsExchange`.

1. Follow the [Auth0 documentation](https://auth0.com/docs/customize/actions/write-your-first-action#create-an-action) to create a custom action on the "Machine to Machine" flow.

2. Use the following code as an example for what your action could look like. Update the initial `const` variables with the values from the when you configured DCR.

   ```js

   const axios = require("axios");

   const INITIAL_CLIENT_AUDIENCE = 
   const INITIAL_CLIENT_ISSUER = 
   const INITIAL_CLIENT_ID = 
   const INITIAL_CLIENT_SECRET = 

   exports.onExecuteCredentialsExchange = async (event, api) => {
      const metadata = event.client.metadata
      if (!metadata.konnect_portal_id) {
         return
      }
      const newClientName = `${metadata.konnect_portal_id}+${metadata.konnect_developer_id}+${metadata.konnect_application_id}`
      await updateApplication(event.client.client_id, {
         name: newClientName
      })
   };

   async function getShortLivedToken() {
      const tokenEndpoint = new URL('/oauth/token', INITIAL_CLIENT_ISSUER).href
      const headers = {
         'Content-Type': 'application/json',
      }

      const payload = {
         client_id: INITIAL_CLIENT_ID,
         client_secret: INITIAL_CLIENT_SECRET,
         audience: INITIAL_CLIENT_AUDIENCE,
         grant_type: 'client_credentials'
      }

      const result = await
      axios.post(`${tokenEndpoint}`, payload, {
         headers
      })
      .then(x => x.data)
      .catch(e => {
         const msg = 'Unable to create one time access token'
         throw new Error(msg)
      })

      if (!result.access_token) {
         const msg = 'Unable to find one time access token from result'
         throw new Error(msg)
      }

      return result.access_token
   }

   async function updateApplication(clientId, update) {
      const shortLivedToken = await getShortLivedToken()
      const getApplicationEndpoint = new URL(`/api/v2/clients/${clientId}`, INITIAL_CLIENT_ISSUER).href
      const headers = makeHeaders(shortLivedToken)


      return await axios.patch(getApplicationEndpoint,
         update,
         { headers })
         .catch(e => {
            const msg = `Unable to update Application from auth0 ${e}`
            throw new Error(msg)
         })
   }

   function makeHeaders(token) {
      return {
         Authorization: `Bearer ${token}`,
         accept: 'application/json',
         'Content-Type': 'application/json'
      }
   }
   ```

3. Make sure to apply this action to the "Machine to Machine" flow. It will run each time a `client_credentials` request is made. After a request is made, you can view the updated application name in the Auth0 dashboard.
-->