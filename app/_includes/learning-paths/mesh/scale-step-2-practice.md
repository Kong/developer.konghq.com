For this exercise you'll set up _soft_ multi-tenancy between Kong Air's `passenger-services` team and the newly-acquired `KongAir-EU` team on a single mesh, then verify the isolation is tight enough that one team's mistake can't reach the other.

If you want to walk through hard multi-tenancy as well, the final section of this step covers the additional resources you'd add.

### Setup: two namespaces representing two tenants

```bash
kubectl create namespace kong-air-passenger
kubectl create namespace kong-air-eu

kubectl label namespace kong-air-passenger kuma.io/sidecar-injection=enabled
kubectl label namespace kong-air-eu kuma.io/sidecar-injection=enabled
```

For the rest of this step, treat `kong-air-passenger` as Devin's team and `kong-air-eu` as the EU subsidiary's team.

### Step 1: Establish a default-deny baseline

You did this in Fundamentals Step 2 — repeat it here if you don't already have it. Default-deny is the foundation of any multi-tenant model, soft or hard.

{% navtabs "mt-default-deny" %}
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

### Step 2: Allow intra-tenant traffic

Each tenant only needs to talk to its own services. Apply per-tenant allow rules that target traffic _within_ the namespace and reject everything else.

{% navtabs "mt-intra-tenant" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: passenger-intra-tenant
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Dataplane
    labels:
      k8s.kuma.io/namespace: kong-air-passenger
  from:
    - targetRef:
        kind: Dataplane
        labels:
          k8s.kuma.io/namespace: kong-air-passenger
      default:
        action: Allow
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: eu-intra-tenant
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Dataplane
    labels:
      k8s.kuma.io/namespace: kong-air-eu
  from:
    - targetRef:
        kind: Dataplane
        labels:
          k8s.kuma.io/namespace: kong-air-eu
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: passenger-intra-tenant
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/namespace: kong-air-passenger
  from:
    - targetRef:
        kind: Dataplane
        labels:
          kuma.io/namespace: kong-air-passenger
      default:
        action: Allow' | kumactl apply -f -

echo 'type: MeshTrafficPermission
name: eu-intra-tenant
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/namespace: kong-air-eu
  from:
    - targetRef:
        kind: Dataplane
        labels:
          kuma.io/namespace: kong-air-eu
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Notice the top-level `targetRef.kind: Dataplane` with `labels` — this is the correct pattern for selecting "every workload in namespace X" by tag.

### Step 3: Verify the boundary

Deploy a smoke-test workload in each namespace, then confirm cross-tenant traffic is blocked while intra-tenant traffic flows.

```bash
kubectl run client --image=curlimages/curl -n kong-air-passenger --command -- sleep 36000
kubectl run target --image=hashicorp/http-echo -n kong-air-passenger -- -text="hello from passenger"
kubectl expose pod target -n kong-air-passenger --port=5678

kubectl run target --image=hashicorp/http-echo -n kong-air-eu -- -text="hello from eu"
kubectl expose pod target -n kong-air-eu --port=5678
```

From the `passenger` client, intra-tenant call should succeed:

```bash
kubectl exec -n kong-air-passenger client -- \
  curl -s -o /dev/null -w "%{http_code}\n" http://target.kong-air-passenger:5678
# 200
```

Cross-tenant call should be denied at the destination sidecar:

```bash
kubectl exec -n kong-air-passenger client -- \
  curl -s -o /dev/null -w "%{http_code}\n" http://target.kong-air-eu:5678
# 403
```

That's the isolation soft multi-tenancy gives you: shared mesh, shared CA, full sidecar performance, but a hard policy boundary between tenants.

### Step 4: Carve out a sanctioned cross-tenant flow

Both teams agree that `kong-air-eu`'s `customer-portal` legitimately needs to call `kong-air-passenger`'s `flight-control` for shared reservation data. Apply a narrow, named exception:

{% navtabs "mt-exception" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: eu-customer-portal-to-flight-control
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: MeshService
    name: flight-control
  from:
    - targetRef:
        kind: Dataplane
        labels:
          app: customer-portal
          k8s.kuma.io/namespace: kong-air-eu
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: eu-customer-portal-to-flight-control
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: flight-control
  from:
    - targetRef:
        kind: Dataplane
        labels:
          app: customer-portal
          kuma.io/namespace: kong-air-eu
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Every other cross-tenant flow is still blocked.

### Step 5: Enforce RBAC on the policy surface

Soft multi-tenancy only works if tenants can't edit each other's policies. Apply a minimal RBAC posture:

```bash
# Passenger team can edit policies in kong-mesh-system that mention their namespace label
# (in real life, use a tighter ResourceQuota / OPA Gatekeeper rule than this RoleBinding)
kubectl create rolebinding passenger-mesh-editor -n kong-mesh-system \
  --clusterrole=edit \
  --group=kong-air-passenger-team
```

The platform team retains `cluster-admin` on `kong-mesh-system` for global policies (`MeshTLS`, `MeshTrust`, the default-deny). Tenants get scoped edit access for their own allow-rules.

### Optional: hard multi-tenancy walkthrough

If your situation calls for fully isolated meshes, the additional resources you'd apply look like this. Note both meshes are still managed by the same Global CP — they're just separate `Mesh` resources with separate CAs.

{% navtabs "mt-hard" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: passenger-mesh
spec:
  meshServices:
    mode: Exclusive
  mtls:
    backends:
      - name: builtin
        type: builtin
    enabledBackend: builtin
---
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: eu-mesh
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
name: passenger-mesh
meshServices:
  mode: Exclusive
mtls:
  backends:
    - name: builtin
      type: builtin
  enabledBackend: builtin' | kumactl apply -f -

echo 'type: Mesh
name: eu-mesh
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

Each namespace's pods now get a `kuma.io/mesh` label that determines which mesh they join. Traffic between meshes requires a cross-mesh gateway (covered in [cross-mesh gateways](/mesh/cross-mesh-gateway/)), with explicit allow-lists at the boundary.

### What you did

- Established a default-deny baseline.
- Set up two tenants on a single (soft) mesh with intra-tenant allow rules using `Dataplane` + label selectors.
- Verified the boundary by confirming cross-tenant traffic gets `403`'d at the destination.
- Carved out one explicit cross-tenant flow without weakening the default.
- Saw what the equivalent hard multi-tenancy setup would look like.

In Step 3 you'll run an asymmetric per-zone canary release for booking-engine v2, using the multi-zone fabric and `MeshLoadBalancingStrategy` for safety.
