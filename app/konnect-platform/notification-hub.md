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
  - text: Configure organization webhooks
    url: /how-to/configure-konnect-notification-webhooks/
  - text: "{{site.konnect_short_name}} account management"
    url: /konnect-platform/account/
  - text: "{{site.konnect_short_name}} teams and roles"
    url: /konnect-platform/teams-and-roles/
---

{{site.konnect_short_name}}’s Notification Hub keeps you up to date on critical events across your organization. 

Notifications are delivered through two supported channels: email and in-app (via the bell icon in the {{site.konnect_short_name}} UI).
Notification delivery is scoped to users with [access to the relevant entity](/konnect-platform/teams-and-roles/). 

You can manage your notification configurations through the [bell icon next to your user menu](https://cloud.konghq.com/global/notifications/) in the {{site.konnect_short_name}} UI, or the [Notification Hub API](/api/konnect/notification-hub/). 

Organization administrators can also send organization-scoped events to HTTP endpoints using webhook destinations and subscriptions. These subscriptions are managed separately from user email and in-app preferences. See [Configure organization webhooks](/how-to/configure-konnect-notification-webhooks/) for setup steps. The [organization events API](/api/konnect/notification-hub/#/operations/list-org-configurations) lists the event types available to your organization.

The Notification Hub generates notifications for the following areas:

* **Dev Portal**: Developer and application registration requests.
* **API Gateway**: Entity notification configurations. You can have up to three regional notification configurations per entity.
* **Organization**: Configurable notifications about org access and audit logs.
* **Billing**: Org billing notifications. These notifications are sent to organization admins, and they are mandatory - you can't opt out of billing notifications.

## Organization webhook events

The events available for webhook subscriptions depend on your organization. Organization administrators can retrieve the current list, including each event's type, title, description, and namespace, from [`GET /notifications/configurations/organization`](/api/konnect/notification-hub/#/operations/list-org-configurations). Use the `event_type` value when creating a subscription.

{% assign org_notification_events = site.data.konnect_notification_events %}
{% if org_notification_events.size > 0 %}

<!--vale off-->
{% table %}
columns:
  - title: Event type
    key: event_type
  - title: Name
    key: event_title
  - title: Description
    key: event_description
  - title: Namespace
    key: event_namespace
rows:
{% for event in org_notification_events %}
  - event_type: {{ event.event_type | jsonify }}
    event_title: {{ event.event_title | jsonify }}
    event_description: {{ event.event_description | jsonify }}
    event_namespace: {{ event.event_namespace | jsonify }}
{% endfor %}
{% endtable %}
<!--vale on-->

{% endif %}






