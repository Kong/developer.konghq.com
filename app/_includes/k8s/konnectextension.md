```bash
echo '
kind: KonnectExtension
apiVersion: konnect.konghq.com/{{ site.operator_konnectextension_api_version }}
metadata:
  name: my-konnect-config
  namespace: kong
spec:{% if include.use_custom_ca %}
  clientAuth:
    certificateSecret:
      provisioning: Manual
      secretRef:
        name: konnect-client-tls{% else %}
  clientAuth:
    certificateSecret:
      provisioning: Automatic{% endif %}
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane' | kubectl apply -f -
```