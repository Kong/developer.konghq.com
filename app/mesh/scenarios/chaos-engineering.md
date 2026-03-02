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
        Workloads to target (e.g., `flight-control`) and a client (e.g., `client-blu`) to generate traffic.
next_steps:
  - text: "Advanced Envoy Customization: MeshProxyPatch"
    url: "/mesh/scenarios/mesh-proxy-patch/"
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
Use `kind: Dataplane` with `labels` in `targetRef` to select workloads. The older `kind: MeshService` approach is deprecated.
{% endtip %}

{% navtabs "fault-abort" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-flight-control-resilience
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshFaultInjection
name: test-flight-control-resilience
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-control
      color: blu
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### 2.2 HTTP Delay (Latency Simulation)
Introduce a fixed delay before the request is processed, simulating a slow dependency.

{% navtabs "fault-delay" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-check-in-api-latency
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - delay:
              value: 5s
              percentage: 50' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshFaultInjection
name: test-check-in-api-latency
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  from:
    - targetRef:
        kind: Mesh
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
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-file-storage-throttle
  namespace: kong-air-production
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: file-storage-svc
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - responseRateLimit:
              bandwidth: "1kbps"
              percentage: 100
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: MeshFaultInjection
name: test-file-storage-throttle
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: file-storage-svc
  from:
    - targetRef:
        kind: Mesh
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
