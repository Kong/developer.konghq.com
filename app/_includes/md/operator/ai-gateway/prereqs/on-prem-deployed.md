Complete [Deploy {{ site.ai_gateway_name }} with {{site.operator_product_name}}](/operator/get-started/ai-gateway/deploy/) with the deployment toggle set to **on-prem**.

Confirm that the control plane and data plane are ready, and that the AI Model is programmed:

```bash
kubectl get onpremaigateway/my-ai-gateway-cp aigatewaydataplane/my-ai-gateway-dp aigatewaymodel/gpt-4o-mini -n kong
```

The `READY` column shows `True` for the `OnPremAIGateway` and the `AIGatewayDataPlane`, and the `PROGRAMMED` column shows `True` for the `AIGatewayModel`.

{% include md/operator/ai-gateway/prereqs/aigw-host.md %}
