---
title: Authentication strategies
description: 'Learn how to set up authentication strategies for Dev Portal.'
content_type: reference
layout: reference
products:
  - dev-portal
tags:
  - authentication
  - beta
beta: true
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
  - text: Application registration
    url: /dev-portal/application-registration/
---

Dev Portal authentication strategies determine which developers can access which APIs. You can define and reuse multiple authentication strategies for different APIs and Dev Portals. For example:

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

1. Navigate to the **Application Auth** tab in the Dev Portal.
1. Click **New Auth Strategy**.
1. Enter a name (for internal use) and a display name (visible to developers).
1. Select **Key auth** as the auth type.
1. Click **Save**.

## Configure OIDC

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
