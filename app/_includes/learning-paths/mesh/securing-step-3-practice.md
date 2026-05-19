You'll wire up three of the four external-CA backends — cert-manager, Vault, and a Bundled external CA — and then walk through the rotation steps you'd take to migrate a real mesh between them.

You don't need a real Vault or AWS account to read along; the resources are valid YAML you can apply against a dev mesh by pointing them at a Vault dev server or a cert-manager Issuer.

### Option A: cert-manager (the simple case)

Assume you already have cert-manager installed and a `ClusterIssuer` named `corporate-issuer` (this is the cluster admin's job, not the mesh operator's).

{% navtabs "cm-backend" %}
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
    enabledBackend: cert-manager-ca
    backends:
      - name: cert-manager-ca
        type: cert-manager
        certManager:
          issuerName: corporate-issuer
          issuerKind: ClusterIssuer' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: cert-manager-ca
  backends:
    - name: cert-manager-ca
      type: cert-manager
      certManager:
        issuerName: corporate-issuer
        issuerKind: ClusterIssuer' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

That's it. The CP starts requesting certs from cert-manager on every identity rotation.

### Option B: Vault with `fromCp`

A few setup steps are needed inside Vault first. These would typically be done by the platform team during onboarding:

```bash
# 1. Enable the PKI engine
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki

# 2. Generate a root CA (or import an existing one)
vault write -field=certificate pki/root/generate/internal \
  common_name="kong-air-mesh-ca" ttl=87600h

# 3. Create a role the CP will use
vault write pki/roles/mesh-dp \
  allowed_domains="mesh,internal.kongair.com" \
  allow_subdomains=true \
  max_ttl="24h"

# 4. Create a token (or a K8s auth role) the CP will use
vault token create -policy=mesh-dp -ttl=8760h
```

Stash the token in a Kubernetes secret:

```bash
kubectl create secret generic vault-token \
  -n kong-mesh-system --from-literal=value=<token>
```

Now point the mesh at Vault. Note both `fromCp` and `dpCert.rotation.expiration` — both required, both for the reasons in the Learn section.

{% navtabs "vault-backend" %}
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
    enabledBackend: vault-ca
    backends:
      - name: vault-ca
        type: vault
        dpCert:
          rotation:
            expiration: 1d
        conf:
          fromCp:
            address: https://vault.default:8200
            role: mesh-dp
            auth:
              token:
                secret: vault-token
            tls:
              caCert:
                secret: vault-ca-cert' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: vault-ca
  backends:
    - name: vault-ca
      type: vault
      dpCert:
        rotation:
          expiration: 1d
      conf:
        fromCp:
          address: https://vault.default:8200
          role: mesh-dp
          auth:
            token:
              secret: vault-token
          tls:
            caCert:
              secret: vault-ca-cert' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify the CP can talk to Vault by checking its logs for a successful issuance on the next sidecar restart:

```bash
kubectl logs -n kong-mesh-system deploy/kong-mesh-control-plane | grep -i vault
```

### Option C: AWS ACM Private CA

For AWS-anchored deployments. You'll need the ARN of an existing Private CA and access keys (or, better, an IRSA-bound service account):

{% navtabs "acm-backend" %}
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
    enabledBackend: aws-acm-ca
    backends:
      - name: aws-acm-ca
        type: acm
        acm:
          arn: arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/abcd1234
          auth:
            awsCredentials:
              accessKey: { secret: aws-access-key }
              accessKeySecret: { secret: aws-secret-key }' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
mtls:
  enabledBackend: aws-acm-ca
  backends:
    - name: aws-acm-ca
      type: acm
      acm:
        arn: arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/abcd1234
        auth:
          awsCredentials:
            accessKey: { secret: aws-access-key }
            accessKeySecret: { secret: aws-secret-key }' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Option D: Bundled external CA via `MeshIdentity`

For environments where the CA material itself is delivered to the cluster (air-gapped meshes, smartcard-issued roots, etc.) — use the modern Workload Identity path from Step 2 and point at the external CA as a `Bundled` provider with `insecureAllowSelfSigned: false` (you should now have a real CA, so don't allow self-signed):

{% navtabs "bundled-external" %}
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
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: corporate-root-ca
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: corporate-root-ca-key
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
      ca:
        certificate:
          type: Secret
          secretRef:
            kind: Secret
            name: corporate-root-ca
        privateKey:
          type: Secret
          secretRef:
            kind: Secret
            name: corporate-root-ca-key
  spiffeID:
    trustDomain: internal.kongair.com
    path: /{% raw %}{{ .Namespace }}{% endraw %}/{% raw %}{{ .Workload }}{% endraw %}' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step E: A safe migration (built-in → Vault)

Apply this sequence if you're moving an existing mesh from the built-in CA to Vault without any wire-level downtime.

**1. Add Vault's CA to the trust bundle** (so sidecars trust both old and new):

{% navtabs "trust-both" %}
{% navtab "Kubernetes" %}
```bash
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  name: kong-air-trust
  namespace: kong-mesh-system
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
$(sed 's/^/          /' builtin-ca.crt)
    - type: Pem
      pem:
        value: |
$(sed 's/^/          /' vault-ca.crt)" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo "type: MeshTrust
name: kong-air-trust
mesh: default
spec:
  trustDomain: internal.kongair.com
  caBundles:
    - type: Pem
      pem:
        value: |
$(sed 's/^/          /' builtin-ca.crt)
    - type: Pem
      pem:
        value: |
$(sed 's/^/          /' vault-ca.crt)" | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Wait at least one KDS sync cycle (a few seconds in most environments).

**2. Flip the issuance backend to Vault** — apply the Option B `Mesh` resource above.

**3. Force a rotation on a canary workload** so it picks up a Vault-issued cert immediately, rather than waiting up to 24h:

```bash
kubectl rollout restart deploy flight-control -n kong-air-production
```

Confirm via the SAN check from Step 2 that the new cert is signed by Vault's CA.

**4. Once you've waited longer than your `dpCert.rotation.expiration`** (24h with the example config), every sidecar in the mesh has rotated to a Vault-issued cert. Now you can remove the built-in CA from the trust bundle:

```bash
kubectl patch meshtrust kong-air-trust -n kong-mesh-system --type=json \
  -p '[{"op":"remove","path":"/spec/caBundles/0"}]'
```

The migration is complete.

### What you did

- Configured three external-CA backends (cert-manager, Vault, ACM) with the right shape — including the non-obvious `fromCp` + `dpCert.rotation.expiration` pair that Vault specifically requires.
- Used `MeshIdentity` to point at a Bundled external CA in the modern Workload Identity path.
- Walked through a zero-downtime migration from the built-in CA to Vault using `MeshTrust` to span the cutover window.

### What's next

You now have a production-shaped security and observability posture: workload-level SPIFFE identities, enterprise-PKI-rooted trust, and full-stack telemetry. The next path covers what changes when you spread that mesh across multiple zones — multi-zone services, locality-aware routing, and per-zone canary releases.
