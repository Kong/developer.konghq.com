{% assign type = include.type %}

{% if type == "dataplane" %}
{% assign revocation_secret = "dataplane-token-revocations-default" %}
{% assign kube_secret_type = "system.kuma.io/secret" %}
{% capture universal_snippet %}
```sh
echo "
type: Secret
mesh: default
name: dataplane-token-revocations-default
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endcapture %}
{% endif %}

{% if type == "zone" %}
{% assign revocation_secret = "zone-token-revocations" %}
{% assign kube_secret_type = "system.kuma.io/global-secret" %}
{% capture universal_snippet %}
```sh
echo "
type: GlobalSecret
name: zone-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endcapture %}
{% endif %}

{% if type == "user" %}
{% assign revocation_secret = "user-token-revocations" %}
{% assign kube_secret_type = "system.kuma.io/global-secret" %}
{% capture universal_snippet %}
```sh
echo "
type: GlobalSecret
name: user-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endcapture %}
{% endif %}

{{site.mesh_product_name}} doesn't keep a list of issued tokens. Whenever a single token is compromised, you can add it to the revocation list to invalidate it.

Every token has its own ID under the `jti` key. You can extract the ID from the token using [jwt.io](https://jwt.io) or the [`jwt-cli`](https://www.npmjs.com/package/jwt-cli) tool.

{% if type == "dataplane" %}
{% new_in 2.10 %} Authentication between the control plane and data planes is only checked at connection start. This means revoking a token after a data plane connects does not terminate the existing connection. The recommended action on token revocation is to restart either the control plane or the affected data planes.
{% endif %}

To revoke tokens, specify a comma-separated list of revoked IDs in a secret named `{{ revocation_secret }}`.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
REVOCATIONS=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) && echo "apiVersion: v1
kind: Secret
metadata:
  name: {{ revocation_secret }}
  namespace: {{site.mesh_namespace}}
data:
  value: $REVOCATIONS
type: {{ kube_secret_type }}" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
{{ universal_snippet }}
{% endnavtab %}
{% endnavtabs %}
