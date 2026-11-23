Update the Kong Helm repository:

```bash
helm repo update kong
```

Install {{ site.operator_product_name_short }} alongside your existing installation:

```bash
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --take-ownership \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set ko-crds.enabled=true \
  --set global.webhooks.conversion.enabled=true \
  --set global.webhooks.options.certManager.enabled=true
```

Check that the {{ site.operator_product_name_short }} pods are running:

```bash
kubectl get pods -n kong-system
```

Complete any {{ site.operator_product_name }} upgrades before cutover.
Avoid {{ site.operator_product_name }} restarts while you change routing resources.
