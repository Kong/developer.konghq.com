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
1. Navigate to [Dev Portal](https://cloud.konghq.com/portals/) in {{site.konnect_short_name}} and select a Dev Portal
1. In the sidebar, click **Settings** > **Security**.
1. Click the **Role-based access control (RBAC)** toggle to enable it.

## Manage developer RBAC

You can manage developers, app registrations, and teams from the **Access and approvals** tab in your Dev Portal.

To assign roles to developers, you need to create a team and add them to it:
1. In your Dev Portal, click **Access and approvals** > **Teams**.
1. Click **New Team** to create a team, enter a name and description, and click **Save**.
1. Click the name of your new team and click **Add developer** to add existing developers to the team.
1. Open the **APIs** tab and click **Add role** to assign roles to the developer team. You can set a role for all APIs on the Dev Portal, or set different roles for specific APIs. The following roles are available:
  
   * **API Consumer**: This role allows developers on the team to make calls to the selected APIs.
   * **API Viewer**: This role gives developer on the teal read-only access to the selected APIs' documentation.