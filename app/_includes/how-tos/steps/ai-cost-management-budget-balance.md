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
