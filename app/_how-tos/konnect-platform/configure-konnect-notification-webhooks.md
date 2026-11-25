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
  skip_product: true
  inline:
    - title: Organization administrator access
      content: You need an organization administrator role to manage notification destinations and subscriptions.
    - title: HTTPS endpoint
      content: |
        Prepare a publicly resolvable HTTPS endpoint that can receive POST requests from {{site.konnect_short_name}}.

        {% include prereqs/webhook-site.md %}
    - title: "{{site.dev_portal}}"
      include_content: prereqs/dev-portal-configure
      icon_url: /assets/icons/dev-portal.svg
cleanup:
  inline:
    - title: Delete the notification resources
      include_content: cleanup/platform/notification-webhooks
      icon_url: /assets/icons/dev-portal.svg
---

Organization webhooks send selected {{site.konnect_short_name}} events to an HTTP endpoint. Destinations and subscriptions are managed at the organization level and are separate from user email and in-app notification preferences.

Organization webhooks aren't limited to events in the `organization` namespace. Organization administrators can subscribe to events from other {{site.konnect_short_name}} areas, such as {{site.dev_portal}}, Gateway Manager, and Plan and Usage. This guide uses a {{site.dev_portal}} event because you can trigger it on demand.

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
  url: $WEBHOOK_URL
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

## Require approval for new developers

This guide uses the `devportal_developer.registration_pending` event, which {{site.konnect_short_name}} sends when a developer signs up for a {{site.dev_portal}} that requires approval. Turn off auto-approve for developers so that new sign-ups are pending and trigger the event:

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID
method: PATCH
status_code: 200
body:
  auto_approve_developers: false
{% endkonnect_api_request %}
<!--vale on-->

## Subscribe a destination to an event

Create a subscription using an `event_type` from the available events response and the destination ID. Use `*` to receive the event for all regions and entities when those filters apply. You can also limit a subscription to specific regions or entity IDs.

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/configurations/organization/devportal_developer.registration_pending/subscriptions
method: POST
status_code: 201
region: global
body:
  name: Developer registration notifications
  destination_ids:
    - $DESTINATION_ID
  regions:
    - '*'
  entities:
    - '*'
  enabled: true
capture:
  - variable: SUBSCRIPTION_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->

To subscribe to a different event, replace `devportal_developer.registration_pending` with an event type returned for your organization. Some event types might not use region or entity filters; follow the API response and validation errors for the event you select.

## Trigger an event

Send a test request to verify that the destination can receive notifications:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID/test
method: POST
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

Then trigger a real event:

1. Run `echo https://$PORTAL_URL` and open the returned URL in a private browser window.
1. Click **Sign up** and [register a test developer account](/dev-portal/developer-signup/#1-register-or-sign-in).
1. On [webhook.site](https://webhook.site), check that you received a `POST` request for the `devportal_developer.registration_pending` event.

## Review delivery history

List the deliveries for your destination. Each delivery shows its `event_type`, `status`, and `mode`, which is `test` for the test request and `live` for real events. The request captures the ID of the most recent delivery:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/deliveries?filter%5Bdestination_id%5D%5Beq%5D=$DESTINATION_ID
method: GET
status_code: 200
region: global
capture:
  - variable: DELIVERY_ID
    jq: '.data[0].id'
{% endkonnect_api_request %}
<!--vale on-->

Inspect the delivery and each of its attempts:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID/deliveries/$DELIVERY_ID
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

If a delivery has the `failed` status, you can resend it:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID/deliveries/$DELIVERY_ID/resend
method: POST
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->

A resend has a new delivery ID but keeps the original `event_id`, which you can use to deduplicate event processing.

Requests include the Standard Webhooks `webhook-id`, `webhook-timestamp`, and `webhook-signature` headers. Verify signatures with the destination signing secret using the [Standard Webhooks specification](https://www.standardwebhooks.com/).

## Pause notifications

To stop sending one event to its destinations without deleting the subscription, set `enabled` to `false` on the subscription:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/configurations/organization/devportal_developer.registration_pending/subscriptions/$SUBSCRIPTION_ID
method: PATCH
status_code: 200
region: global
body:
  enabled: false
{% endkonnect_api_request %}
<!--vale on-->

To stop sending all events to a destination, set its `state` to `disabled`. Set it back to `enabled` to resume delivery:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID
method: PATCH
status_code: 200
region: global
body:
  type: http
  state: disabled
{% endkonnect_api_request %}
<!--vale on-->

Deleting a destination removes it from all its subscriptions and deletes any subscription that has no destinations left.
