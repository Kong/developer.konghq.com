---
title: "Getting Started: Your First Policy"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A hands-on guide to applying your first security policy with {{site.mesh_product_name}}, enabling mTLS and enforcing zero-trust traffic permissions.
products:
  - mesh
tldr:
  q: How do I secure my services with {{site.mesh_product_name}}?
  a: |
    Secure your mesh in four steps:
    1. **Issue workload identity** via `MeshIdentity` to encrypt all traffic with SPIFFE/X.509 certificates.
    2. **Enforce strict mTLS** via `MeshTLS` to reject any unencrypted or unauthenticated traffic.
    3. **Enforce Default Deny** by removing the permissive `allow-all` policy.
    4. **Authorize Traffic** by creating explicit `MeshTrafficPermission` policies for your services.
prereqs:
  inline:
    - title: Tools
      content: |
        * **kubectl** installed and configured against your Kubernetes cluster.
        * **kumactl** CLI installed and connected to your Control Plane.
    - title: Environment
      content: |
        A running {{site.mesh_product_name}} deployment with the **kong-air-production** namespace, sidecar injection enabled, and `meshServices.mode: Exclusive` set on the `kong-air-mesh` Mesh resource.
next_steps:
  - text: "How to Use {{site.mesh_product_name}} Policies"
    url: "/mesh/scenarios/using-policies/"
---
## 1. Issue Workload Identity with `MeshIdentity`

In {{site.mesh_product_name}} 2.14+, workload identity is managed by the `MeshIdentity` resource, not the `Mesh` object's legacy `mtls` block. `MeshIdentity` decouples certificate issuance from the Mesh resource, letting you target specific workloads, customize SPIFFE ID paths, and integrate with SPIRE. The `Bundled` provider with `autogenerate` is the recommended starting point.

{% navtabs "mesh-identity" %}
{% navtab "Kubernetes Global CP (self-managed)" %}

{% warning %}
`MeshIdentity` must be created in the system namespace on Kubernetes. If your Global CP is Kubernetes-hosted, apply this against your Global CP kubeconfig. If your Global CP is Konnect or Universal-backed, use `kumactl apply` and {{site.mesh_product_name}} will sync it to every zone.
{% endwarning %}

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: kong-air-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}

{% warning %}
Run this against your **Global CP**. Use `kumactl config control-planes use <global-cp>` first.
{% endwarning %}

```bash
echo 'type: MeshIdentity
name: kong-air-identity
mesh: kong-air-mesh
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

After applying, **restart your workloads** so each sidecar picks up a new certificate under the `MeshIdentity` backend:

```bash
kubectl rollout restart deployment -n kong-air-production
```

Verify the identity is active, `issuedBackend` should reference `kong-air-identity`:

```bash
kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
```

Expected output:

```yaml
mTLS:
  issuedBackend: kri_mid_kong-air-mesh___kong-air-identity_
```

This `MeshIdentity` gives **every workload in the mesh** a SPIFFE certificate with its Kubernetes service account encoded in the path:

```
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/check-in-api
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/passenger-portal
```

{% tip %}
Mesh-wide does not mean "one shared identity." A `MeshIdentity` is an *issuer*, not an identity: it sets the CA/provider, the SPIFFE ID **path template**, and the trust domain. The actual SPIFFE ID is rendered **per workload** from that template, so every workload still gets a **unique** identity (as the three distinct IDs above show), and `MeshTrafficPermission` keeps full per-workload granularity even with one mesh-wide identity.

Add *more* `MeshIdentity` resources only when a group of workloads needs different **issuance** (a different CA/provider, path scheme, or rotation policy), not to authorize app-to-app traffic. 

{% endtip %}


{% warning %}
Multi-zone deployments need an extra cross-zone trust step. The `autogenerate: enabled: true` option lets each Zone CP generate its own CA independently. This is convenient but means zone1 and zone2 have different CAs. Due to a naming collision during KDS sync, each zone ends up trusting only its own CA. Cross-zone mTLS then fails at the ZoneIngress TLS handshake.

To fix this, create a combined `MeshTrust` on each zone containing all zones' CA bundles. See the [Workload Identity guide](/mesh/scenarios/workload-identity/) for the full procedure and the production alternative (shared CA or SPIRE).
{% endwarning %}

## 2. Enforce Strict mTLS with `MeshTLS`

`MeshIdentity` issues certificates but does not enforce that they are used. Apply a `MeshTLS` policy to reject any unencrypted or unauthenticated traffic across the mesh.

Apply it at the **Global CP**, alongside the `MeshIdentity` from step 1. KDS syncs it to every zone, so strict mTLS is enforced across the whole mesh from a single resource.

{% navtabs "mesh-tls-strict" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: strict-mtls
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
echo 'type: MeshTLS
name: strict-mtls
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

With `MeshTLS` in `Strict` mode, every inbound connection must present a valid mTLS certificate. Unencrypted traffic is rejected at the proxy level before any RBAC evaluation.

## 3. Baseline: All Traffic Allowed

The `allow-all` `MeshTrafficPermission` grants access from any workload in the mesh to any other workload, by matching the mesh SPIFFE trust domain as a prefix.

{% navtabs "allow-all" %}
{% navtab "Kubernetes Global CP (self-managed)" %}

{% tip %}
Like the `MeshTLS` and `MeshIdentity` resources above, apply these permissions at the Global CP so they span every zone. You *can* apply policies directly to a Zone CP instead; see [Resource Scoping](/mesh/scenarios/resource-scoping/) for when you'd do that and the `kuma.io/origin: zone` label it requires.
{% endtip %}

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://kong-air-mesh.mesh.local' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-all
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://kong-air-mesh.mesh.local' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 4. Enforce Zero-Trust (Default Deny)

Kong Air's security team requires that only authorized services can access the check-in APIs. Start by removing the permissive `allow-all` policy:

{% warning %}
`MeshTrafficPermission` is a special case in {{site.mesh_product_name}}. Unlike most inbound policies, it does **not** use a simple "most specific match wins" rule. The control plane evaluates every matching traffic-permission rule, and if any matched rule produces a `Deny`, that deny takes precedence. To enforce a default-deny posture cleanly, **remove the existing `allow-all` policy first**, then layer narrower allows on top of the default deny.
{% endwarning %}

{% navtabs "delete-allow-all" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
kubectl delete meshtrafficpermission allow-all -n {{site.mesh_namespace}}
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
kumactl delete meshtrafficpermission allow-all --mesh kong-air-mesh
```
{% endnavtab %}
{% endnavtabs %}

With no `MeshTrafficPermission` in place, all inter-service traffic returns `403 Forbidden`. This is your **default-deny** baseline.

{% tip %}
Policy changes are not always instantaneous. `MeshTrafficPermission` updates can take a few seconds to propagate to the dataplanes. If a request still succeeds or fails immediately after you apply a policy, wait a moment and test again before assuming the policy shape is wrong.
{% endtip %}

## 5. Explicitly Authorize Service-to-Service Traffic

Now grant one caller access to `check-in-api`. The best-practice path is to target the receiving dataplane and allow the caller's authenticated SPIFFE identity explicitly.

Because each workload runs as its own Kubernetes `ServiceAccount`, the SPIFFE ID encodes the service account name. `flight-control` runs as the `flight-control` `ServiceAccount`, so its SPIFFE ID is:

```
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
```

{% navtabs "targeted-allow" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-flight-control-to-check-in
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Traffic to `check-in-api` is restored **only for `flight-control`**. Any other service still receives `403 Forbidden`.

{% tip %}
`MeshTrafficPermission` is enforced on the **server side** (the receiver's inbound Envoy listener). This means the RBAC decision happens at `check-in-api`, not at `flight-control`.
{% endtip %}

{% tip %}
If you see older runbooks using `MeshSubset`, top-level `MeshService`, or `spec.from`, update them to `Dataplane` + `rules` to match the resource model used in these scenarios.
{% endtip %}
