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
  - text: "Billing, invoicing, and subscriptions"
    url: /metering-and-billing/billing-invoicing-subscriptions/
---

{{site.metering_and_billing}} Notifications let you configure automated webhook alerts that fire when specific usage thresholds or billing events occur. Instead of polling for usage data, you define rules that trigger notification events to a channel of your choice when conditions are met.

## Use cases

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

1. **Channel**: Defines where to send notifications. Currently, {{site.metering_and_billing}} supports webhook channels. A single channel can be referenced by multiple rules.
2. **Rule**: Defines the condition that triggers a notification. When the condition is met, {{site.metering_and_billing}} fires a notification event to all channels attached to the rule.
3. **Event**: The notification payload delivered to your channel when a rule fires. Events include details about the customer, entitlement, and the threshold that was crossed.

## Channels

A channel defines a delivery destination for notification events. {{site.metering_and_billing}} supports the following channel type:

{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - type: Webhook
    description: |
      Sends an HTTP POST request with a JSON payload to a URL of your choice.
      <br><br>
      Use this to:

      * Integrate with Slack incoming webhooks
      * Trigger threshold-based email alerts via your email provider
      * Call an internal API to cut off a customer's access
      * Forward events to your data warehouse or alerting platform
{% endtable %}

### Create a channel

To create a webhook channel in {{site.konnect_short_name}}:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Notifications**.
1. Click the **Channels** tab.
1. Click **Create Channel**.
1. In the **Name** field, enter a name for the channel.
1. In the **URL** field, enter the webhook URL to deliver notifications to.
1. Optionally, add custom HTTP headers if your endpoint requires authentication.
1. Click **Save**.

The following fields are available when creating a webhook channel:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - field: Name
    required: "Yes"
    description: A human-readable name for the channel.
  - field: URL
    required: "Yes"
    description: "The URL that {{site.metering_and_billing}} sends notification events to via HTTP POST."
  - field: Custom Headers
    required: "No"
    description: "Optional HTTP headers to include in each request, for example, `Authorization` headers for authenticating with your endpoint."
{% endtable %}
<!--vale on-->

## Rules

A rule defines the condition that triggers a notification. When the condition is met, {{site.metering_and_billing}} delivers a notification event to the channels specified in the rule.

{{site.metering_and_billing}} supports the following rule type:

{% table %}
columns:
  - title: Rule type
    key: type
  - title: Description
    key: description
rows:
  - type: "[Entitlement balance threshold](#entitlement-balance-threshold-rules)"
    description: Fires when a customer's entitlement balance crosses a specified percentage or absolute threshold.
{% endtable %}

### Entitlement balance threshold rules

Use this rule type to fire notifications when a customer's [metered entitlement](/metering-and-billing/entitlements/#metered-entitlements) usage reaches a threshold. This is the primary rule type for implementing entitlement enforcement and customer warnings.

To create an entitlement balance threshold rule:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Notifications**.
1. Click the **Rules** tab.
1. Click **Create Rule**.
1. In the **Name** field, enter a name for the rule.
1. From the **Type** dropdown menu, select **Entitlement balance threshold**.
1. Under **Channels**, select one or more channels to deliver the notification to.
1. Under **Thresholds**, add one or more thresholds. Each threshold fires a separate notification event.
1. Optionally, scope the rule to specific features using the **Features** field.
1. Click **Save**.

The following fields are available for entitlement balance threshold rules:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - field: Name
    required: "Yes"
    description: A human-readable name for the rule.
  - field: Channels
    required: "Yes"
    description: One or more channels to deliver notification events to.
  - field: Thresholds
    required: "Yes"
    description: |
      One or more threshold definitions. Each threshold fires a separate notification event when crossed. Supports two threshold types:

      * **Percent**: A percentage of the entitlement allowance. For example, `80` fires when usage reaches 80% of the allowance.
      * **Number**: An absolute usage count. For example, `900` fires when the entitlement balance falls to 900 remaining units.
  - field: Features
    required: "No"
    description: "Optional list of feature keys to scope this rule to specific features. If left empty, the rule applies to all metered entitlements."
{% endtable %}
<!--vale on-->

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
    description: The current usage value or balance at the time the event fired.
  - field: "`timestamp`"
    description: The time at which the threshold was crossed.
{% endtable %}

You can view past notification events in {{site.konnect_short_name}} by navigating to **{{site.metering_and_billing}}** > **Notifications** and clicking the **Events** tab.

## Enforcing entitlement limits

{{site.metering_and_billing}} tracks entitlement balances and fires notification events when thresholds are crossed, but it does not automatically block API traffic when a customer's entitlement is exhausted.

{:.info}
> **Kong Gateway enforcement:** Automatic entitlement enforcement at the Kong Gateway level is planned for a future release. Until then, use the webhook-based approach described here to enforce limits in your own infrastructure.

To enforce entitlement limits today, configure a webhook notification rule and handle the incoming event in your own system:

1. [Create a webhook channel](#create-a-channel) pointing to an endpoint you control.
1. [Create an entitlement balance threshold rule](#entitlement-balance-threshold-rules) with a threshold at 100% for the feature you want to enforce.
1. In your webhook handler, take action when the event is received. For example:
   * Remove the consumer from a Kong Gateway consumer group that has access to the API.
   * Return a `403 Forbidden` response from your application layer.
   * Update a feature flag in your system to disable access for the customer.
1. Optionally, add a second threshold at 80% to send a warning to the customer before access is cut off.
