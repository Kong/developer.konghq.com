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
  q: How do I secure my services with Kong Mesh?
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
  name: default
spec:
  mtls:
    backends:
      - name: builtin
        type: builtin
    enabledBackend: builtin' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}

{% warning %}
In Universal mode, run this against your **Global CP** using `kumactl`. Use `kumactl config control-planes use <global-cp>` to confirm you're pointing at the right target.
{% endwarning %}

```bash
echo 'type: Mesh
name: default
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Verify mTLS is now active:
```bash
kumactl get meshes -o yaml | grep -A5 mtls
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

## 2. Baseline: All Traffic Allowed

The `allow-all` `MeshTrafficPermission` grants access from any service to any other service:

{% navtabs "allow-all" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}


## 3. Enforce Zero-Trust (Default Deny)

Kong Air's security team requires that only authorised services can access the check-in APIs. Start by removing the permissive `allow-all` policy and replacing it with a **Default Deny**:

{% warning %}
When an `Allow` and a `Deny` `MeshTrafficPermission` both match the same workload, **Allow wins**.  
To enforce a default-deny posture, you must **remove** any existing `allow-all` policy first.
{% endwarning %}

{% navtabs "delete-allow-all" %}
{% navtab "Kubernetes" %}
```bash
kubectl delete meshtrafficpermission allow-all -n kong-mesh-system
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl delete meshtrafficpermission allow-all --mesh default
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
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Deny' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: default-deny
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Deny' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## 4. Explicitly Authorize Service-to-Service Traffic

Now grant `flight-control` access to `check-in-api` using service identity tags:

{% navtabs "targeted-allow" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: check-in-api-blu
  from:
    - targetRef:
        kind: MeshService
        name: flight-control-blu
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-flight-control-to-check-in
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: check-in-api-blu
  from:
    - targetRef:
        kind: MeshService
        name: flight-control-blu
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}


Traffic is restored, **but only for `flight-control`**. Any other service will still receive `403 Forbidden`.

{% tip %}
`MeshTrafficPermission` is enforced on the **server side** (the receiver's inbound Envoy listener). This means:
- The RBAC decision happens at `check-in-api`, not at `flight-control`.
- Client-side traffic to a denied service will time out or receive an explicit `403`, depending on Envoy configuration.
{% endtip %}
