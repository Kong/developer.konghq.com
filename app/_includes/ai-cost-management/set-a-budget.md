A [budget](/ai-cost-management/budgets/) in {{site.ai_cost_management}} tracks spend against a limit and alerts you as spend grows.

Create a monthly budget with a $100 limit:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/budgets
method: POST
status_code: 201
body:
  name: monthly-org-budget
  effect: limit
  scope:
    filters: []
  limit:
    value: "100"
    currency: USD
  window:
    type: fixed
    interval: P1M
    anchored_at: "2026-01-01T00:00:00+00:00[UTC]"
extract_body:
  - name: id
    variable: BUDGET_ID
capture:
  - variable: BUDGET_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `scope.filters` empty array means this budget covers all organization-wide usage.
