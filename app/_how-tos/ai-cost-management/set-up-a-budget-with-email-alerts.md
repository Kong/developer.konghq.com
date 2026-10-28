---
title: Set up a budget with email alerts in {{site.ai_cost_management}}
permalink: /ai-cost-management/set-up-a-budget-with-email-alerts/
content_type: how_to
description: Create a monthly budget for OpenAI spend in {{site.ai_cost_management}} and send email alerts as spend reaches 50, 80, and 100 percent of the limit.

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
  q: How do I get email alerts when AI spend reaches a limit?
  a: |
    To send email alerts when AI spend reaches a limit, create an email notification channel, then create a limit budget scoped to your provider with a monthly budget window.

    Add a notification rule to the budget to trigger the alerts, and list the email channel on the rule.

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Email address
      content: |
        {{site.ai_cost_management}} sends the budget alerts in this guide to an email address.
        Export the address that should receive them as an environment variable:

        ```sh
        export EMAIL_ADDRESS='YOUR_EMAIL_ADDRESS'
        ```
      icon_url: /assets/icons/email.svg

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
  - text: Set up a budget with Slack alerts
    url: /ai-cost-management/set-up-a-budget-with-slack-alerts/

automated_tests: false
---

A [budget](/ai-cost-management/budgets/) tracks the AI spend of requests that pass through {{site.ai_gateway}} against a limit, then sends alerts as spend grows toward that limit.

In this guide, you'll create a monthly budget for OpenAI usage that sends email alerts when spend reaches 50, 80, and 100 percent of the limit.

## Create an AI Model Provider and an AI Model

{% include how-tos/steps/ai-cost-management-model.md %}

## Create an email notification channel

A [notification channel](/ai-cost-management/notification-channels/) is a destination for budget alerts.
Create an email channel using the [`/v1/ai-cost-management/notification-channels` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-cost-notification-channel).
The channel sends one message to each address in `email.recipients`:

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
      - $EMAIL_ADDRESS
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

{% include how-tos/steps/ai-cost-management-notification-rule.md channel="email" %}

## Validate

{% include how-tos/steps/ai-cost-management-validate-request.md %}

Next, send a test message to the email channel to confirm that alerts arrive:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/notification-channels/$CHANNEL_ID/tests
status_code: 202
method: POST
{% endkonnect_api_request %}
<!--vale on-->

Check the inbox of the address you exported as `EMAIL_ADDRESS`.
You should receive an email with the subject `[Kong Konnect] Test message from channel "budget-alerts-email"`.

{% include how-tos/steps/ai-cost-management-budget-balance.md %}
