{:.info}
> The following example uses the `DataPlane` resource, but you can also configure your `GatewayConfiguration` resource as needed. For more information see the [PodTemplateSpec](/operator/dataplanes/reference/podtemplatespec/) page.

```yaml
{% if kubectl_apply %}echo '
{% endif -%}
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
  namespace: kong
spec:
  deployment:
    podTemplateSpec:
{{spec | indent: 6}}{% if kubectl_apply %}
' | kubectl apply -f -{% endif %}
```