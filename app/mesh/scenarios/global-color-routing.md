---
title: "Global Color Routing"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Route traffic by workload color across zones using MeshMultiZoneService and MeshHTTPRoute. Each color ring stays self-contained end-to-end, with automatic failover to the same color in another zone.
products:
  - mesh
tldr:
  q: How do I route traffic based on workload version or color across zones?
  a: |
    Use **MeshMultiZoneService** and **MeshHTTPRoute** to:
    1. **Aggregate colored pools** across zones behind per-color MMZS hostnames.
    2. **Intercept color-agnostic calls**, clients use a single hostname and the mesh routes to the matching color pool.
    3. **Fail over within the color ring**, if zone1's blue pool is down, traffic moves to zone2's blue pool automatically.
prereqs:
  inline:
    - title: Architecture
      content: |
        A multi-zone {{site.mesh_product_name}} deployment with `spec.meshServices.mode: Exclusive` set on the `kong-air-mesh` `Mesh` resource. If you haven't set one up, start with [Multi-Zone Architecture](/mesh/scenarios/multi-zone-architecture/).
    - title: Mesh
      content: |
        `MeshIdentity` and `MeshTLS` applied for the `kong-air-mesh` mesh (see [Getting Started with Policies](/mesh/scenarios/getting-started-policy/)).
next_steps:
  - text: "Securing the Perimeter: MeshPassthrough"
    url: "/mesh/scenarios/mesh-passthrough/"
---

The Kong Air platform team uses **color labels** to manage parallel tracks of services: `blu` represents the stable production ring, `grn` the canary ring. This guide shows how to use `MeshMultiZoneService` and `MeshHTTPRoute` to keep each ring self-contained across zones, without any code changes in the services themselves.

## What this proves

{% table %}
columns:
  - title: Goal
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Color affinity
    outcome: A request from a `color:blu` pod always reaches a `color:blu` backend, regardless of which zone serves it.
  - goal: Agnostic hostname
    outcome: Client code calls a single stable hostname (`flight-control-all.mzsvc.mesh.local`). The mesh resolves the correct color pool via policy, no client-side logic required.
  - goal: Cross-zone failover
    outcome: If zone1's blue pool is down, the MMZS automatically routes to zone2's blue pool within the same color ring.
{% endtable %}

## Architecture

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

---

## 1. Deploy the color-ring workloads

This scenario uses `nginx:alpine` with per-color ConfigMaps to simulate services that return their own identity. No custom container image is required.

> [!NOTE]
> These color workloads are **additive** to the base Kong Air demo. The caller pods (`check-in-api-blu`/`-grn`) carry `app: check-in-api` plus a `color` label so the color-based `MeshHTTPRoute` can select them, and they reuse the `check-in-api` service account. If your base demo's `check-in-api` Service selects all `app: check-in-api` pods, it will also pick up these `nginx` variants, fine for this self-contained walkthrough, but give them a distinct `app` label (or use a separate namespace) if you need the base service kept isolated.

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

---

## 2. Create MeshMultiZoneService resources (Global CP)

Create three MMZS resources on the **Global CP**:
- `flight-control-all`, the agnostic hostname clients call
- `flight-control-blu`, the blue pool, spanning all zones
- `flight-control-grn`, the green pool, spanning all zones

{% warning %}
`MeshMultiZoneService` must be applied to the **Global Control Plane**. Zone-synced copies receive a hash suffix in `metadata.name`; reference them by `kuma.io/display-name` label in zone-local policies.
{% endwarning %}

{% navtabs "mmzs-resources" %}
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

---

## 3. Apply color-pinning routes

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

---

## 4. Verify color affinity

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

---

## 5. Verify cross-zone failover

The `flight-control-blu` MMZS aggregates blue pods from **all** zones, so this step only works if **zone2 is also running the blue pool**, repeat the section-1 deployment against your zone2 cluster first. Then scale zone1's blue pool to zero and confirm zone1's caller fails over to zone2's blue pods.

> [!IMPORTANT]
> These commands target a specific zone, so they use `--context zone1` (replace with your actual kube-context names). If zone1 is your only zone, scaling its blue pool to zero leaves nowhere to fail over to and the check will fail.

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

---

## Key takeaways

- **Clients stay decoupled from topology.** `check-in-api` calls `flight-control-all.mzsvc.mesh.local`, the MMZS and MeshHTTPRoute handle color resolution and zone selection.
- **Color pinning is enforced by policy, not by code.** Even if a client pod's `color` label changes, the mesh automatically routes it to the correct pool on the next reconciliation.
- **Per-color MMZS provides the failover boundary.** Each color ring fails over independently, a blue outage doesn't affect the green ring.
