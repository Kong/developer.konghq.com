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

Devin is a Senior Software Engineer at **Kong Air**. He is responsible for the **Ticket Booking** ecosystem. His goal is to build a high-performance, resilient booking platform that handles millions of searches while integrating safely with external partners.

## 1. Discovery & Global Naming

Devin needs his services to be reachable by beautiful, predictable DNS names, regardless of which cloud or zone they are running in.

### Predictable DNS with HostnameGenerators
To avoid messy auto-generated names, Devin uses a **HostnameGenerator** to create a standard naming scheme for the airline.

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: kong-air-dns
  namespace: kuma-system
spec:
  template: "{% raw %}{{ .DisplayName }}.svc.kongair.mesh{% endraw %}"
  selector:
    meshService:
      matchLabels:
        kuma.io/mesh: default
```
Now, his service `ticket-booking` is reachable at `ticket-booking.svc.kongair.mesh`.

### Multi-Zone Services (MMZS)
For the global search system, Devin uses a **MeshMultiZoneService** to group instances across the US and EU clusters into a single logical host.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: global-flight-search
  namespace: kong-air
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: flight-search
  ports:
    - port: 80
      targetPort: 8080
      appProtocol: http
```

### External Services
The booking flow needs to talk to a **Legacy Seat Map** provider outside the mesh. Devin defines it as a **MeshExternalService** so it behaves like a domestic service.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: legacy-seat-map
  namespace: kong-air
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: tls
  endpoints:
    - address: seats.external-partner.com
      port: 443
```

## 2. Traffic Management

Devin needs full control over how requests land on his services.

### Canary Routing with `MeshHTTPRoute`
Launching v2 of the booking engine? Devin shifts 10% of traffic to verify its performance.

```yaml
kind: MeshHTTPRoute
spec:
  targetRef:
    kind: MeshService
    name: booking-gateway
  to:
    - targetRef:
        kind: MeshService
        name: ticket-booking
      rules:
        - matches: [{ path: { type: PathPrefix, value: / } }]
          default:
            backendRefs:
              - kind: MeshService
                name: ticket-booking-v1
                weight: 90
              - kind: MeshService
                name: ticket-booking-v2
                weight: 10
```

{% tip %}
**Use Explicit Resources**: Devin manages versions (like `v1` and `v2`) by creating distinct **`MeshService`** entries for each version. This provides better observability and matches the standard Kubernetes service model. See [Architecture Overview](/mesh/scenarios/architecture-overview/) for the modern resource model.
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
    name: ticket-booking
  to:
    - targetRef:
        kind: Mesh
      default:
        loadBalancer:
          type: LeastRequest # Send traffic to the least busy instance
```

### Safety with `MeshRateLimit`
To prevent the mobile app from accidentally DDoS-ing the booking engine, Devin applies a rate limit.

```yaml
kind: MeshRateLimit
spec:
  targetRef:
    kind: MeshService
    name: ticket-booking
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

## 3. Deep Resilience

Devin knows that failure is inevitable. He builds multiple layers of defense.

### Active Health Checks (`MeshHealthCheck`)
The mesh actively pings Devin's services to ensure they are ready to receive traffic.

```yaml
kind: MeshHealthCheck
spec:
  targetRef:
    kind: MeshService
    name: flight-search
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
If a specific instance of the booking service starts returning 500s unexpectedly, the **Circuit Breaker** will temporarily eject it.

```yaml
kind: MeshCircuitBreaker
spec:
  targetRef:
    kind: MeshService
    name: ticket-booking
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
    name: ticket-booking
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          numRetries: 3
          retryOn: [ "5xx", "connect_failure" ]
```

## 4. Observability

Devin needs to see what's happening inside his code. He uses **MeshMetric** to aggregate both sidecar metrics and custom application metrics (like "bookings_per_second").

```yaml
kind: MeshMetric
spec:
  targetRef:
    kind: MeshService
    name: ticket-booking
  default:
    applications:
      - name: booking-app
        path: /internal/prometheus
        port: 9090 # The application's custom metrics port
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
```

## 5. Gateway Integration

Finally, Devin connects **Kong Gateway** to the mesh. This allows external passengers to enter the "Ticket Booking" service while benefiting from the same mTLS security and observability as internal traffic.

*   **Ingress**: Kong Gateway acts as the entry point for the "Kong Air" mobile app.
*   **Bridge**: It translates external JWT authentication into the mesh identity, allowing Devin's services to see which passenger is making the request.

---

By mastering these policies, Devin has turned **Kong Air** into a resilient, high-scale digital airline. He spends less time worrying about the network and more time building features that get passengers where they need to go.
