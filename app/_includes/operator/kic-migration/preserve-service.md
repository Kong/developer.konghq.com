To keep the proxy Service and its address when you uninstall {{ site.kic_product_name_short }}, add the `helm.sh/resource-policy: keep` annotation to your existing Helm values.
This way, Helm records the annotation in the release manifest.
Use the tab for your installed chart.

{% navtabs "kic-chart" %}
{% navtab "`kong` chart" %}

Merge this setting into your existing `values.yaml`:

```yaml
proxy:
  annotations:
    helm.sh/resource-policy: keep
```

Apply the change:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/kong --version "${KIC_CHART_VERSION}" -f values.yaml
```

{% endnavtab %}
{% navtab "`ingress` chart" %}

Merge this setting into your existing `values.yaml`:

```yaml
gateway:
  proxy:
    annotations:
      helm.sh/resource-policy: keep
```

Apply the change:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/ingress --version "${KIC_CHART_VERSION}" -f values.yaml
```

{% endnavtab %}
{% endnavtabs %}

Check that the Service has the `helm.sh/resource-policy: keep` annotation:

```bash
kubectl get svc -n "$NAMESPACE" "$PROXY_SERVICE" -o yaml
```

Add the retained Service to the manifests you maintain.
If you use GitOps, make sure that it preserves this Service and the selector you set during cutover.
