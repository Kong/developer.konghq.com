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
