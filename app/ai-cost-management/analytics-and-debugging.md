---
title: "Analytics and debugging in {{site.ai_cost_management}}"
content_type: reference
layout: reference

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

description: "The analytics views in {{site.ai_cost_management}} show where AI spend goes and what the gateway reported for each request."

api_specs:
  - konnect/ai-cost-management

related_resources:
  - text: "{{site.ai_cost_management}}"
    url: /ai-cost-management/
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/
  - text: Price catalog and overrides
    url: /ai-cost-management/price-catalog/
  - text: "{{site.ai_cost_management}} API reference"
    url: /api/konnect/ai-cost-management/

faqs:
  - q: Why is the cost of my request $0?
    a: |
      A usage event has a cost of $0 when the model had no price at the time of the request, because {{site.ai_cost_management}} stores an omitted cost as zero.
      If the request reported tokens, the event counts toward unpriced calls.

      To fix it, check the following:

      * Check that the model has a price in the [price catalog](/ai-cost-management/price-catalog/).
      * Check if the AI Model target has any cost management settings. If even one target cost management setting is configured, {{site.ai_gateway}} prices the request from the target's settings only. See [How a request is priced](/ai-cost-management/price-catalog/#how-a-request-is-priced).
      * Check when the request ran. An event keeps the cost that the gateway reported, so send a new request after you add a price.

  - q: Why does a usage event show as `unattributed`?
    a: |
      A usage event is unattributed when {{site.ai_gateway}} recorded no accepted identity for the request, so the event has no user.
      The Dashboard includes this spend in Unattributed spend, and the Events debugger shows an `unattributed` badge on the event.
      A new request is attributed after you fix the identity setup, and earlier events stay unattributed.

  - q: Why did a total change after I looked at it?
    a: |
      {{site.ai_cost_management}} groups spend by the time of the usage event, and an event can arrive after its time has passed.
      An event is late when it reaches {{site.ai_cost_management}} more than one hour after its time, and a late event changes the total of a period you have already viewed.
      To find late events, filter the Events debugger by [**Arrival**](/ai-cost-management/analytics-and-debugging/#filters-and-dimensions) or use the `arrival` filter in the [usage events API](/api/konnect/ai-cost-management/v1/#/operations/list-usage-events).
---

{{site.ai_cost_management}} records the cost of each AI request that passes through {{site.ai_gateway}} as a usage event.
If you need to see where AI spend goes, or check what the gateway reported for a request, you can use the Cost management views in {{site.konnect_short_name}}.

* My Usage shows the current user's own spend and projection
* The Dashboard summarizes organization-wide spend and projects it to the end of the month
* The Explorer breaks spend and usage down by any dimension
* The Events debugger lists the individual usage events

The views read stored usage events, so a request can take a short time to appear after it finishes.
All times in the console are in UTC.

The Dashboard chart and breakdown update every minute, and **Refresh** reloads every section.

An event is late when it reaches {{site.ai_cost_management}} more than one hour after its time.
{{site.ai_cost_management}} groups spend by the time of the event, so a late event changes the total for a period you've already viewed.

## How the views relate

The views read the same usage events, and each answers a different question:

<!--vale off-->
{% table %}
columns:
  - title: View
    key: view
  - title: What it shows
    key: shows
  - title: When to use it
    key: use
  - title: Access
    key: access
rows:
  - view: "[**My usage**](#my-usage)"
    shows: "The current user's spend, projection, and spend breakdown."
    use: "To check your own spend and see how it compares with your budget."
    access: "Individual, Team manager, Admin"
  - view: "[**Dashboard**](#dashboard)"
    shows: "Organization-wide spend, projected spend, budget status, and spend grouped by user, group, team, provider, model, harness, or tag."
    use: "To check overall spend, find where it goes, and see which budgets are close to their limits."
    access: "Team manager, Admin"
  - view: "[**Explorer**](#explorer)"
    shows: "Spend, requests, or tokens over time, grouped by up to two dimensions."
    use: "To answer a specific question, for example which model costs the most each day."
    access: "Team manager, Admin"
  - view: "[**Events debugger**](#events-debugger)"
    shows: "The individual usage events, with their cost, tokens, user, and model."
    use: "To check what the gateway reported for a request, or to find out why a cost or a user is missing."
    access: "Admin"
{% endtable %}
<!--vale on-->

## My usage

My Usage shows the current user's own spend. It's available to all {{site.ai_gateway}} users.

The view shows spend for a selected time range, a projection for the current month, and how far spend is above or below the user's budget ceiling.
Spend is also broken down by dimension, for example a model or provider.

<!--TO DO: screenshot-->

## Dashboard

The Dashboard summarizes spend for a time range and shows where it goes.

<!--vale off-->
{% table %}
columns:
  - title: Topic
    key: topic
  - title: What it shows
    key: shows
rows:
  - topic: "**Spend over time**"
    shows: |
      Cumulative spend for the selected time range, compared with the previous period when one exists. 
      For the current month, the chart also shows projected spend and the spending ceiling.
      <br><br>
      Unpriced calls (requests that reported tokens but have a cost of zero) are tracked separately from total spend.
  - topic: "**Projection**"
    shows: |
      Predicted spend for the current UTC month and how far it is above or below the ceiling, regardless of the time range you select.
      * The ceiling is the limit set by an organization-wide monthly budget.
      * The projection is an estimate and requires at least two completed days of usage. See [Budgets](/ai-cost-management/budgets/).
  - topic: "**Where spend goes**"
    shows: |
      Spend broken down by a primary dimension, with an optional secondary dimension.
      You can group by users, groups, teams, providers, models, harnesses, or tags.
      Usage with no user appears as **Unattributed**. 
      <br><br>
      When you group by Groups, shares can add up to more than 100% because an event counts under each of its groups.
  - topic: "**Budgets at risk**"
    shows: |
      Each budget ranked by the share of its limit that spend has consumed. See [Budgets](/ai-cost-management/budgets/).
{% endtable %}
<!--vale on-->

<!--TO DO: screenshot-->

## Explorer

The Explorer shows spend, requests, or tokens over time for any combination of filters and group-by dimensions.

<!--vale off-->
{% table %}
columns:
  - title: Control
    key: control
  - title: What it does
    key: does
rows:
  - control: "**Group by**"
    does: "One or two dimensions to split the results by."
  - control: "**Add filter**"
    does: "Narrows the events. See [Filters and dimensions](#filters-and-dimensions)."
  - control: "**Time range**"
    does: "The same presets as the Dashboard."
  - control: "**Granularity**"
    does: "The size of each chart bucket: hour, day, week, or month. The default is Day."
  - control: "**Measure**"
    does: "What the chart plots: Spend, Requests, Input tokens, or Output tokens."
{% endtable %}
<!--vale on-->

The chart shows stacked bars, one series for each of the ten largest groups and an Other series for the rest.
The group table title includes the dimension, for example **Spend by User**, and lists each group with its share, spend, requests, and tokens.
Usage with no user appears with an **unattributed** badge.
The [query endpoint](/api/konnect/ai-cost-management/v1/#/operations/query-usage-events) (`POST /v1/ai-cost-management/events/query`) supports the same grouping and filtering.

<!--TO DO: screenshot-->

## Events debugger

The Events debugger lists the individual usage events in the time range, newest first.
You can narrow the list with filters. See [Filters and dimensions](#filters-and-dimensions).

You can select a row to open the **Usage event** panel, which shows the full event details.

Here's what a sample event might look like. 
For the full schema, see the [`/v1/ai-cost-management/events` API reference](/api/konnect/ai-cost-management/v1/#/operations/list-usage-events).

```json
{
  "specversion": "1.0",
  "type": "ai.usage.v1",
  "source": "//control-planes/7c4d8e9f-a1b2-c3d4-e5f6-789012345678",
  "id": "req-abc123def456/inv-xyz789ghi012",
  "subject": "principal/9a8b7c6d-5e4f-3a2b-1c0d-ef9876543210",
  "time": "2026-10-30T14:23:11.042Z",
  "data": {
    "quantities": {
      "input_text_tokens": "1834",
      "input_cache_read_tokens": "512",
      "output_text_tokens": "402"
    },
    "reported_cost": { "value": "0.004372", "currency": "USD" },
    "reported_cache_cost": { "value": "0.000512", "currency": "USD" },
    "context": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-6",
      "model_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "request_mode": "stream",
      "region": "us-east-1",
      "client": "claude_code"
    },
    "provenance": {
      "request_id": "req-abc123def456",
      "service_id": "b3c4d5e6-f7a8-b9c0-d1e2-f3a4b5c6d7e8",
      "route_id": "c4d5e6f7-a8b9-c0d1-e2f3-a4b5c6d7e8f9",
      "consumer_id": "d5e6f7a8-b9c0-d1e2-f3a4-b5c6d7e8f9a0",
      "plugin_id": "e6f7a8b9-c0d1-e2f3-a4b5-c6d7e8f9a0b1",
      "plugin_name": "ai-proxy-advanced"
    },
    "tags": {
      "project": "payments-api",
      "environment": "production"
    },
    "groups": ["principal/f7a8b9c0-d1e2-f3a4-b5c6-d7e8f9a0b1c2"]
  }
}
```
{:.collapsible}

## Filters and dimensions

The Explorer, the Events debugger, and the [usage events API](/api/konnect/ai-cost-management/v1/) filter events using the same fields.
An event must match every filter you add.

<!--vale off-->
{% table %}
columns:
  - title: Filter
    key: filter
  - title: Field
    key: field
  - title: What it matches
    key: matches
  - title: Operators
    key: operators
rows:
  - filter: "Provider"
    field: "`provider`"
    matches: "The AI provider that served the request."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`"
  - filter: "Model"
    field: "`model`"
    matches: "The model that the provider reports as served."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`"
  - filter: "User"
    field: "`subject`"
    matches: "The subject accountable for the usage, for example `principal/{uuid}`, `consumer/{uuid}`, or `oidc/{sub}`. An unattributed event has no subject."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`, `exists`, `nexists`"
  - filter: "Request mode"
    field: "`request_mode`"
    matches: "How the request was served: `stream`, `oneshot`, or `realtime`."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`"
  - filter: "Harness"
    field: "`client`"
    matches: "The client that sent the request, as the producer reported it."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`"
  - filter: "Source"
    field: "`source`"
    matches: "The producer of the usage event: a gateway's control plane, as `control-planes/{uuid}`, or a principal that reported usage."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`"
  - filter: "Service"
    field: "`service_id`"
    matches: "The ID of the gateway service that handled the request."
    operators: "`eq`, `neq`, `oeq`"
  - filter: "Route"
    field: "`route_id`"
    matches: "The ID of the gateway route that handled the request."
    operators: "`eq`, `neq`, `oeq`"
  - filter: "Consumer"
    field: "`consumer_id`"
    matches: "The ID of the consumer that sent the request."
    operators: "`eq`, `neq`, `oeq`"
  - filter: "Application"
    field: "`application_id`"
    matches: "The ID of the application that sent the request."
    operators: "`eq`, `neq`, `oeq`"
  - filter: "Consumer groups"
    field: "`consumer_group_ids`"
    matches: "The IDs of the consumer groups that the consumer belongs to."
    operators: "`eq`, `oeq`"
  - filter: "Groups"
    field: "`groups`"
    matches: "The groups that the usage belongs to, as group references, for example `principal/{uuid}` or `oidc/{group}`."
    operators: "`eq`, `oeq`"
  - filter: "Teams"
    field: "`teams`"
    matches: "The teams the usage belongs to."
    operators: "`eq`, `oeq`"
  - filter: "Tag"
    field: "`tags.<key>`"
    matches: "The value of one tag on the event. The tag key is part of the field name, as `tags.<key>`."
    operators: "`eq`, `neq`, `oeq`, `contains`, `ocontains`, `exists`, `nexists`"
{% endtable %}
<!--vale on-->

The Events debugger has additional filters. In the API, these are available on the [list endpoint](/api/konnect/ai-cost-management/v1/#/operations/list-usage-events) only.

<!--vale off-->
{% table %}
columns:
  - title: Filter
    key: filter
  - title: Field
    key: field
  - title: What it matches
    key: matches
  - title: Operators
    key: operators
rows:
  - filter: "Price"
    field: "`reported_cost`"
    matches: "The cost of the event, compared with an amount in US dollars."
    operators: "`eq`, `gt`, `gte`, `lt`, `lte`"
  - filter: "Arrival"
    field: "`arrival`"
    matches: "Whether the event arrived `late` or `on_time`. An event is late when it reaches {{site.ai_cost_management}} more than one hour after its time."
    operators: "`eq`, `neq`, `oeq`"
  - filter: "Token usage"
    field: "`tokens`"
    matches: "Whether the event reported a positive quantity of any token kind."
    operators: "`exists`, `nexists`"
{% endtable %}
<!--vale on-->

## Troubleshoot missing or wrong data

The following table lists common symptoms in the views and what to check:

<!--vale off-->
{% table %}
columns:
  - title: Symptom
    key: symptom
  - title: Likely cause
    key: cause
  - title: What to check
    key: check
rows:
  - symptom: "No events appear"
    cause: "Only successful gateway requests become usage events. Failed or canceled requests produce no event."
    check: "Send a request that returns a successful response, wait a short time, and select **Refresh**."
  - symptom: "An event has a cost of $0"
    cause: "The model had no price when the request ran, and {{site.ai_cost_management}} stores an omitted cost as zero."
    check: "Check the model's price in the [price catalog](/ai-cost-management/price-catalog/), then send a new request. The Unpriced calls card counts these events."
  - symptom: "A user shows as unattributed"
    cause: "{{site.ai_gateway}} recorded no accepted identity for the request."
    check: "Check that the request used a supported credential, for example a consumer, a principal, or an OIDC token. New requests are attributed, and earlier events stay unattributed."
  - symptom: "A total changed after you viewed it"
    cause: "A late event arrived for a period that you already viewed."
    check: "In the Events debugger, filter by [**Arrival**](#filters-and-dimensions) to find late events."
  - symptom: "Group shares add up to more than 100%"
    cause: "Grouping by Groups counts an event under each of its groups."
    check: "Group by another dimension to see shares that add up to 100%."
{% endtable %}
<!--vale on-->

## Query usage data with the API

You can also use the [events API](/api/konnect/ai-cost-management/v1/#/operations/list-usage-events) to query usage.
A query can group by up to two dimensions and span up to 400 buckets.

To list the usage events that arrived late, send a `GET` request to the [`/v1/ai-cost-management/events` endpoint](/api/konnect/ai-cost-management/v1/#/operations/list-usage-events) with the [`arrival`](#filters-and-dimensions) filter set to `late`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/events?filter%5Barrival%5D=late
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

To total the cost and the unpriced requests for each provider and day of a month, send a `POST` request to the [`/v1/ai-cost-management/events/query` endpoint](/api/konnect/ai-cost-management/v1/#/operations/query-usage-events):

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/events/query
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  from: "2026-10-01T00:00:00Z"
  to: "2026-11-01T00:00:00Z"
  granularity: P1D
  dimensions:
    - provider
  measures:
    - reported_cost
    - unpriced_events
{% endkonnect_api_request %}
<!--vale on-->

Each group in the response has its `dimensions` and its `measures`, and a `series` of buckets when you set a `granularity`.

An event with no value for a dimension appears in the `null` group for that dimension, so unattributed usage is the `null` group of `subject`.

