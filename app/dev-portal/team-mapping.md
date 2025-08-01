---
title: Dev Portal team mapping
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

description: "Map existing developer teams from a third-party identity provider (IdP) and their permissions to elements in a {{site.konnect_short_name}} Dev Portal."

related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Pages and content
    url: /dev-portal/pages-and-content/
  - text: "Configure SSO for a {{site.konnect_short_name}} org"
    url: /konnect-platform/sso/
---

With teams mapped from an IdP, the developers and permissions are mapped automatically in {{site.konnect_short_name}} so you don't have to manually copy over each team of developers.

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

1. In [**Dev Portal**](https://cloud.konghq.com/portal), click **Settings**.

1. In the **General** setting tab, enable **Portal RBAC**.
    
    Enabling RBAC allows you to create teams in {{site.konnect_short_name}}. You can disable RBAC after you map teams from your IdP if you don't want to use it.

1. From the **Teams** settings in the side bar, click **New Team** and configure the team.

2. From the IdP team you just created, click the **APIs** tab and click **Add Roles**. This allows you to assign APIs and the role for the APIs to members of your IdP team.

3. From **Settings** in the Dev Portal side bar, click the **Identity** tab and then click **Configure OIDC provider**.

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

## Test developer team mappings

Now that you've configured the IdP team mappings in {{site.konnect_short_name}} for the Dev Portal, you can test the team mappings.

Find your Dev Portal URL in the Dev Portal settings in the **Portal Domain**, navigate to that URL, and log in as a test developer that is assigned to the team in your IdP.
