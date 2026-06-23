---
title: "Global Routing: Canary Rollouts and Color Rings"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Route traffic across zones with MeshMultiZoneService and MeshHTTPRoute, weighted canary rollouts in a single zone, and permanent color rings with same-color cross-zone failover.
products:
  - mesh
tldr:
  q: How do I route traffic across zones for a canary rollout or for parallel color rings?
  a: |
    Both patterns build on **MeshMultiZoneService** (MMZS) and **MeshHTTPRoute**:
    1. **Weighted canary**: aggregate the stable pool across zones, expose the canary as a second MMZS, and apply a weighted split only in the rollout zone.
    2. **Color rings**: give each color its own MMZS, then pin each caller to its matching color, with failover inside the same ring.

    Pick by intent: canary for a temporary percentage rollout, color rings for permanent parallel environments.
prereqs:
  inline:
    - title: Architecture
      content: |
        A multi-zone {{site.mesh_product_name}} deployment with `spec.meshServices.mode: Exclusive` set on the `kong-air-mesh` `Mesh` resource. If you haven't set one up, start with [Multi-Zone Architecture](/mesh/scenarios/multi-zone-architecture/).
    - title: Mesh foundation
      content: |
        `MeshIdentity` and `MeshTLS` applied for `kong-air-mesh` (see [Getting Started with Policies](/mesh/scenarios/getting-started-policy/)). If you apply or change `MeshIdentity` on existing workloads, restart them before testing routes so they serve the new certificate.
next_steps:
  - text: "Securing the Perimeter: MeshPassthrough"
    url: "/mesh/scenarios/mesh-passthrough/"
---

Once Kong Air spans multiple zones, two routing needs show up that look similar but solve different problems: rolling out a new version to a slice of traffic, and keeping parallel "colored" environments separate. Both are built from the same two resources, `MeshMultiZoneService` and `MeshHTTPRoute`, which is exactly why it's worth seeing them side by side.

## Two routing patterns, one foundation

Every pattern here rests on two resources:

- **`MeshMultiZoneService` (MMZS)** aggregates the zone-local `MeshService` objects for a workload behind a single stable hostname, and provides the boundary for cross-zone failover. It is a **Global CP** resource; the synced zone copies receive a hash suffix in `metadata.name`, so zone-local policies reference them by their `kuma.io/display-name` label, not by name.
- **`MeshHTTPRoute`** decides how callers reach those MMZS pools, by **weight** or by the **caller's identity**.

The difference between the two patterns is entirely in that routing decision:

{% table %}
columns:
  - title: "&nbsp;"
    key: aspect
  - title: Weighted canary
    key: canary
  - title: Color rings
    key: color
rows:
  - aspect: "**How traffic splits**"
    canary: "By weight, for example 90% stable / 10% canary."
    color: "By the caller, blue callers reach the blue pool, green the green pool, 100% each."
  - aspect: "**Lifetime**"
    canary: "Temporary, a progressive rollout you ramp up, then retire."
    color: "Permanent, parallel rings that always exist."
  - aspect: "**Where the route applies**"
    canary: "Only in the rollout zone."
    color: "Everywhere; the pin follows the caller's `color` label."
  - aspect: "**Use it when**"
    canary: "You want to ship a new version to a little traffic in one region first."
    color: "You want self-contained environments that each fail over within their own color."
{% endtable %}

Pattern 1 covers the weighted canary. Pattern 2 covers color rings. They are independent, read whichever fits your need.

## Pattern 1: Weighted canary rollout

The Kong Air engineering team wants to test a new **Baggage Tracking API** in one zone without changing the routing policy everywhere else. The shape is: create global `MeshMultiZoneService` resources on the Global CP, then apply a **zone-local** `MeshHTTPRoute` only in the rollout zone.

This pattern needs a **stable** `MeshService` in every zone you want to fail over between, plus a separate **canary** `MeshService` in the rollout zone.

{% tip %}
On the live mesh, the `MeshMultiZoneService` resources synced correctly from Global to each zone, including generated hostnames such as `check-in-api-global.mzsvc.mesh.local`. A zone-local `MeshHTTPRoute` targeting those synced MMZS resources worked when the route referenced them by **`kuma.io/display-name` labels** and included an explicit backend `port`.
{% endtip %}

### 1. Define the global MeshMultiZoneService resources

Create the MMZS resources on the **Global Control Plane**, selecting the generated `MeshService` objects by their service-name labels.

{% warning %}
`MeshMultiZoneService` is a **Global CP** resource. On Konnect or a Universal-backed Global CP, create it with `kumactl`. The synced zone copies receive a hash suffix in `metadata.name`, so **zone-local policies should reference them by labels, not by name**.
{% endwarning %}

{% navtabs "canary-mmzs" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-global
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-canary-global
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api-canary
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
echo 'type: MeshMultiZoneService
name: check-in-api-global
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-canary-global
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: check-in-api-canary
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

After sync, the zone copies expose hostnames like:

- `check-in-api-global.mzsvc.mesh.local`
- `check-in-api-canary-global.mzsvc.mesh.local`

### 2. Apply the rollout-zone canary route

Apply this route only in the zone where you want the canary split. The working shape is:

- top-level `targetRef.kind: Dataplane`
- select the local callers with labels
- reference the synced MMZS resources by `labels.kuma.io/display-name`
- include `port: 8080` on every `MeshMultiZoneService` backend

{% navtabs "canary-route" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: check-in-global-canary
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-global
                port: 8080
                weight: 90
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-canary-global
                port: 8080
                weight: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshHTTPRoute
name: check-in-global-canary
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-global
                port: 8080
                weight: 90
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: check-in-api-canary-global
                port: 8080
                weight: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
This route is **zone-local**. Other zones keep using their existing stable path unless they add their own override or you apply a broader global route.
{% endtip %}

### 3. Verify the split

Check that the synced MMZS resources matched the expected backends:

```bash
kubectl get meshmultizoneservices -n {{site.mesh_namespace}} -o yaml
```

On the mesh:

- `check-in-api-global` matched **2 MeshServices** (zone1 stable + zone2 stable)
- `check-in-api-canary-global` matched **1 MeshService** (zone1 canary)

Then test from a pod in the rollout zone:

```bash
CALLER=$(kubectl get pod -n kong-air-production -l app=passenger-portal -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kong-air-production "$CALLER" -c passenger-portal -- \
  wget -qO- http://check-in-api-global.mzsvc.mesh.local:8080
```

The split is validated: a `90/10` route returned `54` stable and `6` canary responses over `60` requests.

### Optional: locality-aware failover for the stable pool

`MeshLoadBalancingStrategy` controls locality-aware failover. The stable pool is a good fit because `check-in-api-global` spans multiple zones.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshLoadBalancingStrategy
metadata:
  name: check-in-locality
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: check-in-api-global
      default:
        localityAwareness:
          disabled: false
          crossZone:
            failover:
              - to:
                  type: Any
```

## Pattern 2: Color rings

The Kong Air platform team uses **color labels** to manage parallel tracks of services: `blu` represents the stable production ring, `grn` the canary ring. Here, each ring stays self-contained across zones, without any code changes in the services themselves. A request from a `color:blu` pod always reaches a `color:blu` backend, callers use a single agnostic hostname, and each color fails over to its own pool in another zone.

{% mermaid %}
graph TD
    subgraph "Zone 1"
        CallerBlu["check-in-api-blu\n(color: blu)"]
        CallerGrn["check-in-api-grn\n(color: grn)"]
    end

    MMZS["flight-control-all\n(MMZS, agnostic hostname)"]

    subgraph "Color: blu"
        FCBlu1["flight-control-blu\n(Zone 1)"]
        FCBlu2["flight-control-blu\n(Zone 2)"]
    end

    subgraph "Color: grn"
        FCGrn1["flight-control-grn\n(Zone 1)"]
    end

    CallerBlu -->|"MeshHTTPRoute\n(color: blu → blu pool)"| MMZS
    CallerGrn -->|"MeshHTTPRoute\n(color: grn → grn pool)"| MMZS
    MMZS --> FCBlu1
    MMZS -.->|failover| FCBlu2
    MMZS --> FCGrn1
{% endmermaid %}

### 1. Deploy the color-ring workloads

This pattern uses `nginx:alpine` with per-color ConfigMaps to simulate services that return their own identity. No custom container image is required.

{% tip %}
These color workloads are **additive** to the base Kong Air demo. The caller pods (`check-in-api-blu`/`-grn`) carry `app: check-in-api` plus a `color` label so the color-based `MeshHTTPRoute` can select them, and they reuse the `check-in-api` service account. If your base demo's `check-in-api` Service selects all `app: check-in-api` pods, it will also pick up these `nginx` variants, fine for this self-contained walkthrough, but give them a distinct `app` label (or use a separate namespace) if you need the base service kept isolated.
{% endtip %}

Apply the following to **each zone**:

{% navtabs "color-workloads" %}
{% navtab "Kubernetes (each zone)" %}
```bash
kubectl apply -f - <<'EOF'
# --- Service accounts (skip if already created by base Kong Air demo) ---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: check-in-api
  namespace: kong-air-production
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flight-control
  namespace: kong-air-production
---
# --- Backend color variants: flight-control-blu ---
apiVersion: v1
kind: ConfigMap
metadata:
  name: flight-control-blu-config
  namespace: kong-air-production
data:
  default.conf: |
    server {
        listen 8080;
        location / {
            add_header Content-Type application/json;
            return 200 '{"service":"flight-control","color":"blu"}';
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flight-control-blu
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flight-control
      color: blu
  template:
    metadata:
      labels:
        app: flight-control
        color: blu
    spec:
      serviceAccountName: flight-control
      containers:
        - name: flight-control
          image: nginx:alpine
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d
      volumes:
        - name: nginx-config
          configMap:
            name: flight-control-blu-config
---
apiVersion: v1
kind: Service
metadata:
  name: flight-control-blu
  namespace: kong-air-production
spec:
  selector:
    app: flight-control
    color: blu
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      appProtocol: http
---
# --- Backend color variants: flight-control-grn ---
apiVersion: v1
kind: ConfigMap
metadata:
  name: flight-control-grn-config
  namespace: kong-air-production
data:
  default.conf: |
    server {
        listen 8080;
        location / {
            add_header Content-Type application/json;
            return 200 '{"service":"flight-control","color":"grn"}';
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flight-control-grn
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flight-control
      color: grn
  template:
    metadata:
      labels:
        app: flight-control
        color: grn
    spec:
      serviceAccountName: flight-control
      containers:
        - name: flight-control
          image: nginx:alpine
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d
      volumes:
        - name: nginx-config
          configMap:
            name: flight-control-grn-config
---
apiVersion: v1
kind: Service
metadata:
  name: flight-control-grn
  namespace: kong-air-production
spec:
  selector:
    app: flight-control
    color: grn
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      appProtocol: http
---
# --- Agnostic Service: spans all flight-control pods ---
# This gives the "all-colors" MMZS a named MeshService to attach to.
apiVersion: v1
kind: Service
metadata:
  name: flight-control-all
  namespace: kong-air-production
spec:
  selector:
    app: flight-control
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      appProtocol: http
---
# --- Caller pods: check-in-api-blu and check-in-api-grn ---
# Plain nginx:alpine, only the color label matters for routing policy targeting.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: check-in-api-blu
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: check-in-api
      color: blu
  template:
    metadata:
      labels:
        app: check-in-api
        color: blu
    spec:
      serviceAccountName: check-in-api
      containers:
        - name: check-in-api
          image: nginx:alpine
          ports:
            - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: check-in-api-grn
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: check-in-api
      color: grn
  template:
    metadata:
      labels:
        app: check-in-api
        color: grn
    spec:
      serviceAccountName: check-in-api
      containers:
        - name: check-in-api
          image: nginx:alpine
          ports:
            - containerPort: 8080
EOF
```
{% endnavtab %}
{% endnavtabs %}

Verify the pods are running with sidecars injected (2/2 READY):

```bash
kubectl get pods -n kong-air-production -l app=flight-control
kubectl get pods -n kong-air-production -l app=check-in-api
```

### 2. Create the per-color MeshMultiZoneService resources

Create three MMZS resources on the **Global CP**:
- `flight-control-all`, the agnostic hostname clients call
- `flight-control-blu`, the blue pool, spanning all zones
- `flight-control-grn`, the green pool, spanning all zones

{% warning %}
`MeshMultiZoneService` must be applied to the **Global Control Plane**. Zone-synced copies receive a hash suffix in `metadata.name`; reference them by `kuma.io/display-name` label in zone-local policies.
{% endwarning %}

{% navtabs "color-mmzs" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-all
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-all
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-blu
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-blu
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-grn
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-grn
  ports:
    - port: 8080
      appProtocol: http
EOF
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
kumactl apply -f - <<'EOF'
type: MeshMultiZoneService
name: flight-control-all
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-all
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: flight-control-blu
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-blu
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: flight-control-grn
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kong-air-production
        k8s.kuma.io/service-name: flight-control-grn
  ports:
    - port: 8080
      appProtocol: http
EOF
```
{% endnavtab %}
{% endnavtabs %}

After sync, check that each MMZS matched the expected MeshServices:

```bash
kubectl get meshmultizoneservices -n {{site.mesh_namespace}} \
  -l kuma.io/mesh=kong-air-mesh
```

Each MMZS generates a stable hostname:
- `flight-control-all.mzsvc.mesh.local`
- `flight-control-blu.mzsvc.mesh.local`
- `flight-control-grn.mzsvc.mesh.local`

### 3. Apply color-pinning routes

Clients call the color-agnostic hostname `flight-control-all.mzsvc.mesh.local`. `MeshHTTPRoute` intercepts those calls based on the **caller's** `color` label and redirects to the matching color pool. No client code changes are required.

Apply these routes via the **Global CP** so they take effect in all zones:

{% navtabs "color-pinning" %}
{% navtab "Kubernetes Global CP (self-managed)" %}
```bash
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: color-pin-blu
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  targetRef:
    kind: Dataplane
    labels:
      color: blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: flight-control-blu
                port: 8080
                weight: 100
---
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: color-pin-grn
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  targetRef:
    kind: Dataplane
    labels:
      color: grn
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: flight-control-grn
                port: 8080
                weight: 100
EOF
```
{% endnavtab %}
{% navtab "Konnect / Universal Global CP" %}
```bash
kumactl apply -f - <<'EOF'
type: MeshHTTPRoute
name: color-pin-blu
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  targetRef:
    kind: Dataplane
    labels:
      color: blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: flight-control-blu
                port: 8080
                weight: 100
---
type: MeshHTTPRoute
name: color-pin-grn
mesh: kong-air-mesh
labels:
  kuma.io/origin: global
spec:
  targetRef:
    kind: Dataplane
    labels:
      color: grn
  to:
    - targetRef:
        kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                labels:
                  kuma.io/display-name: flight-control-grn
                port: 8080
                weight: 100
EOF
```
{% endnavtab %}
{% endnavtabs %}

### 4. Verify color affinity

Both caller pods call the same agnostic hostname. The mesh routes each to its matching color pool.

```bash
# From the blu caller, should always return "color":"blu"
BLU_POD=$(kubectl get pod -n kong-air-production -l app=check-in-api,color=blu \
  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n kong-air-production "$BLU_POD" -c check-in-api -- \
  sh -c 'for i in $(seq 1 10); do wget -qO- http://flight-control-all.mzsvc.mesh.local:8080; echo; done'
```

Expected output, all responses from the blue pool:
```
{"service":"flight-control","color":"blu"}
{"service":"flight-control","color":"blu"}
...
```

```bash
# From the grn caller, should always return "color":"grn"
GRN_POD=$(kubectl get pod -n kong-air-production -l app=check-in-api,color=grn \
  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n kong-air-production "$GRN_POD" -c check-in-api -- \
  sh -c 'for i in $(seq 1 10); do wget -qO- http://flight-control-all.mzsvc.mesh.local:8080; echo; done'
```

Expected output, all responses from the green pool:
```
{"service":"flight-control","color":"grn"}
{"service":"flight-control","color":"grn"}
...
```

### 5. Verify cross-zone failover

The `flight-control-blu` MMZS aggregates blue pods from **all** zones, so this step only works if **zone2 is also running the blue pool**, repeat the step-1 deployment against your zone2 cluster first. Then scale zone1's blue pool to zero and confirm zone1's caller fails over to zone2's blue pods.

{% warning %}
These commands target a specific zone, so they use `--context zone1` (replace with your actual kube-context names). If zone1 is your only zone, scaling its blue pool to zero leaves nowhere to fail over to and the check will fail.
{% endwarning %}

```bash
# On zone1: scale down the blue backend
kubectl --context zone1 scale deploy/flight-control-blu -n kong-air-production --replicas=0

# Wait for the pod to terminate
kubectl --context zone1 wait --for=delete pod -n kong-air-production \
  -l app=flight-control,color=blu --timeout=30s
```

Re-run the affinity check from the blu caller (a zone1 pod):

```bash
kubectl --context zone1 exec -n kong-air-production "$BLU_POD" -c check-in-api -- \
  sh -c 'for i in $(seq 1 10); do wget -qO- http://flight-control-all.mzsvc.mesh.local:8080; echo; done'
```

Traffic continues to return `"color":"blu"`, now served from **zone2's** blue pool. Restore zone1 when done:

```bash
kubectl --context zone1 scale deploy/flight-control-blu -n kong-air-production --replicas=1
```

## Key takeaways

- **Both patterns share one foundation.** `MeshMultiZoneService` aggregates pools across zones and owns the failover boundary; `MeshHTTPRoute` decides who reaches which pool.
- **Canary splits by weight; color rings split by caller.** Use canary for a temporary percentage rollout in one zone, use color rings for permanent parallel environments.
- **Clients stay decoupled from topology.** Callers use a single MMZS hostname; the route and MMZS handle version or color resolution and zone selection, no client code changes.
- **Routing is enforced by policy, not by code.** Change a weight or a `color` label and the mesh re-resolves on the next reconciliation.
- **Each MMZS is its own failover boundary.** The stable pool fails over independently of the canary; each color ring fails over within its own color.
