{% assign type = include.type %}

{% if type == "dataplane" %}
{% assign key_name_format = "dataplane-token-signing-key-{mesh}-{serialNumber}" %}
{% assign kube_secret_type = "system.kuma.io/secret" %}
{% assign regen_step = "Regenerate tokens. New tokens are automatically signed with the key that has the highest serial number, so they use the new signing key." %}
{% capture check_universal %}
```sh
kumactl get secrets
MESH      NAME                                    AGE
default   dataplane-token-signing-key-default-1   49s
```
{% endcapture %}
{% capture check_kube %}
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/secret'
NAME                                 TYPE                    DATA   AGE
dataplane-token-signing-key-mesh-1   system.kuma.io/secret   1      25m
```
{% endcapture %}
{% capture create_universal %}
```sh
echo "
type: Secret
mesh: default
name: dataplane-token-signing-key-default-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endcapture %}
{% capture create_kube %}
```sh
TOKEN="$(kumactl generate signing-key)" && echo "
apiVersion: v1
data:
  value: $TOKEN
kind: Secret
metadata:
  name: dataplane-token-signing-key-mesh-2
  namespace: {{site.mesh_namespace}}
type: system.kuma.io/secret
" | kubectl apply -f -
```
{% endcapture %}
{% capture delete_universal %}
```sh
kumactl delete secret dataplane-token-signing-key-default-1 --mesh=default
```
{% endcapture %}
{% capture delete_kube %}
```sh
kubectl delete secret dataplane-token-signing-key-default-1 -n {{site.mesh_namespace}}
```
{% endcapture %}
{% endif %}

{% if type == "zone" %}
{% assign key_name_format = "zone-token-signing-key-{serialNumber}" %}
{% assign kube_secret_type = "system.kuma.io/global-secret" %}
{% assign regen_step = "[Generate new tokens](#generate-a-zone-token). New tokens are generated with the signing key with the highest serial number." %}
{% capture check_universal %}
```sh
kumactl get global-secrets
NAME                       AGE
zone-token-signing-key-1   36m
```
{% endcapture %}
{% capture check_kube %}
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
NAME                       TYPE                           DATA   AGE
zone-token-signing-key-1   system.kuma.io/global-secret   1      25m
```
{% endcapture %}
{% capture create_universal %}
```sh
echo "
type: GlobalSecret
name: zone-token-signing-key-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endcapture %}
{% capture create_kube %}
```sh
TOKEN="$(kumactl generate signing-key)" && echo "
apiVersion: v1
data:
  value: $TOKEN
kind: Secret
metadata:
  name: zone-token-signing-key-2
  namespace: {{site.mesh_namespace}}
type: system.kuma.io/global-secret
" | kubectl apply -f -
```
{% endcapture %}
{% capture delete_universal %}
```sh
kumactl delete global-secret zone-token-signing-key-1
```
{% endcapture %}
{% capture delete_kube %}
```sh
kubectl delete secret zone-token-signing-key-1 -n {{site.mesh_namespace}}
```
{% endcapture %}
{% endif %}

{% if type == "user" %}
{% assign key_name_format = "user-token-signing-key-{serialNumber}" %}
{% assign kube_secret_type = "system.kuma.io/global-secret" %}
{% assign regen_step = "[Generate new tokens](#generate-user-tokens). New tokens are generated with the signing key that has the highest serial number." %}
{% capture check_universal %}
```sh
kumactl get global-secrets
NAME                       AGE
user-token-signing-key-1   36m
```
{% endcapture %}
{% capture check_kube %}
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
NAME                       TYPE                           DATA   AGE
user-token-signing-key-1   system.kuma.io/global-secret   1      25m
```
{% endcapture %}
{% capture create_universal %}
```sh
echo "
type: GlobalSecret
name: user-token-signing-key-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endcapture %}
{% capture create_kube %}
```sh
TOKEN="$(kumactl generate signing-key)" && echo "
apiVersion: v1
data:
  value: $TOKEN
kind: Secret
metadata:
  name: user-token-signing-key-2
  namespace: {{site.mesh_namespace}}
type: system.kuma.io/global-secret
" | kubectl apply -f -
```
{% endcapture %}
{% capture delete_universal %}
```sh
kumactl delete global-secret user-token-signing-key-1
```
{% endcapture %}
{% capture delete_kube %}
```sh
kubectl delete secret user-token-signing-key-1 -n {{site.mesh_namespace}}
```
{% endcapture %}
{% endif %}

If the signing key is compromised, you must rotate it. You must also rotate all the tokens that were signed by it.

1. Generate a new signing key.
   The signing key is stored as a secret named in the following format: `{{ key_name_format }}`.

   When generating a new signing key, assign it a serial number greater than the current key's serial number.

   {% capture navtabbed_content %}
   {% navtabs "Environment" %}
   {% navtab "Kubernetes" %}
   Get the current key's serial number:
   {{ check_kube }}

   In this example, the highest serial number is `1`.

   Generate a new signing key with a serial number of `2`:
   {{ create_kube }}
   {% endnavtab %}
   {% navtab "Universal" %}
   Get the current key's serial number:
   {{ check_universal }}

   In this example, the highest serial number is `1`.

   Generate a new signing key with a serial number of `2`:
   {{ create_universal }}
   {% endnavtab %}
   {% endnavtabs %}
   {% endcapture %}
   {{ navtabbed_content | indent }}

2. {{ regen_step }}
   At this point, tokens signed by either the new or old signing key are valid.

3. Remove the old signing key.
   {% capture navtabbed_content %}
   {% navtabs "Environment" %}
   {% navtab "Kubernetes" %}
   {{ delete_kube }}
   {% endnavtab %}
   {% navtab "Universal" %}
   {{ delete_universal }}
   {% endnavtab %}
   {% endnavtabs %}
   {% endcapture %}
   {{ navtabbed_content | indent }}
   All new connections to the control plane now require tokens signed with the new signing key.
