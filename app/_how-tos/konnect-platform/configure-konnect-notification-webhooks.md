---
title: Configure organization webhooks in {{site.konnect_short_name}}
permalink: /how-to/configure-konnect-notification-webhooks/
description: Create an HTTP destination and subscribe it to organization events in {{site.konnect_short_name}}.
content_type: how_to
automated_tests: false
products:
  - konnect
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - notifications
  - webhook
related_resources:
  - text: Notifications in {{site.konnect_short_name}}
    url: /konnect-platform/notification-hub/
  - text: Notification Hub API
    url: /api/konnect/notification-hub/
tldr:
  q: How do I send organization events to an HTTP endpoint?
  a: Create an HTTP destination, save its signing secret, then create an organization subscription for an event and destination.
prereqs:
  inline:
    - title: Organization administrator access
      content: You need an organization administrator role to manage notification destinations and subscriptions.
    - title: HTTPS endpoint
      content: Prepare a publicly resolvable HTTPS endpoint that can receive POST requests from {{site.konnect_short_name}}.
---

Organization webhooks send selected {{site.konnect_short_name}} events to an HTTP endpoint. Destinations and subscriptions are managed at the organization level and are separate from user email and in-app notification preferences.

## List available events

List the organization events that are available to your org. The response contains each event's `event_type`, title, description, and namespace. Use the `event_type` as the event ID when creating a subscription.

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/configurations/organization
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

## Create an HTTP destination

Create a destination for the endpoint. You can add custom headers for credentials or routing; the Standard Webhooks and transport headers are reserved. An organization can have up to 50 destinations.

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations
method: POST
status_code: 201
region: global
body:
  name: Production notifications
  type: http
  url: https://example.com/konnect-notifications
  custom_headers:
    X-Environment: production
capture:
  - variable: DESTINATION_ID
    jq: '.id'
  - variable: SIGNING_SECRET
    jq: '.signing_secret'
{% endkonnect_api_request %}
<!--vale on-->

The request captures the destination `id` and `signing_secret` from the response for the following steps. Store the signing secret securely so your receiver can verify that requests came from {{site.konnect_short_name}}. The API returns the signing secret only when the destination is created.

## Subscribe a destination to an event

Create a subscription using an `event_type` from the available events response and the destination ID. Use `*` to receive the event for all regions and entities when those filters apply. You can also limit a subscription to specific regions or entity IDs.

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/configurations/organization/kai.feature.enablement/subscriptions
method: POST
status_code: 201
region: global
body:
  name: KAI enablement notifications
  destination_ids:
    - $DESTINATION_ID
  regions:
    - '*'
  entities:
    - '*'
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Replace `kai.feature.enablement` with an event type returned for your organization. Some event types might not use region or entity filters; follow the API response and validation errors for the event you select.

## Test and manage delivery

Send a test request to verify that the destination can receive notifications:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID/test
method: POST
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

Review delivery history with [`GET /notifications/deliveries`](/api/konnect/notification-hub/#/operations/list-deliveries), or inspect one delivery and its attempts with [`GET /notifications/destinations/{destinationId}/deliveries/{deliveryId}`](/api/konnect/notification-hub/#/operations/get-destination-delivery). Failed deliveries can be resent through the API. A resend has a new delivery ID but keeps the original `event_id`, which you can use to deduplicate event processing.

Requests include the Standard Webhooks `webhook-id`, `webhook-timestamp`, and `webhook-signature` headers. Verify signatures with the destination signing secret using the [Standard Webhooks specification](https://www.standardwebhooks.com/).

You can pause a subscription by setting `enabled` to `false`, or pause a destination by setting its state to `disabled`. Deleting a destination removes it from subscriptions; a subscription with no remaining destinations is deleted.
