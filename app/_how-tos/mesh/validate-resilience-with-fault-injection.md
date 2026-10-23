---
title: Validate resilience with fault injection
content_type: how_to
permalink: /mesh/validate-resilience-with-fault-injection/
description: Use MeshFaultInjection to test how Kong Air services handle failures. Inject HTTP errors, delays, and slow responses to validate retries, timeouts, and circuit breakers.
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
series:
  id: mesh-kong-air-scenario
  position: 12
tldr:
  q: How do I test my microservices for resilience?
  a: |
    Create a `MeshFaultInjection` that targets the destination proxies and matches the callers by SPIFFE ID:
    1. Use `abort` to return an HTTP status code, such as `503`, and simulate errors.
    2. Use `delay` to add a fixed delay and simulate latency.
    3. Use `responseBandwidth` to slow the response body and simulate a saturated dependency.

    Then check that `MeshRetry`, `MeshTimeout`, and `MeshCircuitBreaker` handle these failures before you rely on them in production.
prereqs:
  inline:
    - title: A permitted request path
      content: |
        `MeshFaultInjection` faults only requests that reach the destination, so you need a call that already succeeds.
        The Kong Air `MeshTrafficPermission` allows `flight-control` to call `check-in-api`.
        So every example on this page faults `check-in-api` and sends requests from `flight-control`.
        If you fault a destination that the caller can't reach, `MeshTrafficPermission` returns `403 Forbidden`, and you never see the injected fault.
    - title: An HTTP port
      content: |
        The destination proxy adds the faults from the `http` block to its HTTP filter chain, so the mesh must treat the inbound port as HTTP.
        On a port that the mesh treats as plain TCP, the proxy adds no fault filter, and the policy does nothing.
        For how a port's protocol is set, see [Ports](/mesh/meshservice/#ports).
cleanup:
  inline:
    - title: Remove the fault injection policies
      include_content: md/mesh/v3/cleanup/fault-injection
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Prepare the mesh for production"
    url: "/mesh/prepare-the-mesh-for-production/"
related_resources:
  - text: MeshFaultInjection
    url: /mesh/policies/meshfaultinjection/
  - text: MeshRetry
    url: /mesh/policies/meshretry/
  - text: MeshCircuitBreaker
    url: /mesh/policies/meshcircuitbreaker/
---
## Why inject faults?

Fault injection tests how callers behave when a destination fails or slows down.
Kong Air uses `MeshFaultInjection` to make `check-in-api` return errors and slow responses.
Kong Air can then check that `MeshRetry`, `MeshTimeout`, and `MeshCircuitBreaker` policies handle these failures as expected.
For what the policy can simulate, see [MeshFaultInjection](/mesh/policies/meshfaultinjection/).

## Record the baseline

Check that `flight-control` can call `check-in-api` before you inject a fault.
This baseline lets you tell an injected fault apart from a permission denial or a broken deployment:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- \
  wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

The command returns immediately and prints the name of the pod that responded.
{:.no-copy-code}

## Inject faults with MeshFaultInjection

`MeshFaultInjection` can inject three types of failure into a request.
Each example uses `percentage: 100`, so you see the effect on the first request.
Lower the percentage after you trust the setup.

{:.warning}
> Apply one example at a time, and delete the previous policy before you apply the next one.
> When several policies select the same destination, the proxy adds their faults as separate filters and runs them in sequence.
> An abort that fires stops the request, so a delay from another policy never runs.
> With one policy at a time, you can attribute each result to the policy you applied.
> Wait up to 10 seconds after each change for the new configuration to reach the proxy.

### HTTP abort (error simulation)
An HTTP abort makes the `check-in-api` sidecar return an HTTP status code for a percentage of requests, without forwarding them to the application.
For the `abort` fields, see [The three faults](/mesh/policies/meshfaultinjection/#the-three-faults).

{:.info}
> The `targetRef` selects the `check-in-api` proxies, which inject the fault.
> The `rules` block selects the callers by their Secure Production Identity Framework for Everyone (SPIFFE) IDs.
> A `Prefix` match on the trust domain faults every caller in that trust domain, and an `Exact` match faults one caller.

Create a `MeshFaultInjection` that makes `check-in-api` return `503` to every caller in the trust domain:

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

To fault only one caller, replace the `Prefix` matcher with an `Exact` match on the caller's SPIFFE ID, such as `spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control`.

{:.info}
> A `MeshFaultInjection` on the mesh-scoped zone egress can also fault one external destination, by matching on its Server Name Indication (SNI):

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

With an SNI match, Kong Air injects failures for one external dependency, and the other destinations that share the zone egress aren't affected.

### HTTP delay (latency simulation)
An HTTP delay makes the `check-in-api` sidecar wait before it forwards the request, which simulates a slow dependency.
For the `delay` fields, see [The three faults](/mesh/policies/meshfaultinjection/#the-three-faults).

Delete the abort policy, then create a `MeshFaultInjection` that delays every request to `check-in-api` by 5 seconds:

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
A response rate limit makes the `check-in-api` sidecar slow down the response body.
For the `responseBandwidth` fields, see [The three faults](/mesh/policies/meshfaultinjection/#the-three-faults).

Delete the delay policy, then create a `MeshFaultInjection` that limits each `check-in-api` response to 1 kbps:

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

Unlike a delay, the response rate limit forwards the request right away and slows the response body on its way back.
To a client, the slow response looks like a saturated dependency.

## Limit the blast radius

The blast radius of a fault experiment is the set of requests that the fault affects.
Kong Air keeps the blast radius small with three controls, from broadest to narrowest:

1. `targetRef` picks the destination proxies. Select a non-production workload, such as one with an `env: staging` label, to keep the experiment away from customer traffic.
2. `matches` picks the callers by `spiffeID`. On the zone egress, `sni` picks one external destination instead. Use `spiffeID` with `type: Exact` to fault requests from one workload identity.
3. `percentage` picks how often the fault fires. Start at `1` and raise it as your confidence grows.

For how each selector works, see [Policy targeting](/mesh/policy-targeting/) and [`spec.rules[]`](/mesh/policy-targeting/#spec-rules).

{:.warning}
> `matches` cannot select on HTTP headers, methods, or paths.
> A fault applies to every request from a matching identity to the targeted workload.
> So identity and percentage are the controls that keep a production experiment small.

## Validate

Run each check while the matching policy is applied.
Delete the policy before you move to the next check.

1. Check that the HTTP abort fires.
   Call `check-in-api` from `flight-control`, and make `wget` print the response status:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -S -q -T 5 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The `check-in-api` sidecar returns `503`:

   ```text
     HTTP/1.1 503 Service Unavailable
   wget: server returned error: HTTP/1.1 503 Service Unavailable
   ```
   {:.no-copy-code}

   The sidecar in front of `check-in-api` returns the `503` status before the request reaches the application.
   `wget` exits with a non-zero code, so the command reports a failure.

1. Check that the HTTP delay fires.
   Give `wget` a timeout longer than the injected delay.
   Otherwise, `wget` gives up before the response arrives, and you can't tell a delay apart from an outage:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 15 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The command prints the same body as the baseline after about 5 seconds.
   {:.no-copy-code}

1. Check that the response rate limit fires.
   The `check-in-api` Pod name is only a few bytes, which arrives in well under a second even at 1 kbps.
   So create a 10 KiB file in the `check-in-api` container, which serves it on `/manifest.bin`:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -c check-in-api -- \
     sh -c 'head -c 10240 /dev/urandom > /tmp/manifest.bin'
   ```

1. Download the file from `flight-control`, and print the time before and after the download:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- sh -c \
     'date +%s; wget -q -T 60 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/manifest.bin; date +%s'
   ```

   The two timestamps are about 10 seconds apart, because the `check-in-api` sidecar sends the 10 KiB body at 1 KiB per second:

   ```text
   1792750000
   1792750010
   ```
   {:.no-copy-code}

1. Delete the throttle policy, and check that the fault is gone:

   ```sh
   kubectl delete meshfaultinjection test-check-in-api-throttle -n kong-air-production
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The baseline behavior returns, and the command prints the pod name immediately.
   {:.no-copy-code}

The control plane pushes policy changes to the proxies over xDS within about 10 seconds, without a restart.
If a result still shows the effect of the policy you deleted, wait and run the command again.
