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

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to connect {{site.ai_gateway}} to OpenAI and store your credentials, and an [AI Model](/ai-gateway/entities/ai-model/) that routes requests to that provider.
Requests to the model produce the spend that the budget tracks:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: budget-gpt-4o
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: budget-gpt-4o
    display_name: "budget-gpt-4o"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - budget-gpt-4o
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
    policies: []
{% endentity_examples %}

{:.info}
> `!env AI_GATEWAY_ID` references the {{site.ai_gateway}} that the quickstart script created in the [prerequisites](#prerequisites), instead of creating a new one.

## Create an email notification channel

A notification channel is a destination for budget alerts.
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

Create a limit budget using the [`/v1/ai-cost-management/budgets` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-budget).
The scope filter selects requests to the `openai` provider, and the limit applies to all of them together.
Each budget window lasts one month (`P1M`).
The anchor is January 1, 2026 in UTC, so every window starts on the first day of a month:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/budgets
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: openai-monthly-budget
  effect: limit
  scope:
    filters:
      - field: provider
        op: eq
        value: openai
  limit:
    currency: USD
    value: "500"
  window:
    type: fixed
    interval: P1M
    anchor: "2026-01-01T00:00:00+00:00[UTC]"
extract_body:
  - name: 'id'
    variable: BUDGET_ID
capture:
  - variable: BUDGET_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The budget observes spend and sends alerts.
Requests to OpenAI continue after spend reaches the $500 limit.

## Add a notification rule

Add a notification rule to the budget using the [`/v1/ai-cost-management/budgets/{budgetId}/notification-rule` endpoint](/api/konnect/ai-cost-management/v1/#/operations/replace-notification-rule).

The rule alerts the email channel when spend reaches 50, 80, and 100 percent of the limit.
Each threshold triggers an alert at most once per budget window:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/budgets/$BUDGET_ID/notification-rule
status_code: 201
method: PUT
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  thresholds:
    - percent: 50
    - percent: 80
    - percent: 100
  channels:
    - id: $CHANNEL_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate

Send a request through {{site.ai_gateway}} so the budget has spend to track:

<!--vale off-->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    model: budget-gpt-4o
    messages:
        - role: "user"
          content: "Say this is a test!"
{% endvalidation %}
<!--vale on-->

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

Check the balance of the budget:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/budgets/$BUDGET_ID/balance
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The response shows the `limit` (500 US dollars), the spend so far in `consumed`, the amount left in `remaining`, and the spend expected by the end of the budget window in `projected`.

Usage takes a short time to reach the service, so `consumed` can show no spend right after the request.
The `latest_record_at` field shows when the newest counted usage arrived, and it's `null` until usage matches the budget.
The `projected` field rounds to the cent, so it can show `0` when spend is a fraction of a cent.
