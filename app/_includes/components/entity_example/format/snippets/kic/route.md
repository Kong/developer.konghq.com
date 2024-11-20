Routes are defined using native Kubernetes resources such as `Ingress` and `HTTPRoute`. This example uses HTTPRoute, but you can also use `Ingress` if needed. See the [{{site.kic_product_name}}](https://docs.konghq.com/kubernetes-ingress-controller/latest/guides/services/http/) documentation for Ingress docs.

To create a route in {{site.base_gateway}}, create a `HTTPRoute` resource that points to a service in your cluster:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include.presenter.data.name }}
  annotations:
    konghq.com/strip-path: 'true'
spec:
  parentRefs:
  - name: kong
  rules:
  - matches:
    {%- for path in include.presenter.data.paths %}
    - path:
        type: PathPrefix
        value: {{ path }}{%- endfor %}
    backendRefs:
    - name: {{ include.presenter.data.name }}-demo-service
      kind: Service
      port: 1027
```
