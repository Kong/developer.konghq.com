---
title: Notifications in {{site.konnect_short_name}}
content_type: reference
layout: reference
products:
  - konnect
works_on:
    - konnect
api_specs:
    - konnect/notification-hub
breadcrumbs:
  - /konnect/
description: "{{site.konnect_short_name}}’s Notification Hub keeps you up to date on critical events across your organization."

related_resources:
  - text: "{{site.konnect_short_name}} account management"
    url: /konnect-platform/account/
  - text: "{{site.konnect_short_name}} teams and roles"
    url: /konnect-platform/teams-and-roles/
---

{{site.konnect_short_name}}’s Notification Hub keeps you up to date on critical events across your organization. 

Notifications are delivered through two supported channels: email and in-app (via the bell icon in the {{site.konnect_short_name}} UI).
Notification delivery is scoped to users with [access to the relevant entity](/konnect-platform/teams-and-roles/). 

You can manage your notification configurations through the [bell icon next to your user menu](https://cloud.konghq.com/global/notifications/) in the {{site.konnect_short_name}} UI, or the [Notification Hub API](/api/konnect/notification-hub/). 

The Notification Hub generates notifications for the following areas:
* **Organization**: Configurable notifications about org access and audit logs.
* **API Gateway**: Entity notification configurations. You can have up to three regional notification configurations per entity.
* **Billing**: Org billing notifications. These notifications are sent to organization admins, and they are mandatory - you can't opt out of billing notifications.






