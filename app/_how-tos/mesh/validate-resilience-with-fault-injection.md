---
title: Validate resilience with fault injection
content_type: how_to
permalink: /mesh/scenarios/validate-resilience-with-fault-injection/
description: Learn how to use MeshFaultInjection to proactively test your service mesh resilience. Validate retries, timeouts, and circuit breakers by simulating real-world failures.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I test my microservices for resilience?
  a: |
    Use **MeshFaultInjection** to proactively test your "sad paths":
    1. **Simulate Errors** by aborting requests with specific HTTP status codes (for example, 503).
    2. **Simulate Latency** by injecting fixed delays into requests.
    3. **Validate Defenses** like `MeshRetry` and `MeshCircuitBreaker` before they are needed in production.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment.
    - title: Resources
      content: |
        Workloads to target (for example, `flight-control`) and a client (for example, `check-in-api`) to generate traffic.
next_steps:
  - text: "Explore by role"
    url: "/mesh/scenarios/persona/"
related_resources:
  - text: MeshFaultInjection
    url: /mesh/policies/meshfaultinjection/
  - text: MeshRetry
    url: /mesh/policies/meshretry/
  - text: MeshCircuitBreaker
    url: /mesh/policies/meshcircuitbreaker/
---
## Why inject faults?

Traditional testing usually focuses on the "Happy Path." Fault injection allows you to test the "Sad Path":
*   Validate Retries: Does your `MeshRetry` policy actually recover from a 503 error?
*   Test Timeouts: How does your UI react when the API takes 30 seconds to respond?
*   Verify Circuit Breakers: Does the circuit trip and stop traffic when a service is flooded with errors?

## Using MeshFaultInjection

The `MeshFaultInjection` policy allows you to introduce three types of failure during a request:

### HTTP abort (error simulation)
Immediately return a specific HTTP status code for a percentage of requests. See [MeshFaultInjection](/mesh/policies/meshfaultinjection/) for the full `abort` field definitions.

{:.info}
> Use `kind: Dataplane` with `labels` in `targetRef` to select the workloads being faulted. The `rules` block then names the callers whose requests should be faulted, using their SPIFFE identities. A `Prefix` match against the trust domain faults every caller; an `Exact` match faults one specific caller. (The older top-level `kind: MeshService` / `MeshSubset` selectors and the `spec.from` block are legacy forms, see the compatibility note after the example.)

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

To fault only a specific caller, swap the `Prefix` matcher for an `Exact` match against that caller's SPIFFE ID, for example `spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/passenger-portal`. This ties chaos targeting to authenticated identity rather than topology.

{:.info}
> Legacy `spec.from` form. Older policies select callers with a `spec.from[].targetRef` (for example `kind: Mesh`) instead of `rules[].matches[].spiffeID`. It still works for backward compatibility, but prefer `rules` with SPIFFE matchers for new policies.

{:.info}
> ZoneEgress-specific chaos in 2.14. The same rules model can fault a single external destination flowing through mesh-scoped zone egress by matching on SNI:

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

### HTTP delay (latency simulation)
Introduce a fixed delay before the request is processed, simulating a slow dependency. See [MeshFaultInjection](/mesh/policies/meshfaultinjection/) for the full `delay` field definitions.

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

### Response rate limit (throttling simulation)
Limit the speed at which the response body is delivered to the client. See [MeshFaultInjection](/mesh/policies/meshfaultinjection/) for the full `responseBandwidth` field definitions.

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
          - responseBandwidth:
              limit: "1kbps"
              percentage: 100
```

## Strategic chaos: the blast radius

One of the biggest risks of chaos engineering is accidentally breaking things for real users. Use the `targetRef` system to limit the "Blast Radius":

1.  Start with Header Matches: Only inject faults if a specific header (for example, `x-chaos: true`) is present. This allows developers to test in production without affecting customers.
2.  Target Non-Critical Zones: Run tests in `zone: dev` or `env: staging` before moving to production.
3.  Low Percentages: Start with a `1%` failure rate and slowly increase it as your confidence grows.

## Validate

1. Confirm the HTTP abort fires for roughly the configured `percentage: 10`. From `check-in-api`, send a batch of requests to `flight-control` and count failures:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- sh -c '
   ok=0; aborted=0
   for i in $(seq 1 50); do
     if wget -q -T 5 -O /dev/null http://flight-control.kong-air-production.svc.cluster.local:8080/; then
       ok=$((ok+1))
     else
       aborted=$((aborted+1))
     fi
   done
   echo "ok=$ok aborted=$aborted"
   '
   ```

   Expected output: roughly 1 in 10 requests fails, for example:

   ```text
   ok=45 aborted=5
   ```
   {:.no-copy-code}

   confirming the `abort` fault (`httpStatus: 503`) fires for about `percentage: 10` of requests.

1. Confirm the HTTP delay adds the configured `5s` for roughly half of requests. From `flight-control`, time a batch of requests to `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- sh -c '
   for i in $(seq 1 6); do
     start=$(date +%s)
     wget -q -T 10 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/
     end=$(date +%s)
     echo "request $i: $((end-start))s"
   done
   '
   ```

   Expected output: about half the requests return immediately and the rest take around 5 seconds longer, for example:

   ```text
   request 1: 0s
   request 2: 5s
   request 3: 0s
   request 4: 5s
   request 5: 0s
   request 6: 0s
   ```
   {:.no-copy-code}

   confirming the `delay` fault (`value: 5s`) fires for about `percentage: 50` of requests.
