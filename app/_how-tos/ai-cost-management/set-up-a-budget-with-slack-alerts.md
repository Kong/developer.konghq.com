---
title: Set up a budget with Slack alerts in {{site.ai_cost_management}}
permalink: /ai-cost-management/set-up-a-budget-with-slack-alerts/
content_type: how_to
description: Create a monthly budget for OpenAI spend in {{site.ai_cost_management}} and send alerts to Slack as spend reaches 50, 80, and 100 percent of the limit.

products:
  - ai-cost-management
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.3'

entities:
  - ai-model-provider
  - ai-model

tags:
  - ai
  - governance
  - metering

tools:
  - kongctl
  - konnect-api

tldr:
  q: How do I get Slack alerts when AI spend reaches a limit?
  a: |
    To send Slack alerts when AI spend reaches a limit, create a Slack notification channel from an incoming webhook URL, then create a limit budget scoped to your provider with a monthly budget window.

    Add a notification rule to the budget to trigger the alerts, and list the Slack channel on the rule.

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Slack webhook
      include_content: prereqs/slack-incoming-webhook
      icon_url: /assets/icons/slack.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_cost_management}} resources
      icon_url: /assets/icons/money.svg
      content: |
        Delete the budget:

        ```sh
        curl -X DELETE "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/budgets/$BUDGET_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
        {: data-test-cleanup="block" }

        Delete the notification channel:

        ```sh
        curl -X DELETE "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/notification-channels/$CHANNEL_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
        {: data-test-cleanup="block" }
    - title: Clean up {{site.ai_gateway}} resources
      icon_url: /assets/icons/ai-gateway.svg
      include_content: cleanup/products/ai-gateway

related_resources:
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/
  - text: Notification channels in {{site.ai_cost_management}}
    url: /ai-cost-management/notification-channels/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Set up a budget with email alerts
    url: /ai-cost-management/set-up-a-budget-with-email-alerts/
automated_tests: false
---

A [budget](/ai-cost-management/budgets/) tracks the AI spend of requests that pass through {{site.ai_gateway}} against a limit, then sends alerts as spend grows toward that limit.

In this guide, you'll create a monthly budget for OpenAI usage that sends alerts to Slack when spend reaches 50, 80, and 100 percent of the limit.

## Create an AI Model Provider and an AI Model

{% include how-tos/steps/ai-cost-management-model.md %}

## Create a Slack notification channel

A notification channel is a destination for budget alerts.
Create a Slack channel using the [`/v1/ai-cost-management/notification-channels` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-cost-notification-channel).
The channel posts each alert to the incoming webhook in `slack.webhook_url`:

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
    webhook_url: $SLACK_WEBHOOK_URL
extract_body:
  - name: 'id'
    variable: CHANNEL_ID
capture:
  - variable: CHANNEL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a budget

{% include how-tos/steps/ai-cost-management-budget.md %}

## Add a notification rule

{% include how-tos/steps/ai-cost-management-notification-rule.md channel="Slack" %}

## Validate

{% include how-tos/steps/ai-cost-management-validate-request.md %}

Next, send a test message to the Slack channel to confirm that alerts arrive:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/notification-channels/$CHANNEL_ID/tests
status_code: 202
method: POST
{% endkonnect_api_request %}
<!--vale on-->

Check the Slack channel that your webhook posts to.
You should see a message titled `Test message from channel "budget-alerts-slack"`.

{% include how-tos/steps/ai-cost-management-budget-balance.md %}
