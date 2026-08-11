{% assign ns = include.namespace | default: "kong" %}
{% assign issuer_name = include.issuer_name | default: "selfsigned-issuer" %}
The `Issuer` resource represents the certificate authority that signs your certificates. Create a self-signed issuer in the `{{ ns }}` namespace:

```bash
echo '
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: {{ issuer_name }}
  namespace: {{ ns }}
spec:
  selfSigned: {}' | kubectl apply -f -
```

{:.info}
> A self-signed issuer keeps this guide self-contained. In production, use an ACME issuer such as Let's Encrypt, or a CA issuer. For all issuer types, see the [cert-manager configuration documentation](https://cert-manager.io/docs/configuration/).
