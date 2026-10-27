---
title: "Budgets in {{site.ai_cost_management}}"
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

description: "Reference for budgets in {{site.ai_cost_management}}. Covers the usage a budget tracks, how its limit and budget window work, and how notification rules and channels alert you as spend grows."

schema:
  api: konnect/ai-cost-management
  path: /schemas/AICostLimitBudgetInput

api_specs:
  - konnect/ai-cost-management

related_resources:
  - text: "{{site.ai_cost_management}}"
    url: /ai-cost-management/
  - text: Notification channels in {{site.ai_cost_management}}
    url: /ai-cost-management/notification-channels/
  - text: Set up a budget with email alerts
    url: /ai-cost-management/set-up-a-budget-with-email-alerts/
  - text: Set up a budget with Slack alerts
    url: /ai-cost-management/set-up-a-budget-with-slack-alerts/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
---

## What is a budget?

A budget in {{site.ai_cost_management}} tracks AI spend against a limit and sends alerts as spend approaches it.
If a team's AI usage can run past what your organization planned to spend, budgets give you an early signal while there's still time to react.

Budgets observe spend and send alerts. They don't enforce spend limits, so requests continue after spend reaches the limit.

You can send budget alerts to [notification channels](/ai-cost-management/notification-channels/).

## Use cases for budgets

Common use cases for budgets:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: Cap total AI spend
    description: |
      Set one limit on all AI usage in your organization with an organization-wide budget, so you know when overall spend nears a planned amount.
  - use_case: Share one allowance across groups
    description: |
      Give several groups a combined limit with a pooled budget, so their spend counts against the same allowance.
  - use_case: Give every group or user the same cap
    description: |
      Split the limit by a field, so every group, user, provider, or model gets its own limit from a single budget.
  - use_case: Watch one provider or model
    description: |
      Scope a budget to a provider or model with a filter, so you see when spend on a costly model grows.
  - use_case: Get an early warning
    description: |
      Add notification thresholds below the limit, like 50 and 80 percent, to alert people while there's time to react. A threshold above 100 percent alerts on spend beyond the limit. 
{% endtable %}
<!--vale on-->

To create a provider budget that sends early warnings to a channel, follow one of these guides:
* [Set up a budget with email alerts](/ai-cost-management/set-up-a-budget-with-email-alerts/)
* [Set up a budget with Slack alerts](/ai-cost-management/set-up-a-budget-with-slack-alerts/)

## How budgets work

Here's how a budget works:
1. {{site.ai_gateway}} records each AI request that passes through it, with its cost, as usage.
1. {{site.ai_cost_management}} matches that usage against the scope of each budget.
1. Matching usage counts toward the budget's spend in the current budget window, so the spend count increases.
1. When spend reaches a threshold in the budget's notification rule, {{site.ai_cost_management}} sends an alert to the rule's [notification channels](/ai-cost-management/notification-channels/) and records a notification event.
1. When the budget window ends, a new window starts and spend begins again at zero.

<!--vale off-->
{% mermaid %}
sequenceDiagram
  autonumber
  participant GW as {{site.ai_gateway}}
  participant ACM as {{site.ai_cost_management}}
  participant CH as Notification channels

  GW->>ACM: Report cost of each AI request as usage
  ACM->>ACM: Match usage against the scope of each budget
  ACM->>ACM: Add the cost to the spend in current budget window
  alt If spend reaches a threshold <br>in notification rule
    ACM->>CH: Send an alert
    ACM->>ACM: Record a notification event
  end
{% endmermaid %}
_Figure 1: Diagram showing how a budget tracks spend and sends alerts._
<!--vale on-->

A request can match several budgets.
The request counts toward every budget it matches, and {{site.ai_cost_management}} evaluates each budget on its own.

For example, let's say you have two budgets:
* An organization-wide budget with a $100 limit
* A second budget for OpenAI usage with a $50 limit

An OpenAI request counts toward both budgets, and the OpenAI budget sends alerts at its own thresholds, based on OpenAI spend alone.

## Budget scope

The scope of a budget selects which AI requests count toward its spend limit.

A scope has filters, and it can split the budget into one limit per value of a field.
Filters narrow a budget to the usage you want it to cover.
Each filter compares a [usage field](#schema-aicost-limit-budget-input-scope-filters-aicost-budget-scope-predicate-input-aicost-budget-scope-value-predicate-input-field) (for example, a provider, model, or tag) with a value.
Usage counts toward the budget only when it matches all of the filters.

A budget with no filters counts all usage in your organization.

### Filter operators and groups

A filter uses an operator like `eq`, `neq`, `in`, `contains`, or `exists` to compare a field with a value.
The [subject and group fields](#schema-aicost-limit-budget-input-scope-filters-aicost-budget-scope-predicate-input-aicost-budget-scope-value-predicate-input-field) don't accept `contains` or `ocontains`.

A filter group combines several filters with `and` or `or`, and a group can contain further groups.
A scope allows at most 15 conditions in total, nested at most 4 groups deep.

### Limits

Budgets can apply their spend limits in one of the following ways:

<!--vale off-->
{% table %}
columns:
  - title: Limit type
    key: limit_type
  - title: Description
    key: description
  - title: When to use
    key: when_to_use
rows:
  - limit_type: "Pooled limit"
    description: |
      In a pooled limit, one limit applies to all the usage in scope.
      A budget pools its usage by default.
      <br><br>
      A pooled limit can cover the usage that matches a set of filters, or all usage in your organization.
    when_to_use: |
      Choose a pooled limit when the usage in scope shares one allowance, like a team with a single monthly allowance.
  - limit_type: "Individual limit"
    description: |
      With an individual limit, you choose a field to split the budget by, and every value of that field gets its own limit.
      Each value gets a derived budget with the same limit.
      Usage with no value for that field doesn't count toward any derived budget.
      One budget covers all of its values, so you don't create a budget for each one.
    when_to_use: |
      Choose an individual limit when every value needs the same cap, like every user or every model.
{% endtable %}
<!--vale on-->

Either limit works with any scope, including a scope with no filters, which covers all usage in your organization.
For example, a pooled limit on an empty scope is one limit for your whole organization, and an individual limit on an empty scope gives every user, provider, or model the same cap.

## Limit and budget window

The limit sets the spend a budget allows in one budget window.
Set the limit as an amount in US dollars, for example `500` or `0.2`.

{:.info}
> `USD` is the only supported currency.

The size of a budget window is fixed. Consecutive windows have the same length and align to an anchor.
* The [interval](#schema-aicost-limit-budget-input-window-interval) sets the length of each window, like one month or one day.
* The [anchor](#schema-aicost-limit-budget-input-window-anchor) sets a time when a window starts, in a specific time zone.

Windows start a whole number of intervals before or after the anchor, in the local time of the anchor's time zone.
Calendar units like months therefore stay aligned to the calendar.
A window that would start on a day its month doesn't have, like the 31st, starts on the last day of that month.

## Budget balance

The balance of a limit budget shows spend, the amount remaining, and projected spend for one budget window.

By default, the balance covers the current budget window.
It can also cover an earlier budget window, chosen by a time within the window.
The balance counts the usage stored when you request it, so a request that finished moments ago can take a short time to appear. 

Each amount in a balance is a `value` and a `currency`, for example `{ "value": "499.9998412", "currency": "USD" }`.

A balance has the following fields:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`consumed`"
    description: The spend of all usage in the budget's scope during the budget window.
  - field: "`remaining`"
    description: The limit minus `consumed`. The value is negative once spend exceeds the limit.
  - field: "`projected`"
    description: |
      The spend expected by the end of the budget window at the current pace, rounded to the cent. The pace extrapolates `consumed` over the whole window from the share that has elapsed.
      The share is never counted as less than one twentieth of the window.
  - field: "`latest_record_at`"
    description: |
      When the newest usage counted in the balance reached the service. The value is `null` when no usage matches.
  - field: "`derived`"
    description: |
      For a budget with `each`, the balances of the derived budgets with the highest spend, highest first. The `size` query parameter sets how many, up to 100.
{% endtable %}
<!--vale on-->

## Notification rules

A notification rule alerts channels as a budget's spend reaches thresholds.
Each limit budget can have one rule.
A rule has thresholds, channels, and an optional custom message.
The rule sends alerts to [notification channels](/ai-cost-management/notification-channels/), which you create once and list in the rules of any budget.
A rule can list up to 10 channels.

### Thresholds

A threshold is a share of the limit, set as a whole percent from 1 to 1000.
Spend reaches a threshold when it equals or exceeds that share of the limit.
A threshold above 100 alerts on spend beyond the limit.
A threshold never blocks a request.

A rule holds up to 10 thresholds, and each threshold uses a different percent.
Each threshold triggers an alert at most once per budget window, derived budget, and limit.
When one evaluation finds several thresholds reached, only the highest sends an alert.
The lower thresholds still appear as notification events, with no deliveries.
When you change the limit, the thresholds can trigger alerts again.

When you create or replace a rule, {{site.ai_cost_management}} evaluates it right away.
A threshold that spend has already reached in the current budget window sends an alert, unless a higher threshold has already sent one.

### Custom message

By default, alerts use a standard template, which includes:
* The budget
* The threshold
* The limit
* The budget window
* The spend, with a link to the budget

To change the wording of an alert on every channel, you can set up a custom message with a subject and a body.
The subject is a single line of 1 to 200 characters.
The body is plain text of 1 to 2000 characters, and a blank line starts a new paragraph.

Both fields can contain placeholders in double curly braces, for example {% raw %}`{{budget.name}}`{% endraw %}.
{{site.ai_cost_management}} replaces each placeholder with the value for that alert. 
Monetary amounts appear in US dollars, for example `$4,125.50`.

The custom message accepts any of the following placeholders:

<!--vale off-->
{% table %}
columns:
  - title: Placeholder
    key: placeholder
  - title: Value
    key: value
rows:
  - placeholder: "`budget.name`"
    value: The budget's name.
  - placeholder: "`budget.url`"
    value: A link to the budget in {{site.konnect_short_name}}.
  - placeholder: "`threshold`"
    value: "The threshold that spend reached, like `80%`."
  - placeholder: "`limit`"
    value: "The limit that spend is measured against. With `each`, the limit of one derived budget."
  - placeholder: "`spend`"
    value: The spend so far in the budget window.
  - placeholder: "`percent`"
    value: "The spend as a share of the limit, like `82.51%`."
  - placeholder: "`remaining`"
    value: "What is left of the limit, never below `$0.00`."
  - placeholder: "`projected`"
    value: The spend expected by the end of the budget window at the current pace, as an amount and a share of the limit.
  - placeholder: "`period`"
    value: The budget window, in the time zone of its anchor.
  - placeholder: "`period.start`"
    value: When the budget window started.
  - placeholder: "`period.end`"
    value: When the budget window ends and the budget resets.
  - placeholder: "`period.remaining`"
    value: "How long is left in the budget window, like `8 days` or `3 hours`."
  - placeholder: "`entity.field`"
    value: "The `each` field as a noun: `group`, `user` for `subject`, or `env tag` for `tags.env`."
  - placeholder: "`entity.value`"
    value: The value whose derived budget reached the threshold.
{% endtable %}
<!--vale on-->

{:.info}
> **Note**: The `entity.field` and `entity.value` placeholders work only on a budget with `each`.
An unknown placeholder, or an `entity` placeholder on a budget without `each`, is rejected with an error.

#### Example custom message

The following custom message template uses placeholders for a budget that splits its limit by group:

{% raw %}
```text
Subject: [Kong Konnect] Budget "{{budget.name}}" reached {{threshold}} of its limit
Body: The {{entity.field}} {{entity.value}} used {{spend}} of its {{limit}} limit ({{percent}}), with {{period.remaining}} left in the period.
```
{:.wrap}
{% endraw %}

For example, if you have a budget named `Model spend` with an 80% threshold, the template produces this alert:

```text
[Kong Konnect] Budget "Model spend" reached 80% of its limit
The group group/example used $4,125.50 of its $5,000.00 limit (82.51%), with 5 days left in the period.
```
{:.no-copy-code}

### Notification events

A notification event records each time spend reaches a threshold for a budget.
To list events or get one by ID, use the [`/v1/ai-cost-management/notification-events` endpoints](/api/konnect/ai-cost-management/v1/#/operations/list-notification-events).

{{site.ai_cost_management}} records an event only after it has stored and evaluated the usage that reached the threshold, so an event can show up some time after the request that caused it.

The following sample event shows an 80% threshold reached by a pooled budget, with one delivery to an email channel:

```json
{
  "id": "0198c5b6-d000-7000-8000-000000000101",
  "kind": "threshold",
  "budget": {
    "id": "0198c5b6-d000-7000-8000-000000000001",
    "name": "Model spend",
    "effect": "limit",
    "labels": {},
    "scope": {
      "filters": [
        {
          "field": "provider",
          "op": "eq",
          "value": "openai"
        }
      ],
      "each": null
    },
    "priority": 100,
    "limit": {
      "currency": "USD",
      "value": "5000"
    },
    "window": {
      "type": "fixed",
      "interval": "P1M",
      "anchor": "2026-01-01T00:00:00+00:00[UTC]"
    },
    "created_at": "2026-06-01T09:00:00Z",
    "updated_at": "2026-06-01T09:00:00Z"
  },
  "threshold": {
    "percent": 80
  },
  "value": null,
  "window": {
    "start": "2026-07-01T00:00:00Z",
    "end": "2026-08-01T00:00:00Z"
  },
  "limit": {
    "currency": "USD",
    "value": "5000"
  },
  "consumed": {
    "currency": "USD",
    "value": "4031.4"
  },
  "fired_at": "2026-07-27T14:05:00Z",
  "deliveries": [
    {
      "channel": {
        "id": "0198c5b6-d000-7000-8000-000000000201",
        "name": "budget-alerts-email",
        "type": "email"
      },
      "status": "delivered",
      "error": null,
      "updated_at": "2026-07-27T14:05:02Z"
    }
  ]
}
```
{:.no-copy-code.collapsible}

The `value` field is `null` because the budget is pooled.
For a budget with `each`, `value` holds the value whose derived budget reached the threshold.
A lower threshold that didn't send an alert has the same shape, with an empty `deliveries` array.

## Set up a budget

{% navtabs "set-up-budget" %}
{% navtab "Konnect UI" %}

To create a sample budget:
1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. In the Cost Management sidebar, click **Budget Policies**.
1. Click **New budget**.
1. Click **Express** for common presets, or **Advanced** for full customization. We'll use **Express** for this example.
1. From the **Budget type** dropdown menu, select "Organization-wide".
1. In the **Spend limit** field, enter a number in USD.
1. From the **Resets** dropdown menu, select a time frame.
1. *(Optional)* From the **Notification threshold** dropdown menu, select the thresholds that send alerts.
1. *(Optional)* From the **Notify** dropdown menu, select the channels that receive alerts.
1. In the **Name** field, enter `organization-monthly-budget`.
1. Click **Create budget**.

To set the scope with filters, add labels, choose a reset anchor and time zone, set the priority, or customize the alert message, click **Advanced** instead.

To create a notification channel, see [Set up a notification channel](/ai-cost-management/notification-channels/#set-up-a-notification-channel).

{% endnavtab %}
{% navtab "Konnect API" %}

Create the [notification channels](/ai-cost-management/notification-channels/#set-up-a-notification-channel) that should receive alerts before you add a notification rule.

To create a budget, send a `POST` request to the [`/v1/ai-cost-management/budgets` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-budget). 
This budget covers all usage in your organization, with a limit of 500 US dollars for each calendar month in UTC:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/budgets
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: organization-monthly-budget
  effect: limit
  scope:
    filters: []
  limit:
    currency: USD
    value: "500"
  window:
    type: fixed
    interval: P1M
    anchor: "2026-01-01T00:00:00+00:00[UTC]"
{% endkonnect_api_request %}
<!--vale on-->

To alert a channel as spend grows, send a `PUT` request to the [`/v1/ai-cost-management/budgets/{budgetId}/notification-rule` endpoint](/api/konnect/ai-cost-management/v1/#/operations/replace-notification-rule). 
Replace `BUDGET_ID` with the `id` of the budget and `CHANNEL_ID` with the `id` of the channel, both from the create responses:

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

To use a [custom message](#custom-message) in the alerts, add `message` to the same request.
The `PUT` request replaces the whole rule, so include the thresholds and channels again:

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
  message:
    subject: '{% raw %}Budget {{budget.name}} reached {{threshold}}{% endraw %}'
    body: '{% raw %}Spend is {{spend}} ({{percent}}), with {{period.remaining}} left in the period. See {{budget.url}}.{% endraw %}'
{% endkonnect_api_request %}
<!--vale on-->

A `PUT` request can change a budget's `name`, `labels`, `priority`, `limit`, and `posture`.

The `scope` and `window` fields can't change after you create the budget.
To change either one, delete the budget and create a new one.

{% endnavtab %}
{% endnavtabs %}

## Limitations

* Budgets observe spend and send alerts. Requests continue after spend reaches the limit.
* Budget windows are fixed and aligned to an anchor.
* Limits use USD.
* A budget's scope and budget window can't change after you create it.

## Schema

{% entity_schema %}
