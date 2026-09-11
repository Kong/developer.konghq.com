---
title: "{{site.dev_portal}} team mapping"
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - authentication
breadcrumbs:
  - /dev-portal/
works_on:
    - konnect
search_aliases:
  - Portal

description: "Map existing developer teams from a third-party identity provider (IdP) and their permissions to elements in a {{site.konnect_short_name}} {{site.dev_portal}}."

related_resources:
  - text: About {{site.dev_portal}} customizations
    url: /dev-portal/customizations/dev-portal-customizations/
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: "Configure SSO for a {{site.konnect_short_name}} org"
    url: /konnect-platform/sso/
---

With teams mapped from an IdP, the developers and permissions are mapped automatically in {{site.konnect_short_name}} so you don't have to manually copy over each team of developers.

You can exclude specific teams from IdP synchronization to manage their membership manually in {{site.konnect_short_name}}, even while mapping is enabled for the rest of your teams.
This can be useful when you are migrating from one IdP to another or if {{site.dev_portal}} Admins don't have access to the IdP settings and they want to create some teams manually.

This guide explains how to map the permissions, including scopes and claims, from your group of developers in your IdP to your organization's team in {{site.konnect_short_name}}. Although this guide uses Okta, Azure Active Directory (AD), and Auth0 as examples, you can use any IdP that conforms to OIDC standards. 

## Prerequisites

* A test developer account in your IdP
* An application for {{site.konnect_short_name}} configured in your IdP:
    * [Okta](https://help.okta.com/en-us/content/topics/apps/apps_app_integration_wizard.htm)
    * [Azure AD](https://learn.microsoft.com/graph/toolkit/get-started/add-aad-app-registration)
    * [Auth0](https://auth0.com/docs/get-started/auth0-overview/create-applications)

## Set up developer teams and group claims in your IdP

{% navtabs "set-up" %}
{% navtab "Okta" %}
1. In Okta, [assign people to a group](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-assign-group-people.htm), including your test developer account. Alternatively, you can use [group rules](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-create-group-rules.htm) to automatically add people to a group.

1. Configure any other group settings and attributes as needed.

1. [Enable group push](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-enable-group-push.htm) for **{{site.base_gateway}}** to push existing Okta groups and their memberships to {{site.konnect_short_name}}.

1. [Add a groups claim for the org authorization server](https://developer.okta.com/docs/guides/customize-tokens-groups-claim/main/#add-a-groups-claim-for-the-org-authorization-server).
{% endnavtab %}
{% navtab "Azure AD" %}
1. In [Azure AD](https://portal.azure.com/), [create a new group](https://learn.microsoft.com/azure/active-directory/fundamentals/how-to-manage-groups#create-a-basic-group-and-add-members) that includes your test developer account.

1. [Configure a groups claim](https://learn.microsoft.com/azure/active-directory/develop/optional-claims#configure-groups-optional-claims).

{% endnavtab %}
{% navtab "Auth0" %}
1. In Auth0, create a [new team of developers](https://auth0.com/docs/get-started/tenant-settings/auth0-teams) that you want to map to Konnect. Make sure to add your test developer account. 

1. [Configure a groups claim](https://auth0.com/docs/secure/tokens/json-web-tokens/create-custom-claims).
{% endnavtab %}
{% endnavtabs %}

## Map IdP developer teams in {{site.konnect_short_name}}

You can configure more than one IdP for a {{site.dev_portal}}, but only one IdP can be enabled at a time.

{% navtabs "map-idp-teams" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **{{site.dev_portal}}** > **Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Settings** tab.
1. Click the **Security** tab.
1. Enable **Role-based access control (RBAC)**.
   
   Enabling RBAC allows you to create teams in {{site.konnect_short_name}}. You can disable RBAC after you map teams from your IdP if you don't want to use it.

1. Click the **Developers** tab.
1. Click the **Teams** tab.
1. Click **New Team** and configure the team.
2. From the IdP team you just created, click the **APIs** tab and click **Add Roles**. This allows you to assign APIs and the role for the APIs to members of your IdP team.
1. Navigate back to your {{site.dev_portal}} overview and click the **Settings** tab.
1. Click the **Security** tab.
1. In the User authentication settings, click **Configure** next to OIDC.
4. Configure the IdP settings using the following mappings:
    * **Issuer URI:** The value stored in the `issuer` variable from your application in your IdP.
    * **Client ID:** The application ID from your application in your IdP.
    * **Client Secret:** The client secret from your application in your IdP.
    * **Scopes:** The scopes to be requested from your application in your IdP.
    * **Claim Mappings - Name:** `name`
    * **Claim Mappings - Email:** `email`
    * **Claim Mappings - Groups:** `groups`

5. Click the **Team Mapping** tab, and then select **IdP Mapping Enabled**.

6. Enter the exact name of your team from your IdP next to the name of the {{site.konnect_short_name}} team you want to map it to.

7. Optional: In the team's settings, disable **Sync with external identity provider (IdP)** for any team you don't want IdP logins to overwrite.

    This setting is enabled by default for every new and existing team, even before IdP mapping is configured for the {{site.dev_portal}}. 
    When enabled, developers are added to or removed from the team automatically at login, based on their `groups` claim. When disabled, the admin can manage the team manually in {{site.konnect_short_name}}.

    Disable this setting when a {{site.dev_portal}} admin needs to create or manage a team manually without IdP access, or to keep an old IdP's teams and a new IdP's teams side by side temporarily during a [migration](#migrate-developer-teams-to-a-new-idp).


    {:.warning}
    > If IdP mapping is enabled and this setting is enabled for a {{site.konnect_short_name}}-managed team, {{site.konnect_short_name}} treats the team as an empty IdP group. Developers are removed from the team at their next login, even if they were added manually.
{% endnavtab %}
{% navtab "API" %}
1. The team you're mapping to must already exist before you create the mapping. Create it by sending a `POST` request to the [`/portals/{portalId}/teams` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-team):
{% capture create-team %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams
status_code: 201
method: POST
body:
    name: IDM - Developers
    description: The Identity Management (IDM) team
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-team | indent: 3 }}

    The team object includes a `konnect_managed` field. `konnect_managed: true` means the team is managed manually in {{site.konnect_short_name}}. `konnect_managed: false` means the team is synced from the IdP.
    You can change this by sending a `PATCH` request to the [`/portals/{portalId}/teams/{teamId}` endpoint](/api/konnect/portal-management/v3/#/operations/update-portal-team). If the team is currently mapped to an IdP group, remove the mapping first by sending a `DELETE` request to the [`/portals/{portalId}/identity-providers/{id}/team-group-mappings/{mappingId}` endpoint](/api/konnect/portal-management/v3/#/operations/delete-portal-idp-team-group-mapping).

1. Configure the IdP by sending a `POST` request to the [`/portals/{portalId}/identity-providers` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-identity-provider):
{% capture create-idp %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/identity-providers
status_code: 201
method: POST
body:
    type: oidc
    enabled: true
    config:
        issuer_url: https://konghq.okta.com/oauth2/default
        client_id: YOUR_CLIENT_ID
        client_secret: YOUR_CLIENT_SECRET
        scopes:
            - openid
            - email
            - profile
        claim_mappings:
            name: name
            email: email
            groups: groups
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-idp | indent: 3 }}

1. Map an IdP group to the team by sending a `POST` request to the [`/portals/{portalId}/identity-providers/{id}/team-group-mappings` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-idp-team-group-mapping):
{% capture create-mapping %}
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/identity-providers/$IDP_ID/team-group-mappings
status_code: 201
method: POST
body:
    team_id: $TEAM_ID
    group: IDM - Developers
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-mapping | indent: 3 }}
{% endnavtab %}
{% endnavtabs %}

## Test developer team mappings

Now that you've configured the IdP team mappings in {{site.konnect_short_name}} for the {{site.dev_portal}}, you can test the team mappings.

Find your {{site.dev_portal}} URL in the {{site.dev_portal}} settings in the **Portal Domain**, navigate to that URL, and log in as a test developer that is assigned to the team in your IdP.

## Migrate developer teams to a new IdP

If you're moving from one IdP to another, you can freeze your existing teams so they aren't affected while you set up and test the new IdP.

1. For each team currently mapped to your old IdP, disable **Sync with external identity provider (IdP)** in the team's settings. This excludes the team from synchronization so its membership stays as-is.

1. Configure and test the new IdP by following [Set up developer teams and group claims in your IdP](#set-up-developer-teams-and-group-claims-in-your-idp) and [Map IdP developer teams in {{site.konnect_short_name}}](#map-idp-developer-teams-in-konnect).

1. After the new IdP's teams are mapped and verified, delete the old, frozen teams.
