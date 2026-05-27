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
    Secure your mesh in three steps:
    1. **Enable mTLS** to encrypt all traffic and enable SPIFFE identity.
    2. **Enforce Default Deny** to move from an open network to zero-trust.
    3. **Authorize Traffic** by creating explicit `MeshTrafficPermission` policies for your services.
prereqs:
  inline:
    - title: Tools
      content: |
        * **kubectl** installed and configured against your Kubernetes cluster.
        * **kumactl** CLI installed and connected to your Control Plane.
    - title: Environment
      content: |
        A running {{site.mesh_product_name}} deployment with the **kong-air-production** namespace and sidecar injection enabled.
next_steps:
  - text: "How to Use {{site.mesh_product_name}} Policies"
    url: "/mesh/scenarios/using-policies/"
---
## 1. Enable mTLS

By default, {{site.mesh_product_name}} has mTLS **disabled**. The `default` Mesh object has no `mtls` configuration.

Enable it by applying the `Mesh` resource:

{% navtabs "mesh-mtls" %}
{% navtab "Kubernetes (Global CP)" %}

{% warning %}
The `Mesh` resource is **Global CP only**: it can only be created or modified on the Global Control Plane. Apply this against your Global CP kubeconfig. Zone CPs receive a read-only copy via KDS. See [Resource Scoping](/mesh/scenarios/resource-scoping/) for details.
{% endwarning %}

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: kong-air-mesh
spec:
  mtls:
    backends:
      - name: builtin
        type: builtin
    enabledBackend: builtin
  meshServices:
    mode: Exclusive' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}

{% warning %}
In Universal mode, run this against your **Global CP** using `kumactl`. Use `kumactl config control-planes use <global-cp>` to confirm you're pointing at the right target.
{% endwarning %}

```bash
echo 'type: Mesh
name: kong-air-mesh
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin
meshServices:
  mode: Exclusive' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify mTLS is now active:
```bash
kumactl get meshes kong-air-mesh -o yaml | grep -A5 mtls
```

Expected output:
```yaml
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin
```

With mTLS enabled, all inter-service communication is automatically encrypted and mutually authenticated using SPIFFE/X.509 certificates, with no application changes required.

{% warning %}
When mTLS is enabled in a Mesh, you will need an explicit `MeshTrafficPermission` policy to allow traffic between services. Without it, all traffic will be blocked by default.
{% endwarning %}

{% tip %}
**MeshService mode.** This guide assumes `spec.meshServices.mode: Exclusive`, because that is the best-practice path for production meshes. It moves policy matching and routing onto first-class resources instead of the legacy `kuma.io/service` tag model. Four modes are available:

- `Disabled` — legacy tag-based behaviour (default).
- `Everywhere` — `MeshService` is generated for every workload and used for configuration alongside tags.
- `ReachableBackends` — `MeshService` is generated, but only used where you explicitly opt in via `reachableBackends`.
- `Exclusive` — `MeshService` is the only model; `kuma.io/service` tags are not used. Recommended production path.

Existing clusters can switch modes with `kubectl patch mesh kong-air-mesh --type merge -p '{"spec":{"meshServices":{"mode":"Exclusive"}}}'`. Test in a non-production zone first.
{% endtip %}

## 2. Baseline: All Traffic Allowed

The `allow-all` `MeshTrafficPermission` grants access from any workload in the mesh to any other workload in the mesh by matching the mesh SPIFFE trust domain directly.

{% navtabs "allow-all" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: {{site.mesh_system_namespace}}
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://kong-air-mesh.mesh.local
```
{% endnavtab %}
{% navtab "Universal" %}
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

{% tip %}
Legacy `spec.from` examples still apply on current 2.13 control planes, but they emit a deprecation warning and are being removed in 3.0. This guide uses the `rules` shape directly so you do not have to unlearn it later.
{% endtip %}


## 3. Enforce Zero-Trust (Default Deny)

Kong Air's security team requires that only authorised services can access the check-in APIs. Start by removing the permissive `allow-all` policy and replacing it with a **Default Deny**:

{% warning %}
`MeshTrafficPermission` is a special case in {{site.mesh_product_name}}. Unlike most inbound policies, it does **not** use a simple "most specific match wins" rule. The control plane evaluates every matching traffic-permission rule, and if any matched rule produces a `Deny`, that deny takes precedence. To enforce a default-deny posture cleanly, **remove the existing `allow-all` policy first**, then layer narrower allows on top of the default deny.
{% endwarning %}

{% navtabs "delete-allow-all" %}
{% navtab "Kubernetes" %}
```bash
kubectl delete meshtrafficpermission allow-all -n kong-mesh-system
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl delete meshtrafficpermission allow-all --mesh kong-air-mesh
```
{% endnavtab %}
{% endnavtabs %}

Apply the deny-all policy:

{% navtabs "default-deny" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: default-deny
  namespace: {{site.mesh_system_namespace}}
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: spiffe://kong-air-mesh.mesh.local' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: default-deny
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: spiffe://kong-air-mesh.mesh.local' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
Policy changes are not always instantaneous. In the 2.13 validation environment, `MeshTrafficPermission` updates took a few seconds to propagate to the dataplanes. If a request still succeeds or fails immediately after you apply a policy, wait a moment and test again before assuming the policy shape is wrong.
{% endtip %}

## 4. Explicitly Authorize Service-to-Service Traffic

Now grant one caller access to `check-in-api`. The best-practice path is to target the receiving dataplane and allow the caller's authenticated identity explicitly.

For Kubernetes, the cleanest way to make that identity workload-specific is to give `flight-control` its own ServiceAccount. In the example below, `flight-control` runs as ServiceAccount `flight-control`, so its SPIFFE ID becomes `spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control`.

{% navtabs "targeted-allow" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: {{site.mesh_system_namespace}}
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
{% navtab "Universal" %}
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


Traffic is restored, **but only for `flight-control`**. Any other service will still receive `403 Forbidden`.

{% tip %}
Legacy `MeshSubset`, `MeshService`, and `spec.from` examples are still accepted on current 2.13 control planes, but they are already on the deprecation path. If you see them in older internal runbooks, plan to replace them with `Dataplane` + `rules` before moving to 3.0.
{% endtip %}

{% tip %}
`MeshTrafficPermission` is enforced on the **server side** (the receiver's inbound Envoy listener). This means:
- The RBAC decision happens at `check-in-api`, not at `flight-control`.
- Client-side traffic to a denied service will time out or receive an explicit `403`, depending on Envoy configuration.
{% endtip %}
