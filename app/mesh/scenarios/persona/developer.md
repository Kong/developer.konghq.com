---
title: "Persona: Devin the Developer"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
description: A comprehensive deep-dive into how Devin uses {{site.mesh_product_name}} at Kong Air to manage traffic, ensure resilience, and optimize flight booking services.
products:
  - mesh
---

Devin is a Senior Software Engineer at **Kong Air**, on the **Passenger Experience** team. He owns the services that the airline's passengers see and interact with — `passenger-portal` (the booking and check-in UI) and `check-in-api` (the back-end that processes seat assignments and boarding passes). He does **not** own the operational core (`flight-control`), the ingress gateway (`booking-gateway`), or the underlying databases (`flight-db`); those belong to other teams. His job is to make his services fast, resilient, and observable while consuming everyone else's services safely.

### What Devin owns at Kong Air

{% mermaid %}
flowchart LR
  subgraph DEV["Devin's scope"]
    PP["passenger-portal"]
    CI["check-in-api"]
  end
  subgraph OTHERS["Owned by other teams"]
    BG["booking-gateway<br/>(Ollie)"]
    FC["flight-control<br/>(Ollie)"]
    DB[("flight-db<br/>(Infra)")]
    WX["weather-api<br/>(SaaS)"]
  end

  BG --> PP
  PP --> CI
  CI --> FC
  FC --> DB
  CI -.-> WX
{% endmermaid %}

The dashed arrow to `weather-api` is an external SaaS — Devin reaches it through a `MeshExternalService` that Ollie has configured. See the [Meet Kong Air section](/mesh/scenarios/introduction/#meet-kong-air) for the full picture.

## 1. Service discovery and consuming services Devin doesn't own

Devin's services need predictable hostnames for the things they call. Both the in-zone DNS naming (via `HostnameGenerator`) and the cross-zone abstraction (via `MeshMultiZoneService`) are typically set up by **Ollie the Operator** — they're cluster-wide concerns that live in the system namespace and apply to every service. Devin's job is to use them.

### Devin's view of in-zone DNS

Ollie has applied a single `HostnameGenerator` for the mesh. It generates a DNS name like `<service>.svc.kongair.mesh` for every `MeshService`. Devin just needs to know the convention:

| Service | Hostname Devin calls |
|---|---|
| `check-in-api` (Devin's own service) | `check-in-api.svc.kongair.mesh` |
| `flight-control` (Ollie's service) | `flight-control.svc.kongair.mesh` |

If Devin wanted to look at the `HostnameGenerator` resource itself, it lives in the system namespace:

```yaml
# Applied by Ollie, not Devin. Shown here for reference only.
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: kong-air-dns
  namespace: {{site.mesh_system_namespace}}
spec:
  template: "{% raw %}{{ .DisplayName }}.svc.kongair.mesh{% endraw %}"
  selector:
    meshService:
      matchLabels:
        kuma.io/mesh: kong-air-mesh
```

{% tip %}
On Kubernetes, Devin can call other in-cluster services directly by their Kubernetes service address (e.g. `check-in-api.kong-air-production.svc.cluster.local`) — the mesh transparently proxies that traffic. The HostnameGenerator just gives him a stable, mesh-native name that works the same in every zone.
{% endtip %}

### Devin's view of cross-zone services

When `passenger-portal` (running in Zone East) needs to call `flight-control` (which may be in East *or* West), Ollie has defined a `MeshMultiZoneService` that aggregates both zones into one logical service. Devin calls a single hostname and the mesh handles locality and failover.

```yaml
# Applied by Ollie. Devin consumes the resulting hostname.
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: flight-control
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: global
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: flight-control
  ports:
    - port: 80
      targetPort: 8080
      appProtocol: http
```

### External services

For the SaaS weather feed, Ollie has registered a `MeshExternalService`. Devin calls it like any other in-mesh service.

```yaml
# Applied by Ollie. Devin's check-in-api calls weather-api.ext.kongair.com.
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: weather-api
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: tls
  endpoints:
    - address: api.weather.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: api.weather.com
```

## 2. Traffic Management

Devin needs full control over how requests land on his services.

### Canary Routing with `MeshHTTPRoute`
Launching v2 of the passenger portal? Devin shifts 10% of traffic to verify its performance. The route applies to every client in the mesh, so the top-level `targetRef` is `Mesh`. (To roll out to a subset of clients first, swap the top level for `Dataplane` with a `labels:` selector — that's the modern way to scope a policy to a slice of the fleet. `MeshService`, `MeshServiceSubset`, and `MeshSubset` are no longer valid at the top level.)

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: passenger-portal-canary
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: passenger-portal
      rules:
        - matches: [{ path: { type: PathPrefix, value: / } }]
          default:
            backendRefs:
              - kind: MeshService
                name: passenger-portal-v1
                weight: 90
              - kind: MeshService
                name: passenger-portal-v2
                weight: 10
```

{% tip %}
**Use Explicit Resources for Rollouts**: Current Kuma builds can generate baseline `MeshService` resources automatically for workloads, but Devin still models versions like `v1` and `v2` as distinct **`MeshService`** entries when he wants independent routing and metrics for a rollout. See [Architecture Overview](/mesh/scenarios/architecture-overview/) for the modern resource model.
{% endtip %}

{% warning %}
### The Traffic Hierarchy: Routing vs. Load Balancing
It's easy to confuse `weight` in a route with load balancing, but they happen at different "layers":
1.  **Selection (The Route)**: `MeshHTTPRoute` uses `weight` to decide which **subset** (e.g., `v1` or `v2`) the request belongs to.
2.  **Distribution (The Strategy)**: Once a subset is chosen, `MeshLoadBalancingStrategy` decides which **specific instance (Pod)** within that subset receives the traffic.
{% endwarning %}

### Advanced Load Balancing
To ensure fair distribution across his backend instances, Devin configures the **MeshLoadBalancingStrategy**.

```yaml
kind: MeshLoadBalancingStrategy
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  to:
    - targetRef:
        kind: Mesh
      default:
        loadBalancer:
          type: LeastRequest # Send traffic to the least busy instance
```

### Safety with `MeshRateLimit`
To prevent a misbehaving client from overwhelming the check-in service during peak boarding times, Devin applies a rate limit.

```yaml
kind: MeshRateLimit
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  from:
    - targetRef:
        kind: Mesh
      default:
        local:
          http:
            requestRate:
              numRequests: 100
              interval: 1s
            onRateLimit:
              status: 429
```

{% tip %}
**Recommended for 2.14+ — use `rules`.** `MeshRateLimit.spec.from` is deprecated. The same policy as `rules`:

```yaml
kind: MeshRateLimit
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - default:
        local:
          http:
            requestRate:
              numRequests: 100
              interval: 1s
            onRateLimit:
              status: 429
```
{% endtip %}

## 3. Deep Resilience

Devin knows that failure is inevitable. He builds multiple layers of defense.

### Active Health Checks (`MeshHealthCheck`)
The mesh actively pings Devin's services to ensure they are ready to receive traffic.

```yaml
kind: MeshHealthCheck
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          path: /health
          interval: 5s
          unhealthyThreshold: 3
```

### Passive Health Checks (`MeshCircuitBreaker`)
If a specific instance of `check-in-api` starts returning 500s unexpectedly, the **Circuit Breaker** will temporarily eject it.

```yaml
kind: MeshCircuitBreaker
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  to:
    - targetRef:
        kind: Mesh
      default:
        outlierDetection:
          splitExternalAndLocalErrors: true
          baseEjectionTime: 30s
          detectors:
            totalFailures:
              consecutive: 5
```

### Self-Healing with `MeshRetry`
Transient network blips shouldn't reach the passenger. Devin configures automatic retries.

```yaml
kind: MeshRetry
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          numRetries: 3
          retryOn: [ "5xx", "connect_failure" ]
```

## 4. Observability

Devin needs to see what's happening inside his code. He uses **MeshMetric** to aggregate both sidecar metrics and custom application metrics (like "checkins_per_second").

```yaml
kind: MeshMetric
spec:
  targetRef:
    kind: MeshService
    name: check-in-api
  default:
    applications:
      - name: check-in-api
        path: /internal/prometheus
        port: 9090 # The application's custom metrics port
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
```

## 5. Gateway Integration

Finally, **booking-gateway** ({{site.base_gateway}}, owned by Ollie) is the entry point into Devin's services. Devin doesn't operate the gateway itself — he just makes sure his services play well with it:

*   **Ingress**: {{site.base_gateway}} terminates external HTTPS and forwards into the mesh. Passengers hit the gateway; the gateway routes to `passenger-portal`.
*   **Bridge**: It translates external JWT authentication into the mesh identity, so Devin's services see which passenger is making the request.

See the [Ingress mTLS Bridge](/mesh/scenarios/ingress-mtls-bridge/) scenario for the pattern Ollie uses to wire the gateway into the mesh.

---

By mastering these policies, Devin has turned **Kong Air** into a resilient, high-scale digital airline. He spends less time worrying about the network and more time building features that get passengers where they need to go.
