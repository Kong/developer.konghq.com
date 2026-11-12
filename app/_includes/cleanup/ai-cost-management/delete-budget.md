Delete the budget you created:

```bash
curl -X DELETE "$KONNECT_CONTROL_PLANE_URL/v1/ai-cost-management/budgets/$BUDGET_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```
{: data-test-cleanup="block" }
