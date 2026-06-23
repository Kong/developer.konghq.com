---
title: "Chaos Engineering: Validating Resilience with Fault Injection"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Learn how to use MeshFaultInjection to proactively test your service mesh resilience. Validate retries, timeouts, and circuit breakers by simulating real-world failures.
products:
  - mesh
tldr:
  q: How do I test my microservices for resilience?
  a: |
    Use **MeshFaultInjection** to proactively test your "sad paths":
    1. **Simulate Errors** by aborting requests with specific HTTP status codes (e.g., 503).
    2. **Simulate Latency** by injecting fixed delays into requests.
    3. **Validate Defenses** like `MeshRetry` and `MeshCircuitBreaker` before they are needed in production.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment.
    - title: Resources
      content: |
        Workloads to target (e.g., `flight-control`) and a client (e.g., `check-in-api`) to generate traffic.
next_steps:
  - text: "Explore the Persona Guides"
    url: "/mesh/scenarios/persona/"
---
## 1. Why Inject Faults?

Traditional testing usually focuses on the "Happy Path." Fault injection allows you to test the "Sad Path":
*   **Validate Retries**: Does your `MeshRetry` policy actually recover from a 503 error?
*   **Test Timeouts**: How does your UI react when the API takes 30 seconds to respond?
*   **Verify Circuit Breakers**: Does the circuit trip and stop traffic when a service is flooded with errors?

## 2. Using MeshFaultInjection

The `MeshFaultInjection` policy allows you to introduce three types of failure during a request:

### 2.1 HTTP Abort (Error Simulation)
Immediately return a specific HTTP status code for a percentage of requests.

{% tip %}
Use `kind: Dataplane` with `labels` in `targetRef` to select the workloads being faulted. The `rules` block then names the callers whose requests should be faulted, using their SPIFFE identities. A `Prefix` match against the trust domain faults every caller; an `Exact` match faults one specific caller. (The older top-level `kind: MeshService` / `MeshSubset` selectors and the `spec.from` block are legacy forms, see the compatibility note after the example.)
{% endtip %}

{% navtabs "fault-abort" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-resilience
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshFaultInjection
name: test-flight-control-resilience
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

To fault only a specific caller, swap the `Prefix` matcher for an `Exact` match against that caller's SPIFFE ID, for example `spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/passenger-portal`. This ties chaos targeting to authenticated identity rather than topology.

{% tip %}
Legacy `spec.from` form. Older policies select callers with a `spec.from[].targetRef` (for example `kind: Mesh`) instead of `rules[].matches[].spiffeID`. It still works for backward compatibility, but prefer `rules` with SPIFFE matchers for new policies.
{% endtip %}

{% tip %}
ZoneEgress-specific chaos in 2.14. The same rules model can fault a single external destination flowing through mesh-scoped zone egress by matching on **SNI**:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: zone-egress-fault-injection
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  rules:
    - matches:
        # SNI format: sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>
        # See the MeshExternalService scenario for how to derive this value.
        - sni:
            type: Exact
            value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.aeropay-api.80
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 50
```

That lets Kong Air inject failures for one external dependency without disturbing every other destination sharing the same zone egress proxy.
{% endtip %}

### 2.2 HTTP Delay (Latency Simulation)
Introduce a fixed delay before the request is processed, simulating a slow dependency.

{% navtabs "fault-delay" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-check-in-api-latency
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - delay:
              value: 5s
              percentage: 50' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshFaultInjection
name: test-check-in-api-latency
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - delay:
              value: 5s
              percentage: 50' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
The delay duration field is named `value` (not `fixedDelay`). The `percentage` field accepts an integer or decimal string (e.g., `10` or `"10.0"`).
{% endtip %}

### 2.3 Response Rate Limit (Throttling Simulation)
Limit the speed at which the response body is delivered to the client.

{% navtabs "fault-rate-limit" %}
{% navtab "Kubernetes (Zone CP)" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-throttle
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - responseRateLimit:
              bandwidth: "1kbps"
              percentage: 100
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```yaml
type: MeshFaultInjection
name: test-flight-control-throttle
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://kong-air-mesh.mesh.local
      default:
        http:
          - responseRateLimit:
              bandwidth: "1kbps"
              percentage: 100
```
{% endnavtab %}
{% endnavtabs %}

## 3. Strategic Chaos: The Blast Radius

One of the biggest risks of chaos engineering is accidentally breaking things for real users. Use the **`targetRef`** system to limit the "Blast Radius":

1.  **Start with Header Matches**: Only inject faults if a specific header (e.g., `x-chaos: true`) is present. This allows developers to test in production without affecting customers.
2.  **Target Non-Critical Zones**: Run tests in `zone: dev` or `env: staging` before moving to production.
3.  **Low Percentages**: Start with a `1%` failure rate and slowly increase it as your confidence grows.
