Add a notification rule to the budget using the [`/v1/ai-cost-management/budgets/{budgetId}/notification-rule` endpoint](/api/konnect/ai-cost-management/v1/#/operations/replace-notification-rule).

The rule alerts the {{include.channel}} channel when spend reaches 50, 80, and 100 percent of the limit.
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
