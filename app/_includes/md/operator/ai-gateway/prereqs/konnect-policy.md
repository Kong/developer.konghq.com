Complete [Apply AI Policies with {{site.operator_product_name}}](/operator/get-started/ai-gateway/policy/) with the deployment toggle set to **konnect**.

Confirm that the AI Policy is programmed:

```bash
kubectl get aigatewaypolicy/content-guardrails -n kong
```

{% include md/operator/ai-gateway/prereqs/aigw-host.md %}
