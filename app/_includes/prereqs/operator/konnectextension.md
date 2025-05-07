{% assign summary='Create a KonnectExtension resource' %}

{% capture details_content %}
```bash
echo '
kind: KonnectExtension
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: my-konnect-config
  namespace: default
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane' | kubectl apply -f -
```
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}