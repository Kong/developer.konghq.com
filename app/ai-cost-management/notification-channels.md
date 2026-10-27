---
title: "Notification channels in {{site.ai_cost_management}}"
content_type: reference
layout: reference_with_schema

products:
  - ai-cost-management
  - ai-gateway

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

tools:
  - konnect-api

breadcrumbs:
  - /ai-cost-management/

tags:
  - ai
  - governance
  - metering

description: "Reference for notification channels in {{site.ai_cost_management}}. Covers the email and Slack channel types, how to create and test a channel, and how budget alerts reach it."

schema:
  api: konnect/ai-cost-management
  path: /schemas/AICostNotificationChannel

api_specs:
  - konnect/ai-cost-management

related_resources:
  - text: "{{site.ai_cost_management}}"
    url: /ai-cost-management/
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/
  - text: Set up a budget with email alerts
    url: /ai-cost-management/set-up-a-budget-with-email-alerts/
  - text: Set up a budget with Slack alerts
    url: /ai-cost-management/set-up-a-budget-with-slack-alerts/
---

## What is a notification channel?

A notification channel is a destination for budget alerts in {{site.ai_cost_management}}.
Use channels to send each budget's alerts where the right people will see them, for example an email list for finance and a Slack channel for the team that owns the budget.

You only need to create a channel once, then list it in the notification rule of any [budget](/ai-cost-management/budgets/).

One channel can serve many budgets, and a rule can list up to 10 channels.
A channel has a name of 1 to 100 characters and optional labels, and several channels can share a name.

## Channel types

{{site.ai_cost_management}} supports the following channel types:

* **Email**: {{site.ai_cost_management}} sends one message to each recipient address. A channel holds 1 to 10 addresses, and each address can appear only once, ignoring case.
* **Slack**: {{site.ai_cost_management}} posts the message to the Slack incoming webhook URL, which you create in your own Slack workspace. Slack workflow trigger URLs aren't accepted.

When you replace a Slack channel, you can omit `slack.webhook_url` to keep the stored URL.

## Set up a notification channel

{% navtabs "set-up-channel" %}
{% navtab "UI" %}

To create an email or Slack channel:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. In the Cost Management sidebar, click **Budget Policies**.
1. Click the **Channels** tab.
1. Click **New channel**.
1. In the **Name** field, enter a name for the channel.
1. From the **Channel type** dropdown menu, select "Email" or "Slack".
1. Enter the delivery details for the channel type:
   * For an email channel, in the **Recipients** field, enter an email address. Repeat for each address that should receive alerts.
   * For a Slack channel, enter the webhook URL from your [Slack incoming webhook](/ai-cost-management/set-up-a-budget-with-slack-alerts/#prerequisites).
1. Click **Create channel**.

{% endnavtab %}
{% navtab "Konnect API" %}

To create an email channel, send a `POST` request to the [`/v1/ai-cost-management/notification-channels` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-cost-notification-channel). Replace `YOUR_EMAIL_ADDRESS` with the address that should receive alerts:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/notification-channels
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: budget-alerts-email
  type: email
  email:
    recipients:
      - $YOUR_EMAIL_ADDRESS
{% endkonnect_api_request %}
<!--vale on-->

To create a Slack channel, send a `POST` request to the [`/v1/ai-cost-management/notification-channels` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-cost-notification-channel) with the `slack` type and the webhook URL from your [Slack incoming webhook](/ai-cost-management/set-up-a-budget-with-slack-alerts/#prerequisites). Replace `YOUR_SLACK_WEBHOOK_URL` with the URL:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/notification-channels
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: budget-alerts-slack
  type: slack
  slack:
    webhook_url: $YOUR_SLACK_WEBHOOK_URL
{% endkonnect_api_request %}
<!--vale on-->

The response includes the `id` of the channel, which you list in a budget's notification rule.

{% endnavtab %}
{% endnavtabs %}

## Test a notification channel

To check a channel before you attach it to a budget, send it a test message.
The test message looks like an alert, with test wording and example figures.
Its title is `Test message from channel "<name>"`, with the name of the channel.
{{site.ai_cost_management}} sends the test within seconds and records the outcome as a notification event.

To send a test, send a `POST` request to the [`/v1/ai-cost-management/notification-channels/{channelId}/tests` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-cost-notification-channel-test). Replace `CHANNEL_ID` with the `id` of the channel:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/notification-channels/$CHANNEL_ID/tests
status_code: 202
method: POST
{% endkonnect_api_request %}
<!--vale on-->

The response is the notification event that records the test.
To read the outcome, get the event with the [`/v1/ai-cost-management/notification-events/{eventId}` endpoint](/api/konnect/ai-cost-management/v1/#/operations/get-notification-event).
While a channel already has a pending test, a new request returns that test instead of queueing another.

## Schema

{% entity_schema %}
