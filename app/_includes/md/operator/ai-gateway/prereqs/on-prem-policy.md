Complete [Apply AI Policies with {{site.operator_product_name}}](/operator/get-started/ai-gateway/policy/) with the deployment toggle set to **on-prem**.

Confirm that the `OnPremAIGateway` is ready and the AI Policy is programmed:

```bash
kubectl get onpremaigateway/my-ai-gateway-cp aigatewaypolicy/content-guardrails -n kong
```

{% include md/operator/ai-gateway/prereqs/aigw-host.md %}
