---
title: "Notifications"
content_type: reference
description: "Use {{site.metering_and_billing}} Notifications to receive webhook alerts when customers reach entitlement thresholds or billing events occur."
layout: reference
products:
  - metering-and-billing
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: Entitlements
    url: /metering-and-billing/entitlements/
  - text: "Billing and invoicing"
    url: /metering-and-billing/billing-invoicing/
---

{{site.metering_and_billing}} Notifications let you configure automated webhook alerts that trigger when specific usage thresholds or billing events occur. Instead of polling for usage data, you define rules that trigger notification events to a channel of your choice when conditions are met.

## Use cases

The following table describes the use cases for notifications:
<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: case
  - title: Description
    key: description
rows:
  - case: Entitlement enforcement
    description: |
      Receive a webhook when a customer reaches a percentage of their entitlement allowance (for example, 80% or 100%) and take action in your system, such as restricting access or sending a warning to the customer.
      <br><br>
      See [Enforcing entitlement limits](#enforcing-entitlement-limits) for details.
  - case: Customer warnings
    description: Notify customers before they reach their usage limits to avoid unexpected service interruptions or overage charges.
  - case: Sales alerts
    description: Alert your sales team when a customer approaches or exceeds their plan limits to trigger an upgrade conversation.
  - case: Invoice events
    description: Receive a webhook when an invoice is created, issued, or paid to trigger downstream processes such as ERP sync or custom delivery.
{% endtable %}
<!--vale on-->

## How it works

The {{site.metering_and_billing}} Notifications system is built around three entities:

{% mermaid %}
flowchart LR
    Rule["Rule<br/>(when to trigger)"]
    Channel["Channel<br/>(where to send)"]
    Event["Event<br/>(the notification sent)"]

    Rule --> Event
    Event --> Channel
{% endmermaid %}

2. **Rule**: Defines the condition that triggers a notification. When the condition is met, {{site.metering_and_billing}} sends a notification event to all channels attached to the rule.
3. **Event**: The notification payload delivered to your channel when a rule triggers. Events include details about the customer, entitlement, and the threshold that was crossed.
1. **Channel**: Defines where to send notifications. Currently, {{site.metering_and_billing}} supports webhook channels. A single channel can be referenced by multiple rules.

## Channels

A channel defines a delivery destination for notification events. {{site.metering_and_billing}} supports webhook channels, which send an HTTP POST request with a JSON payload to a URL of your choice.

Use webhook channels to:

* Integrate with Slack incoming webhooks
* Trigger threshold-based email alerts via your email provider
* Call an internal API to cut off a customer's access
* Forward events to your data warehouse or alerting platform

### Create a channel

To create a webhook channel in {{site.konnect_short_name}}:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click the **Notifications** tab.
1. Click **Create Channel**.
1. In the **Name** field, enter a name for the channel.
1. In the **URL** field, enter the webhook URL to deliver notifications to.
1. (Optional) Add custom HTTP headers if your endpoint requires authentication.
1. Click **Save**.

### Verify webhook requests

When exposing a webhook endpoint, make sure the sender is authenticated before you process the payload. {{site.metering_and_billing}} lets you add custom HTTP headers when you create the channel. A common pattern is to configure a shared secret in a custom header, for example `Authorization: Bearer <secret>` or `X-Webhook-Secret: <secret>`, and validate that value in your webhook handler for every delivery.

Reject requests with a missing or invalid authentication header by returning a `400` or `401` response, and only process the notification after the header value matches the secret you configured on the channel.
## Rules

A rule defines the condition that triggers a notification. When the condition is met, {{site.metering_and_billing}} delivers a notification event to the channels specified in the rule.

{{site.metering_and_billing}} supports the following rule types:

{% table %}
columns:
  - title: Rule type
    key: type
  - title: Description
    key: description
rows:
  - type: "[Entitlement balance threshold](#entitlement-balance-threshold-rules)"
    description: Triggers when a customer's entitlement balance crosses a specified percentage or absolute threshold.
  - type: Entitlement reset
    description: Triggers when an entitlement is reset, either manually or automatically.
  - type: Invoice created
    description: Triggers when a new invoice is created.
  - type: Invoice updated
    description: Triggers when an invoice changes state.
{% endtable %}

{:.info}
> Notifications for [gathering invoices](/metering-and-billing/billing-invoicing/) are not currently supported.

### Entitlement balance threshold rules

Use this rule type to trigger notifications when a customer's [metered entitlement](/metering-and-billing/entitlements/#metered-entitlements) usage reaches a threshold. This is the primary rule type for implementing entitlement enforcement and customer warnings.

To create an entitlement balance threshold rule:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click the **Notifications** tab.
1. Click **Create Rule**.
1. In the **Name** field, enter a name for the rule.
1. From the **Type** dropdown menu, select "Entitlement balance threshold".
1. From the **Channels** dropdown menu, select one or more channels to deliver the notification to.
1. (Optional) From the **Features** dropdown menu, select features to scope the rule to.
1. From the **Thresholds** settings, add one or more thresholds. Each threshold triggers a separate notification event.
1. Click **Save**.

## Notification events

When a rule condition is met, {{site.metering_and_billing}} delivers a notification event as an HTTP POST request to all channels attached to the rule. The event payload is a JSON object containing the following information:

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`id`"
    description: Unique identifier for the notification event.
  - field: "`type`"
    description: "The rule type that triggered this event, for example `entitlements.balance.threshold`."
  - field: "`rule`"
    description: The rule configuration that triggered this event.
  - field: "`subject`"
    description: The customer subject that triggered this event.
  - field: "`threshold`"
    description: The specific threshold that was crossed.
  - field: "`feature`"
    description: The feature key associated with the entitlement.
  - field: "`entitlement`"
    description: The entitlement configuration, including type and allowance.
  - field: "`value`"
    description: The current usage value or balance at the time the event was triggered.
  - field: "`timestamp`"
    description: The time at which the threshold was crossed.
{% endtable %}

Each notification event has a delivery state:

<!--vale off-->
{% table %}
columns:
  - title: State
    key: state
  - title: Description
    key: description
rows:
  - state: "`PENDING`"
    description: The event was created but sending hasn't started.
  - state: "`SENDING`"
    description: The event is actively being transmitted to the channel.
  - state: "`SUCCESS`"
    description: The event was delivered successfully.
  - state: "`FAILED`"
    description: The event couldn't be delivered.
{% endtable %}
<!--vale on-->

You can view past notification events in {{site.konnect_short_name}} by navigating to **{{site.metering_and_billing}}** > **Settings** > **Notifications** and clicking the name of the rule.

## Enforcing entitlement limits

{{site.metering_and_billing}} tracks entitlement balances and triggers notification events when thresholds are crossed, but it does not automatically block API traffic when a customer's entitlement is exhausted.

To enforce entitlement limits today, configure a webhook notification rule and handle the incoming event in your own system:

1. [Create a webhook channel](#create-a-channel) pointing to an endpoint you control.
1. [Create an entitlement balance threshold rule](#entitlement-balance-threshold-rules) with a threshold at 100% for the feature you want to enforce.
1. In your webhook handler, take action when the event is received. For example:
   * Remove the Consumer from a {{site.base_gateway}} Consumer Group that has access to the API.
   * Return a `403 Forbidden` response from your application layer.
   * Update a feature flag in your system to disable access for the customer.
1. (Optional) Add a second threshold at 80% to send a warning to the customer before access is cut off.
