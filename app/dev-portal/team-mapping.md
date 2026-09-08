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

Mapping teams from an IdP doesn't have to be all-or-nothing. You can exclude specific teams from IdP synchronization so their membership can be managed manually in {{site.konnect_short_name}}, even while mapping is enabled for the rest of your teams.
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

1. In [**{{site.dev_portal}}**](https://cloud.konghq.com/portal), click **Settings**.

1. In the **General** setting tab, enable **Portal RBAC**.
    
    Enabling RBAC allows you to create teams in {{site.konnect_short_name}}. You can disable RBAC after you map teams from your IdP if you don't want to use it.

1. From the **Teams** settings in the side bar, click **New Team** and configure the team.

2. From the IdP team you just created, click the **APIs** tab and click **Add Roles**. This allows you to assign APIs and the role for the APIs to members of your IdP team.

3. From **Settings** in the {{site.dev_portal}} side bar, click the **Identity** tab and then click **Configure OIDC provider**.

4. Configure the IdP settings using the following mappings:
    * **Provider URL:** The value stored in the `issuer` variable from your application in your IdP.
    * **Client ID:** The application ID from your application in your IdP.
    * **Client Secret:** The client secret from your application in your IdP.
    * **Scopes:** The scopes to be requested from your application in your IdP.
    * **Claim Mappings - Name:** `name`
    * **Claim Mappings - Email:** `email`
    * **Claim Mappings - Groups:** `groups`

5. Click the **Team Mappings** tab, and then select **IdP Mapping Enabled**.

6. Enter the exact name of your team from your IdP next to the name of the {{site.konnect_short_name}} team you want to map it to.

7. Optional: In the team's settings, disable **Sync with external identity provider (IdP)** for any team you don't want IdP logins to overwrite.

    This setting is enabled by default for every new and existing team, even before IdP mapping is configured for the {{site.dev_portal}}. 
    When enabled, developers are added to or removed from the team automatically at login, based on their `groups` claim. When disabled, the team can be managed manually in {{site.konnect_short_name}}.

    Disable this setting when a {{site.dev_portal}} admin needs to create or manage a team manually without IdP access, or to keep an old IdP's teams and a new IdP's teams side by side temporarily during a [migration](#migrate-developer-teams-to-a-new-idp).

    A team with this setting disabled can't be selected in **Team Mappings**.

    {:.warning}
    > If IdP mapping is enabled and this setting stays enabled for a team with no name entered in **Team Mappings**, {{site.konnect_short_name}} treats the team as an empty IdP group. Developers are removed from the team at their next login, even if they were added manually.

## Test developer team mappings

Now that you've configured the IdP team mappings in {{site.konnect_short_name}} for the {{site.dev_portal}}, you can test the team mappings.

Find your {{site.dev_portal}} URL in the {{site.dev_portal}} settings in the **Portal Domain**, navigate to that URL, and log in as a test developer that is assigned to the team in your IdP.

## Migrate developer teams to a new IdP

If you're moving from one IdP to another, you can freeze your existing teams so they aren't affected while you set up and test the new IdP.

1. For each team currently mapped to your old IdP, disable **Sync with external identity provider (IdP)** in the team's settings. This excludes the team from synchronization so its membership stays as-is.

1. Configure and test the new IdP by following [Set up developer teams and group claims in your IdP](#set-up-developer-teams-and-group-claims-in-your-idp) and [Map IdP developer teams in {{site.konnect_short_name}}](#map-idp-developer-teams-in-konnect).

1. After the new IdP's teams are mapped and verified, delete the old, frozen teams.
