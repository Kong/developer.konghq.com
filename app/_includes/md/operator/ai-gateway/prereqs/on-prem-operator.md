Complete [Install {{site.operator_product_name}} for {{ site.ai_gateway_name }}](/operator/get-started/ai-gateway/install/) with the deployment toggle set to **on-prem**.

Confirm that the `OnPremAIGateway` controller is enabled. The command prints `true`:

```bash
kubectl get deployment -n kong-system kong-operator-kong-operator-controller-manager \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KONG_OPERATOR_ENABLE_CONTROLLER_ONPREMAIGATEWAY")].value}'
```

Confirm that the `KongLicense` is applied. The command prints `True`:

```bash
kubectl get konglicense kong-license \
  -o jsonpath='{.status.controllers[0].conditions[?(@.type=="Programmed")].status}'
```
