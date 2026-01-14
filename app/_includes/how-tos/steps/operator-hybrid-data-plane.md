## Create the data plane

Configure a Kong `DataPlane` by using your `KonnectExtension` reference:

```bash
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
  namespace: kong
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
' | kubectl apply -f -
```

## Check the Ready status

<!-- vale off -->
{% validation kubernetes-resource %}
kind: DataPlane
name: dataplane-example
conditionType: Ready
reason: Ready
{% endvalidation %}
<!-- vale on -->

If the `DataPlane` has `Ready` condition set to `True` then you can visit {{site.konnect_short_name}} and see the dataplane in the list of connected data planes for your control plane.