Complete [Deploy {{ site.ai_gateway_name }} with {{site.operator_product_name}}](/operator/get-started/ai-gateway/deploy/) with the deployment toggle set to **konnect**.

Confirm that the data plane is ready and the AI Model is programmed:

```bash
kubectl get aigatewaydataplane/my-ai-gateway-dp aigatewaymodel/gpt-4o-mini -n kong
```

{% include md/operator/ai-gateway/prereqs/aigw-host.md %}
