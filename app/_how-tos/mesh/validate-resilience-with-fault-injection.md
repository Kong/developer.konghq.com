---
title: Validate resilience with fault injection
content_type: how_to
permalink: /mesh/validate-resilience-with-fault-injection/
description: Learn how to use MeshFaultInjection to proactively test your service mesh resilience. Validate retries, timeouts, and circuit breakers by simulating real-world failures.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
tldr:
  q: How do I test my microservices for resilience?
  a: |
    Use **MeshFaultInjection** to proactively test your "sad paths":
    1. **Simulate Errors** by aborting requests with specific HTTP status codes (for example, 503).
    2. **Simulate Latency** by injecting fixed delays into requests.
    3. **Validate Defenses** like `MeshRetry` and `MeshCircuitBreaker` before they are needed in production.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
    - title: A permitted request path
      content: |
        `MeshFaultInjection` faults requests that reach the destination, so you need a call that already succeeds. The Kong Air `MeshTrafficPermission` allows `flight-control` to call `check-in-api`, so every example here faults `check-in-api` and drives it from `flight-control`. If you fault a destination the caller is not authorized to reach, you get a `403 Forbidden` from `MeshTrafficPermission` and never see the injected fault.
    - title: An HTTP port
      content: |
        Faults from the `http` block are added to the destination's HTTP filter chain, so the inbound port must be known to the mesh as HTTP. A port the mesh treats as plain TCP gets no fault filter and the policy silently does nothing.
cleanup:
  inline:
    - title: Remove the fault injection policies
      include_content: md/mesh/v3/cleanup/fault-injection
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Explore by role"
    url: "/mesh/persona/"
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

## Record the baseline

Confirm the call you are about to fault works today. Without this, you cannot tell an injected fault apart from a permission denial or a broken deployment:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- \
  wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

Expected result: the command returns immediately and prints the responding pod name.
{:.no-copy-code}

## Using MeshFaultInjection

The `MeshFaultInjection` policy allows you to introduce three types of failure during a request. Each example uses `percentage: 100` so you can see the effect on the first request. Lower the percentage once you trust the setup.

{:.warning}
> Apply one example at a time, and delete the previous policy before applying the next. Faults from several policies that select the same destination are added as separate filters and run in sequence, so an abort that fires short-circuits the request and a delay configured elsewhere never runs. Working with one policy at a time keeps what you observe attributable to what you applied. Allow a few seconds after each change for the new configuration to reach the proxy.

### HTTP abort (error simulation)
Immediately return a specific HTTP status code for a percentage of requests. See [MeshFaultInjection](/mesh/policies/meshfaultinjection/) for the full `abort` field definitions.

{:.info}
> Use `kind: Dataplane` with `labels` in `targetRef` to select the workloads being faulted. The `rules` block then names the callers whose requests should be faulted, using their SPIFFE identities. A `Prefix` match against the trust domain faults every caller; an `Exact` match faults one specific caller.

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-check-in-api-abort
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
            value: spiffe://kong-air-mesh.zone1.mesh.local
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 100
EOF
```

To fault only a specific caller, swap the `Prefix` matcher for an `Exact` match against that caller's SPIFFE ID, for example `spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control`. This ties chaos targeting to authenticated identity rather than topology.

{:.info}
> The same rules model can fault a single external destination flowing through mesh-scoped zone egress by matching on SNI:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: zone-egress-fault-injection
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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

```sh
kubectl delete meshfaultinjection test-check-in-api-abort -n kong-air-production
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
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
            value: spiffe://kong-air-mesh.zone1.mesh.local
      default:
        http:
          - delay:
              value: 5s
              percentage: 100
EOF
```

### Response rate limit (throttling simulation)
Limit the speed at which the response body is delivered to the client. See [MeshFaultInjection](/mesh/policies/meshfaultinjection/) for the full `responseBandwidth` field definitions.

```sh
kubectl delete meshfaultinjection test-check-in-api-latency -n kong-air-production
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: test-check-in-api-throttle
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
            value: spiffe://kong-air-mesh.zone1.mesh.local
      default:
        http:
          - responseBandwidth:
              limit: "1kbps"
              percentage: 100
EOF
```

`limit` is a bandwidth, written in `Gbps`, `Mbps`, or `kbps`. Unlike `delay`, it does not hold the request back before it is processed; it slows the response body on the way out, which is what a saturated dependency looks like to a client.

## Strategic chaos: the blast radius

One of the biggest risks of chaos engineering is accidentally breaking things for real users. `MeshFaultInjection` gives you three controls for limiting the blast radius, and they narrow it in this order:

1.  Pick the destination with `targetRef`. A `Dataplane` selector with `labels` faults one workload. Selecting a non-production workload, for example with `kuma.io/zone: dev` or an `env: staging` label your platform sets, keeps the experiment away from customer traffic entirely.
2.  Pick the caller with `matches`. A rule matches on `spiffeID` or on `sni`, and nothing else. Use `spiffeID` with `type: Exact` to fault requests from one named workload identity, `type: Prefix` to fault a whole trust domain, or `sni` with `type: Exact` to fault one external destination leaving through a zone egress.
3.  Pick how often with `percentage`. Start at `1` and raise it as your confidence grows.

{:.warning}
> `matches` cannot select on HTTP headers, methods, or paths. A fault applies to every request from a matching identity to the targeted workload, so identity and percentage are what keep a production experiment small.

## Validate

Run these against whichever policy you currently have applied. Delete it before moving to the next one.

1. Confirm the HTTP abort fires. Call `check-in-api` from `flight-control` and ask `wget` to print the response status:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -S -q -T 5 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output:

   ```text
     HTTP/1.1 503 Service Unavailable
   wget: server returned error: HTTP/1.1 503 Service Unavailable
   ```
   {:.no-copy-code}

   The status comes from the sidecar in front of `check-in-api`, not from the application. `wget` exits non-zero, so the command reports a failure.

1. Confirm the HTTP delay fires. Give `wget` a timeout longer than the injected delay, otherwise it gives up before the response arrives and you cannot tell a delay apart from an outage:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 15 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected result: the same body as the baseline, printed after about 5 seconds instead of immediately.
   {:.no-copy-code}

1. Confirm the response rate limit fires. The request is processed straight away, but the body arrives slowly:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 60 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected result: the same body as the baseline, taking several seconds to arrive even though it is only a few bytes.
   {:.no-copy-code}

1. Confirm the fault is gone once the policy is removed:

   ```sh
   kubectl delete meshfaultinjection test-check-in-api-throttle -n kong-air-production
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected result: the baseline behavior returns, printing the pod name immediately.
   {:.no-copy-code}

Policies reach the proxies over xDS within a few seconds and need no restart. If a result looks like the policy you just deleted, wait and run the command again.
