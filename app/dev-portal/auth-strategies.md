---
title: Application authentication strategies
description: 'Learn how to set up authentication strategies for application registration in Dev Portal.'
content_type: reference
layout: reference
products:
  - gateway
  - dev-portal
tags:
  - authentication
  - application-registration
works_on:
  - konnect

breadcrumbs:
  - /dev-portal/

api_specs:
  - konnect/portal-management

search_aliases:
  - OpenID Connect
  - Key Authentication
  - Portal

related_resources:
  - text: SSO reference
    url: /dev-portal/sso/
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: About Dev Portal Dynamic Client Registration
    url: /dev-portal/dynamic-client-registration/
  - text: About OIDC Dynamic Client Registration
    url: https://openid.net/specs/openid-connect-registration-1_0.html
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
  - text: Enable self-managed OIDC auth with Okta
    url: /how-to/enable-oidc-auth-for-dev-portal/
  - text: Enable key authentication for Dev Portal apps
    url: /how-to/enable-key-auth-for-dev-portal/
---

Dev Portal application authentication strategies determine which developers can access which APIs. 
You can define and reuse multiple authentication strategies for different APIs and Dev Portals. For example:

* `key-auth`: Built-in default
* `okta-oidc`: OpenID Connect with Okta
* `okta-dcr`: Dynamic Client Registration with Okta
* `auth0-oidc`: OpenID Connect with Auth0

Using these, a flexible setup might look like:

* **Staging Portal**
  * Weather API v1 → `key-auth`
  * Weather API v2, Maps API v2 → `okta-oidc`
* **Production Portal**
  * Weather API v2 → `okta-dcr`
  * Maps API v2 → `auth0-oidc`

{% mermaid %}
flowchart TB
    subgraph Production Portal
    WeatherAPIv2p["Weather API v2"] --> okta-dcr
    MapsAPIv2-2["Maps API v2"] --> auth0-oidc
    end
    subgraph Staging Portal
    WeatherAPIv2s["Weather API v2"] --> okta-oidc
    MapsAPIv2-1["Maps API v2"] --> okta-oidc
    WeatherAPIv1["Weather API v1"] --> key-auth
    end
{% endmermaid %}

Authentication strategies are reusable and can be applied across multiple APIs and Dev Portals.

Developers can only use **one auth strategy per application**. 
For example, to register for both Weather v2 and Maps v2 (both use `okta-oidc`), one application is sufficient. 
To register for Weather v1 and Weather v2, two applications are required.

## Configure the key auth strategy

Key authentication is {{site.konnect_short_name}}'s built-in API authentication strategy. 
When developers create an application through your Dev Portal, they are automatically issued credentials.

By default, a **Key Auth** strategy is created for every Dev Portal. 
If your portal is marked as **Private**, this strategy is also set as the default in your security settings.

To create an additional key auth strategy:

1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal**.
1. In the Dev Portal sidebar, click **Application Auth**.
1. Click **New authentication strategy**.
1. In the **Name** field, enter a name for internal use.
1. In the **Display name** field, enter a name for external use that is visible to developers.
1. From the **Authentication Type**, select "Key-Auth".
1. (Optional) To configure an expiration time for the key, do the following:
   1. Click **Advanced configuration**.
   1. In the **Key Names** field, enter a name for your key that will display in the API request header.
   1. Enable **Key expiration policy**.
   1. In the **Key expires after** dropdown menu, select the number of days, weeks, or years after which the key will expire.
1. Click **Save**.

Once you've configured the key auth strategy, you must apply it to your [Dev Portal](#set-the-default-auth-strategy-of-a-dev-portal), [API packages](#apply-an-auth-strategy-to-an-api-package), and [APIs](#apply-an-auth-strategy-to-an-api). For a complete tutorial, see [Enable key authentication for Dev Portal apps](/how-to/enable-key-auth-for-dev-portal/).

{% include /konnect/key-expiration-note.md %}

## Dev Portal OIDC authentication

OpenID Connect (OIDC) is an open authentication protocol that lets users sign in to multiple sites using one set of credentials. Using the OIDC authentication strategy allows developers visiting your Dev Portal to authenticate using OIDC.

There are two ways to use OIDC with the Dev Portal:
- [Linking static clients (Self-managed OIDC)](#link-static-clients-with-self-managed-oidc): Developers bring their own pre-registered application from the IdP and manually link the client ID to their Portal application.
- [Dynamic Client Registration (DCR)](/dev-portal/dynamic-client-registration/): The Dev Portal automatically creates and manages applications in the IdP as developers need them.

The following table compares the two Dev Portal OIDC methods:
<!--vale off-->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: Self-managed OIDC (Static)
    key: static-oidc
  - title: DCR OIDC (Dynamic)
    key: dynamic-oidc
rows:
  - feature: "App creation in IdP"
    static-oidc: "Manual by developer"
    dynamic-oidc: "Automated by Dev Portal"
  - feature: "Client ID management"
    static-oidc: "Manual"
    dynamic-oidc: "Automated"
  - feature: "Use case"
    static-oidc: "Full developer control"
    dynamic-oidc: "Streamlined onboarding"
  - feature: "IdP support required"
    static-oidc: "Any OIDC IdP"
    dynamic-oidc: "IdP must support DCR"
{% endtable %}
<!--vale on-->


### Configure OIDC in Dev Portal

For a step-by-step guide about how to configure OIDC with Okta, see [Enable self-managed OIDC auth with Okta in Dev Portal](/how-to/enable-oidc-auth-for-dev-portal/).

If you don't have an OIDC auth strategy set up, follow these steps to create one:

1. Create a new strategy under **Application Auth** and select **OpenID-Connect** as the auth type.
1. Provide a name for internal use and a display name for developers.
1. Enter the Issuer URL for your OIDC provider.
1. Define the scopes required by your developers (for example, `openid`, `profile`, `email`).
1. Set the Credential Claims to match the client ID from your identity provider.
1. Select the authentication methods you need, such as `client_credentials`, `bearer`, or `session`.
1. Save the strategy.

Optionally, update the **Default Auth Strategy** in **Settings > Security** to use your new OIDC strategy for easier publishing.

### OpenID Connect configuration parameters {#openid-config-parameters}

For more background information about OpenID Connect plugin parameters, see the [OpenID Connect plugin configuration reference](/plugins/openid-connect/reference/).

{% table %}
columns:
  - title: Form Parameter
    key: param
  - title: Description
    key: description
  - title: Required
    key: required
rows:
  - param: "`Issuer`"
    description: |
      The issuer URL from which the OpenID Connect configuration can be discovered. 
      <br><br>
      For example: `https://dev-1234567.okta.com/oauth2/default`.
    required: "**True**"
  - param: "`Scopes`"
    description: |
      The scopes to be requested from the OpenID Provider. 
      <br><br>
      Enter one or more scopes separated by spaces, for example: `open_id` `myscope1`.
    required: "**False**"
  - param: "`Credential claims`"
    description: Name of the claim that maps to the unique client id in the identity provider.
    required: "**True**"
  - param: "`Auth method`"
    description: |
      The supported authentication method(s) you want to enable. This field should contain only the authentication methods that you need to use. Individual entries must be separated by commas. 
      <br><br>
      Available options: `password`, `client_credentials`, `authorization_code`, `bearer`, `introspection`, `kong_oauth2`, `refresh_token`, `session`.
    required: "**True**"
  - param: "`Hide Credentials`"
    description:  |
      Hide the credential from the upstream service. If enabled, the plugin strips the credential from the request header, query string, or request body, before proxying it.
      <br><br>
      *Default: disabled*
    required: "**False**"
  - param: "`Auto Approve`"
    description: |
      Automatically approve developer application requests for an application.
      <br><br>
      *Default: disabled*
    required: "**False**"
{% endtable %}

### Link static clients with self-managed OIDC 

With this model, developers bring their own pre-registered application from the IdP and manually link the client ID to their Portal application. You should use this model if:
- You want developers to have full control over their IdP applications.
- Your IdP doesn't support DCR, or you do not want to enable it.
- You require manual review or approval of all IdP applications.

Self-managed OIDC follows this workflow:

1. Developer registers an application directly in the IdP (such as Okta, Auth0, Azure, etc.).
2. Developer copies the client ID (and secret, if needed).
3. Developer creates or links an application in the Dev Portal, providing the client ID.
4. The Dev Portal uses the provided client ID for OIDC authentication.

{:.info}
> **Note:** The Dev Portal doesn't create or manage IdP applications in this model. All application management is manual and handled by the developer or IdP admin.

## Set the default auth strategy of a Dev Portal

The default auth strategy of a Dev Portal will apply to any APIs that are published to that Dev Portal. You can adjust the strategy through Dev Portal security settings.

If you want to override the default auth strategy, you can configure a different auth strategy on a [per API](#apply-an-auth-strategy-to-an-api) or [per API package](#apply-an-auth-strategy-to-an-api-package) basis.

1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal**.
1. Click your Dev Portal.
1. From the **Actions** dropdown menu, select "Settings". 
1. Click the **Security** tab.
1. From the **Authentication strategy** dropdown menu, select the auth strategy you want to set as the default.
1. Click **Save changes**.

## Apply an auth strategy to an API

After configuring an auth strategy, you can apply it to APIs.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **APIs**.
1. Click the API you want to apply the auth strategy to.
1. Depending on the API's publication status, do one of the following:
   1. Unpublished: Click **Publish API**.
   1. Published: Click the more options menu and then click **Edit publication**.
1. From the **Authentication strategy** dropdown menu, select the auth strategy you want to apply to the API.
1. Click **Save**.

{:.info}
> To enforce auth strategies on an app, you must [link your API to a Gateway Service](/catalog/apis/#allow-developers-to-consume-your-api).

## Apply an auth strategy to an API package

After configuring an auth strategy, you can apply it to API packages.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **APIs**.
1. Click the **API packages** tab.
1. Click the API package you want to apply the auth strategy to.
1. Click the **Portals** tab.
1. Depending on the API's publication status, do one of the following:
   1. Unpublished: Click **Publish API**.
   1. Published: Click the more options menu and then click **Edit publication**.
1. From the **Authentication strategy** dropdown menu, select the auth strategy you want to apply to the API.
1. Click **Save**.

{:.info}
> To enforce auth strategies on an app, you must [link your API package to a Gateway Service](/how-to/package-apis-with-dev-portal/#associate-a-control-plane).
