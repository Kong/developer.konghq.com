---
title: Configure SAML SSO for Konnect with Microsoft Entra ID
permalink: /konnect-platform/entra-saml-sso/
content_type: how_to
description: Learn how to configure SAML 2.0 SSO for Kong Konnect using Microsoft Entra ID as the identity provider.
products:
  - konnect
works_on:
  - konnect
tags:
  - saml
  - sso
  - authentication
  - azure
automated_tests: false
tldr:
  q: How do I configure SAML SSO for Konnect with Microsoft Entra ID?
  a: |
    Get your {{site.konnect_short_name}} organization ID from the `/organizations/me` endpoint, then create a non-gallery enterprise application in Microsoft Entra ID, configure the SAML settings with that organization ID and your chosen login path, and map the required user attributes and claims. Then create a SAML identity provider using the `/identity-providers` endpoint with the App Federation Metadata URL from Entra ID, and enable SAML using the `/authentication-settings` endpoint.
related_resources:
  - text: "{{site.konnect_short_name}} authentication"
    url: /konnect-platform/authentication/
prereqs:
  skip_product: true
  inline:
    - title: Microsoft Entra ID
      content: |
        You need a Microsoft Entra account with the Cloud Application Administrator or Application Administrator role.

        You also need an Entra ID group containing the users you want to map to a {{site.konnect_short_name}} team. If you don't have one yet, [create a group](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-manage-groups) before continuing. 
        Export the name of the Entra ID group you want to map to the team in {{site.konnect_short_name}}:
        ```sh
        export ENTRA_GROUP_NAME='YOUR-ENTRA-GROUP-NAME'
        ```

        Create an enterprise application in Microsoft Entra ID:

        1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com) using your admin account.
        1. In the sidebar, navigate to **Entra ID** > **Enterprise apps**.
        1. Click **New application**.
        1. Click **Create your own application**.
        1. Enter a name for the application (for example, `Kong Konnect SSO`).
        1. Select **Integrate any other application you don't find in the gallery (Non-gallery)**.
        1. Click **Create**.

      icon_url: /assets/icons/azure.svg
---

{{site.konnect_short_name}} supports external single sign-on SAML authentication using an Microsoft Entra. 
This allows [Org admins](/konnect-platform/teams-and-roles/) to log in with SSO and is an alternative to {{site.konnect_short_name}}'s [built-in authentication](https://cloud.konghq.com/global/organization/settings#authentication-scheme).

The following diagram shows the [SAML](/konnect-platform/sso/) authentication flow between a user, {{site.konnect_short_name}}, and Microsoft Entra ID:

{% mermaid %}
sequenceDiagram
    participant User
    participant Konnect as {{site.konnect_short_name}}
    participant Entra as Entra ID (IdP)

    User->>Konnect: Access login URL (https://cloud.konghq.com/login/&lt;custom_path&gt;)
    Konnect->>User: Redirect to IdP SSO URL (https://login.microsoftonline.com/&lt;tenant_id&gt;/saml2)
    User->>Entra: Send SAML request (SP entity ID: https://cloud.konghq.com/sp/&lt;organization_id&gt;)
    Entra->>User: Return SAML response with claims (email, name ID, groups)
    User->>Konnect: Post SAML response to ACS URL (https://global.api.konghq.com/v2/authenticate/&lt;custom_path&gt;/saml/acs)
    Konnect->>Konnect: Validate SAML response (verify signature, claims)
    Konnect->>User: Grant access to {{site.konnect_short_name}}
{% endmermaid %}

## Get your organization ID

Before configuring Basic SAML in Entra ID, get and save your {{site.konnect_short_name}} organization ID. 
You'll need this to build the SAML values Entra ID expects. Send a `GET` request to the [`/organizations/me` endpoint](/api/konnect/identity/#/operations/get-organizations-me):

<!--vale off-->
{% konnect_api_request %}
url: /v3/organizations/me
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

Also decide on the login path you want to use for your {{site.konnect_short_name}} organization, and export it as an environment variable. 
This will be appended to the {{site.konnect_short_name}} login, for example: `https://cloud.konghq.com/login/$LOGIN_PATH`
You'll use this same value in both Entra ID and {{site.konnect_short_name}}:

```sh
export LOGIN_PATH='my-org'
```

## Configure Basic SAML in Microsoft Entra

1. In the application, click **Single sign-on** in the sidebar.
1. Select **SAML** as the single sign-on method.
1. In the **Basic SAML Configuration** section, click **Edit**.
1. In the **Identifier (Entity ID)** field, enter `https://cloud.konghq.com/sp/$KONNECT_ORG_ID`.
1. In the **Reply URL (Assertion Consumer Service URL)** field, enter `https://global.api.konghq.com/v2/authenticate/$LOGIN_PATH/saml/acs`.
1. In the **Sign on URL** field, enter `https://cloud.konghq.com/login/$LOGIN_PATH`.
1. Click **Save**.
1. In the sidebar, click **Users and groups**, then click **Add user/group** and assign the Entra ID group you want to map to a {{site.konnect_short_name}} team.
1. In the **Attributes & Claims** section, click **Edit**.
1. Configure the following claims. For each claim, clear the namespace URI before saving:
   1. Set **Unique user identifier** to `user.userprincipalname`.
   1. Click **Add a group claim**, select **Groups assigned to the application**, and set the **Source attribute** to **Cloud-only group display names** so the SAML assertion sends the group's name rather than its object ID. Then click **Advanced options**, select **Customize the name of the group claim**, and enter `user.groups` in the **Name** field.
   1. Click **Add new claim** and add a claim named `firstname` with source attribute `user.givenname`. Click **Save**.
   1. Click **Add new claim** and add a claim named `lastname` with source attribute `user.surname`. Click **Save**.
   1. Click **Add new claim** and add a claim named `email` with source attribute `user.mail`. Click **Save**.
1. Navigate back to your SAML settings and copy the **App Federation Metadata URL** from the **SAML Certificates** section, and export it as an environment variable. You'll need this in the next section:
   ```sh
   export APP_FEDERATION_METADATA_URL='YOUR-APP-FEDERATION-METADATA-URL'
   ```

{:.warning}
> **Important:** Use the App Federation Metadata URL, not the tenant-level metadata URL. Using the tenant-level URL causes an invalid SAML response error due to a certificate mismatch.

## Configure SAML in {{site.konnect_short_name}}

Create the SAML identity provider using the App Federation Metadata URL from Microsoft Entra ID and the login path you chose earlier, by sending a `POST` request to the [`/identity-providers` endpoint](/api/konnect/identity/#/operations/create-identity-provider). {{site.konnect_short_name}} uses the login path to generate your organization's custom login URL: `https://cloud.konghq.com/login/$LOGIN_PATH`. 

Capture the identity provider's ID as `$IDP_ID`:

<!--vale off-->
{% konnect_api_request %}
url: /v3/identity-providers
method: POST
status_code: 201
region: global
body:
  type: saml
  login_path: $LOGIN_PATH
  config:
    idp_metadata_url: $APP_FEDERATION_METADATA_URL
capture:
  - variable: IDP_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

## Configure teams in {{site.konnect_short_name}}

Before you can map teams from Entra, you must create them or modify the existing teams in {{site.konnect_short_name}}

1. Create the {{site.konnect_short_name}} team you want to map to an Entra ID group, and capture its ID as `$TEAM_ID`, by sending a `POST` request to the [`/teams` endpoint](/api/konnect/identity/#/operations/create-team). If you already have a team to map, send a `GET` request to the [`/teams` endpoint](/api/konnect/identity/#/operations/list-teams) instead, filtered on its name, to look up its ID:
{% capture create-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/teams
method: POST
status_code: 201
region: global
body:
  name: IDM - Developers
  description: The Identity Management (IDM) team.
capture:
  - variable: TEAM_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-team | indent: 3}}
1. Map the Entra ID group to the team by sending a `POST` request to the [`/identity-providers/{idpId}/team-group-mappings` endpoint](/api/konnect/identity/#/operations/create-idp-team-group-mapping):
{% capture create-team-mapping %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/identity-providers/$IDP_ID/team-group-mappings
method: POST
status_code: 201
region: global
body:
  team_id: $TEAM_ID
  group: $ENTRA_GROUP_NAME
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-team-mapping | indent: 3}}
   The `$ENTRA_GROUP_NAME` is the name of the group in Entra that you exported in the [prerequisites](/konnect-platform/entra-saml-sso/#microsoft-entra-id). 
   Repeat this request for each additional team you want to map.

## Enable SAML and team mappings in {{site.konnect_short_name}}

1. Enable SAML as an authentication method for your organization by sending a `PATCH` request to the [`/authentication-settings` endpoint](/api/konnect/identity/#/operations/update-authentication-settings):
{% capture enable-saml %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/authentication-settings
method: PATCH
status_code: 200
region: global
body:
  saml_auth_enabled: true
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ enable-saml | indent: 3}}
1. [Team mappings](/konnect-platform/sso/#team-mapping-configuration) let you automatically assign {{site.konnect_short_name}} teams based on Entra ID group membership. Enable IdP mapping by sending a `PATCH` request to the [`/authentication-settings` endpoint](/api/konnect/identity/#/operations/update-authentication-settings):
{% capture enable-idp-mapping %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/authentication-settings
method: PATCH
status_code: 200
region: global
body:
  idp_mapping_enabled: true
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ enable-idp-mapping | indent: 3}}

## Validate

1. Navigate to your custom login URL: `https://cloud.konghq.com/login/$LOGIN_PATH`. You will be redirected to the Microsoft Entra ID sign-in page.
1. Log in with your Entra ID credentials. If the configuration is correct, you are authenticated into {{site.konnect_short_name}}.
