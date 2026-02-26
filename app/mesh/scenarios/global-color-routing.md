---
title: "Global Color Routing"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A deep-dive into color-based routing with cross-zone failover using {{site.mesh_product_name}} MeshMultiZoneServices and agnostic hostnames.
products:
  - mesh
tldr:
  q: How do I route traffic based on workload versions across zones?
  a: |
    This scenario uses **MeshMultiZoneService (MMZS)** and **MeshHTTPRoute** to:
    1. **Pin traffic by color** (e.g., experimental vs. stable) across multiple hops.
    2. **Enable failover** within a specific color group across different zones.
    3. **Simplify connectivity** using agnostic hostnames that don't change during rollouts.
prereqs:
  inline:
    - title: Architecture
      content: |
        A multi-zone {{site.mesh_product_name}} deployment (Global CP + multiple Zone CPs).
    - title: Resources
      content: |
        The **chain-app** container image available in your environment.
next_steps:
  - text: "Securing the Perimeter: MeshPassthrough"
    url: "/mesh/scenarios/mesh-passthrough/"
---
## What this proves

{% table %}
columns:
  - title: Goal
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Color Affinity
    outcome: The full chain (Gateway -> Check-in -> Flight Control) stays within the same color via agnostic hostnames.
  - goal: Cross-Zone Failover
    outcome: If a service fails in one zone, traffic automatically shifts to the same color in another zone.
  - goal: Business Continuity
    outcome: Your flight operations remain stable across regions without code changes.
{% endtable %}

### The Routing Chain

{% mermaid %}
graph TD
    Gateway["Kong Gateway (Gateway API)"] -->|HTTPRoute split| MMZS1["check-in-api-all (MMZS)"]
    MMZS1 -->|color-pinning| App1B["Check-in-blu (Zone A)"]
    App1B -->|agnostic host| MMZS2["flight-control-all (MMZS)"]
    MMZS2 -->|color-pinning| App2B["Flight-Control-blu (Zone A)"]

    subgraph "Color: Blue"
        App1B
        App2B
    end

    App1B -.->|Failover| App1B_ZoneB["Check-in-blu (Zone B)"]
{% endmermaid %}

---

## 1. Building the Kong Air `chain-app`

The `chain-app` is a lightweight service used by the Kong Air platform team to simulate service-to-service calls. It returns its own identity (service name, color, pod, node) and propagates calls to a `BACKEND_URL`.

```bash
docker build -t kong-air/chain-app:v1 .
```

## 2. Setting Up the Demo

### Step 1: Namespace & Workloads

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 07-flight-control-services.yaml   # Flight Control (downstream)
kubectl apply -f 01-check-in-services.yaml         # Check-in API (upstream)
kubectl apply -f 02-client-pods.yaml               # Client pods
```

### Step 2: Create MeshMultiZoneService Resources (Global CP)

Create "all-colors" aggregated pools for each service. These aggregate pods regardless of their `color` label so the mesh can route to the right color via policy.

{% warning %}
`MeshMultiZoneService` must be applied to the **Global Control Plane**. You must also set `appProtocol: http` on the port, as without it, Kuma defaults to `tcp` and `MeshHTTPRoute` policies will be silently ignored.
{% endwarning %}

{% navtabs "mmzs-create" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control-all
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: http
---
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: check-in-api-all
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: MeshMultiZoneService
name: flight-control-all
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: flight-control
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: http
---
type: MeshMultiZoneService
name: check-in-api-all
mesh: default
labels:
  kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/service-name: check-in-api
        k8s.kuma.io/namespace: kong-air-production
  ports:
    - port: 8080
      appProtocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Color-Pinning Routes

These routes ensure that a request originating from a `blu`-colored sidecar stays within the `blu` service ring.

{% tip %}
**Why `MeshService`?**
Using explicit `MeshService` resources provides stable, resource-based targeting that doesn't rely on fragile pod tags or hash suffixes. This model is the standard for modern {{site.mesh_product_name}} deployments (2.6+).
{% endtip %}

{% navtabs "color-pinning" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: color-pinning-blu
  namespace: kong-air-production
  labels:
    kuma.io/origin: global
spec:
  targetRef:
    kind: MeshService
    name: client-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: "/"
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: flight-control-blu
                weight: 100
                port: 8080' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshHTTPRoute
name: color-pinning-blu
mesh: default
labels:
  kuma.io/origin: global
spec:
  targetRef:
    kind: MeshService
    name: client-blu
  to:
    - targetRef:
        kind: MeshMultiZoneService
        name: flight-control-all
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: "/"
          default:
            backendRefs:
              - kind: MeshMultiZoneService
                name: flight-control-blu
                weight: 100
                port: 8080' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 4: Gateway Entry

```bash
kubectl apply -f 04b-gateway.yaml
kubectl apply -f 04c-httproute.yaml
```

---

## 3. Validating the Chain

When you run the demo script (`./05-demo.sh`), you should see a nested JSON response proving the full Kong Air chain:

```json
{
  "service": "check-in-api",
  "color": "blu",
  "pod": "check-in-api-blu-abc123",
  "node": "eks-worker-1",
  "backend_call": {
    "url": "http://flight-control-all.mzsvc.kong-air-production.mesh.local:1027",
    "response": {
      "service": "flight-control",
      "color": "blu",
      "pod": "flight-control-blu-def456"
    }
  }
}
```

*   **Affinity**: The `backend_call.response.color` matches the top-level `color`.
*   **Abstraction**: The `url` field shows that `check-in-api` used the **color-agnostic** MMZS address.

---

## 4. Summary Findings

- **Architecture**: Kong Air uses labels on the `Dataplane` (Envoy sidecar) to define logical rings like `color: blu`.
- **Failover**: If `flight-control-blu` fails in the East cluster, `check-in-api-blu` will automatically reach `flight-control-blu` in the West cluster without manual intervention.
- **Simplicity**: Developers just call `flight-control-all.mzsvc.kong-air-production.mesh.local`. The mesh handles the rest.
