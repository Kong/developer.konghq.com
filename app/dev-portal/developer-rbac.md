---
title: Dev Portal developer RBAC
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

description: "The Dev Portal allows you to manage developers by creating teams and assigning specific roles for each API."

related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
---

The Dev Portal allows you to manage [registered developers](/dev-portal/developer-signup/) by creating teams and assigning specific roles for each API.

## Enable developer RBAC

To use RBAC, you need to enable it from your Dev Portal settings:
{% navtabs "enable-rbac" %}
{% navtab "UI" %}
1. In {{site.konnect_short_name}}, click [**Dev Portal**](https://cloud.konghq.com/portals/) in the sidebar.
1. Click your Dev Portal.
1. Click **Settings** in the sidebar.
1. Click the **Security** tab.
1. Enable **Role-based access control (RBAC)**.
1. Click **Save changes**.
{% endnavtab %}
{% navtab "API" %}
Send a `POST` request to the [`/portals/{portalId}/teams` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-team):
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
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_portal_team` resource](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/konnect_portal_team.tf):
```hcl
echo '
resource "konnect_portal_team" "my_portalteam" {
  description = "The Identity Management (IDM) team."
  name        = "IDM - Developers"
  portal_id   = "f32d905a-ed33-46a3-a093-d8f536af9a8a"
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

## Manage developer RBAC

You can manage developers, app registrations, and teams from the **Access and approvals** tab in your Dev Portal.

To assign roles to developers, you need to create a team and add them to it:
{% navtabs "assign-roles" %}
{% navtab "UI" %}
1. In {{site.konnect_short_name}}, click [**Dev Portal**](https://cloud.konghq.com/portals/) in the sidebar.
1. Click your Dev Portal.
1. Click **Access and approvals** in the sidebar.
1. Click the **Teams** tab.
1. Click **New Team**.
1. Enter a team name in the **Team** field.
1. Enter a team description in the **Description** field.
1. Click **Save**.
1. Click the name of your new team.
1. Click **Add developer**.
1. Select a developer from the **Select one or more developer** dropdown menu.
1. Click the **APIs** tab.
1. Click **Add role**.
1. Select an API from the **API** dropdown menu.
1. Select a role from the **Add roles** dropdown menu. 
   You can set a role for all APIs on the Dev Portal, or set different roles for specific APIs. The following roles are available:
  
   * **API Consumer**: This role allows developers on the team to make calls to the selected APIs.
   * **API Viewer**: This role gives developers on the team read-only access to the selected APIs' documentation.
{% endnavtab %}
{% navtab "API" %}
1. Assign a developer to a team by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/developers` endpoint](/api/konnect/portal-management/v3/#/operations/add-developer-to-portal-team):
<!--vale off-->
{% capture team %}
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams/$TEAM_ID/developers
status_code: 201
method: POST
body:
    id: $DEVELOPER_ID
{% endkonnect_api_request %}
{% endcapture %}
{{ team | indent: 3}}
<!--vale on-->

1. Add a role to the team by sending a `POST` request to the [`/portals/{portalId}/teams/{teamId}/assigned-roles` endpoint](/api/konnect/portal-management/v3/#/operations/assign-role-to-portal-teams):
<!--vale off-->
{% capture role %}
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/teams/$TEAM_ID/assigned-roles
status_code: 201
method: POST
body:
   role_name: API Viewer
   entity_id: $API_ID
   entity_type_name: $API_NAME
   entity_region: us
{% endkonnect_api_request %}
{% endcapture %}
{{ role | indent: 3}}
<!--vale on-->
   The following roles are available:
      * **API Consumer**: This role allows developers on the team to make calls to the selected APIs.
      * **API Viewer**: This role gives developers on the team read-only access to the selected APIs' documentation.
{% endnavtab %}
{% endnavtabs %}