You'll switch the mesh into Exclusive mode, assign a custom-trust-domain SPIFFE identity to the `flight-control` workload, declare the trust bundle that issues those certs, and finally enforce strict mTLS.

### Step 1: Switch the mesh to Exclusive mode

`MeshIdentity` requires `meshServices.mode: Exclusive`. The `Mesh` resource is Global CP–only.

{% navtabs "mesh-exclusive" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
  mtls:
    backends:
      - name: builtin
        type: builtin
    enabledBackend: builtin' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

This disables legacy `kuma.io/service`-tag identity and prepares the mesh to use `MeshIdentity` resources.

### Step 2: Create the CA Secrets that back the new identity

In a real deployment you'd come from a corporate Root CA. For this exercise, generate a self-signed pair and store it in the system namespace:

```bash
openssl req -x509 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 365 -nodes \
  -subj "/CN=kong-air-flight-ops-ca"

kubectl create secret generic kong-air-ca-cert \
  -n kong-mesh-system --from-file=ca.crt
kubectl create secret generic kong-air-ca-key \
  -n kong-mesh-system --from-file=ca.key
```

### Step 3: Apply a `MeshIdentity` for flight-control

The selector matches every sidecar labelled `app: flight-control`. The SPIFFE ID template injects the namespace and workload name into a custom trust domain (`internal.kongair.com`).

{% warning %}
`MeshIdentity` must be applied to the **system namespace** on Kubernetes. Apply it to an application namespace and the resource is silently ignored.
{% endwarning %}

{% navtabs "mesh-identity-apply" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: flight-operations-id
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-key
  spiffeID:
    trustDomain: internal.kongair.com
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshIdentity
name: flight-operations-id
mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: flight-control
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-cert
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: kong-air-ca-key
  spiffeID:
    trustDomain: internal.kongair.com
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 4: Confirm the new identity on a sidecar

Look at the actual SPIFFE ID a `flight-control` sidecar is now presenting:

```bash
POD=$(kubectl get pod -n kong-air-production -l app=flight-control -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$POD" -c kuma-sidecar -- \
  openssl s_client -connect 127.0.0.1:5680 -showcerts </dev/null 2>/dev/null \
  | openssl x509 -noout -ext subjectAltName
```

You should see:

```
X509v3 Subject Alternative Name:
    URI:spiffe://internal.kongair.com/kong-air-production/flight-control
```

Not the legacy `spiffe://default/flight-control_kong-air-production_svc_8080` from Fundamentals — the new custom trust domain and templated path.

### Step 5: Declare the trust bundle with `MeshTrust`

Tell the mesh that the `internal.kongair.com` trust domain is signed by the CA you just deployed:

{% navtabs "mesh-trust-apply" %}
{% navtab "Kubernetes" %}
```bash
CA_PEM=$(cat ca.crt)

echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: kong-air-trust
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
${CA_PEM}" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
CA_PEM=$(cat ca.crt)

echo "type: MeshTrust
name: kong-air-trust
mesh: default
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
${CA_PEM}" | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 6: Move the mesh from Permissive to Strict

With the new identity in place and trusted, you can promote the mesh from Permissive to Strict mTLS for the affected workloads:

{% navtabs "mesh-tls-strict" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: strict-mtls
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    mode: Strict' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTLS
name: strict-mtls
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    mode: Strict' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Any non-mTLS request now gets rejected at the destination sidecar. Confirm by inspecting recent access logs (from Step 1's `MeshAccessLog`) — you shouldn't see entries with `status: 0` (connection-time rejections) once the rollout completes.

### Step 7: Roll back to permissive if needed

If something downstream isn't ready, you can quickly relax enforcement without removing identities:

```bash
kubectl patch meshtls strict-mtls -n kong-mesh-system --type=merge \
  -p '{"spec":{"default":{"mode":"Permissive"}}}'
```

The new identities and trust bundles stay in place; only the wire-level enforcement drops back to permissive.

### What you did

- Switched the mesh into `meshServices.mode: Exclusive` to enable `MeshIdentity`.
- Provisioned a self-signed Kong Air CA in `kong-mesh-system` and assigned it to `flight-control` via `MeshIdentity` — producing the custom SPIFFE ID `spiffe://internal.kongair.com/kong-air-production/flight-control`.
- Declared the new CA as trusted via `MeshTrust`.
- Promoted enforcement to `MeshTLS: Strict`.

In Step 3 you'll replace the self-signed CA with a proper enterprise PKI integration — HashiCorp Vault, cert-manager, or AWS ACM Private CA.
