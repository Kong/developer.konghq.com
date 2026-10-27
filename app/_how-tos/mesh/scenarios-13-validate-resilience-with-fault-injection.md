---
title: Validate resilience with fault injection
content_type: how_to
permalink: /mesh/validate-resilience-with-fault-injection/
description: Use MeshFaultInjection to make a Kong Air service return errors, add latency, and slow its responses, so you can see how its callers handle failures.
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
  position: 13
tldr:
  q: How do I test my services for resilience?
  a: |
    Create a `MeshFaultInjection` that targets the destination proxies and matches the caller by its SPIFFE ID, then check the effect:
    1. Use `abort` to return an HTTP status code, such as `503`, and simulate errors.
    2. Use `delay` to add a fixed delay and simulate latency.
    3. Use `responseBandwidth` to slow the response body and simulate a saturated dependency.
faqs:
  - q: Why doesn't my fault work?
    a: |
      Check the following:
      * The caller can already reach the destination. If a `MeshTrafficPermission` denies the caller, it gets `403 Forbidden`, and you never see the injected fault.
      * The `matches` entry matches the caller's SPIFFE ID. The trust domain comes from the `MeshIdentity` that issues the caller's certificate.
      * The mesh treats the destination port as HTTP. On a plain TCP port, the proxy adds no fault filter. For how a port's protocol is set, see [Ports](/mesh/meshservice/#ports).
      * The new configuration reached the proxy. The control plane pushes policy changes over xDS within about 10 seconds, without a restart.
  - q: Can I apply several fault injection policies at the same time?
    a: |
      Yes, but the results are hard to read.
      When several policies select the same destination, the proxy adds their faults as separate filters and runs them in sequence.
      An abort that fires stops the request, so a delay from another policy never runs.
      With one policy at a time, you can attribute each result to the policy that you applied.
  - q: How do I fault every caller instead of one?
    a: |
      Replace the `Exact` match with a `Prefix` match on the trust domain, such as `spiffe://kong-air-mesh.zone1.mesh.local`.
      The fault then applies to every caller whose SPIFFE ID starts with that value.
  - q: How do I keep the blast radius of a fault experiment small?
    a: |
      The blast radius is the set of requests that the fault affects.
      Three controls limit it, from broadest to narrowest:
      1. `targetRef` picks the destination proxies. Select a non-production workload, such as one with an `env: staging` label.
      1. `matches` picks the callers by `spiffeID`. Use `type: Exact` to fault the requests from one workload identity.
      1. `percentage` picks how often the fault fires. Start at `1` and raise it as your confidence grows.

      `matches` can't select HTTP headers, methods, or paths, so a fault applies to every request from a matching identity to the targeted workload.
      For how each selector works, see [Policy targeting](/mesh/policy-targeting/).
  - q: How do I fault one external dependency?
    a: |
      Target the mesh-scoped zone egress, and match the `MeshExternalService` by its Server Name Indication (SNI).
      The other destinations that share the zone egress aren't affected:

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
              - sni:
                  type: Exact
                  value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.aeropay-api.80
            default:
              http:
                - abort:
                    httpStatus: 503
                    percentage: 50
      ```

      For how to find the SNI, see [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).
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

Fault injection tests how callers behave when a destination fails or slows down.
In this guide, make the `check-in-api` sidecar fail the requests from `flight-control` in three ways, one at a time, and check the effect of each one.

## Record the baseline

Check that `flight-control` can call `check-in-api` before you inject a fault, so you can tell an injected fault apart from a permission denial or a broken deployment:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- \
  wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

The command returns immediately and prints the name of the Pod that responded.

## Return errors

1. Create a `MeshFaultInjection` that makes the `check-in-api` sidecar return `503` to `flight-control`, without forwarding the request to the application:

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
               type: Exact
               value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
         default:
           http:
             - abort:
                 httpStatus: 503
                 percentage: 100
   EOF
   ```

1. Call `check-in-api` from `flight-control`, and print the response status:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -S -q -T 5 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The `check-in-api` sidecar returns `503` before the request reaches the application, so `wget` reports a failure:

   ```text
     HTTP/1.1 503 Service Unavailable
   wget: server returned error: HTTP/1.1 503 Service Unavailable
   ```
   {:.no-copy-code}

   {:.info}
   > It can take a few seconds for the policy to apply, if you still get a 200 response, wait and try again.

1. Delete the abort policy:

   ```sh
   kubectl delete meshfaultinjection test-check-in-api-abort -n kong-air-production
   ```

## Add latency

1. Create a `MeshFaultInjection` that makes the `check-in-api` sidecar wait 5 seconds before it forwards each request from `flight-control`:

   ```sh
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
               type: Exact
               value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
         default:
           http:
             - delay:
                 value: 5s
                 percentage: 100
   EOF
   ```

1. Call `check-in-api` from `flight-control`, with a `wget` timeout longer than the delay:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 15 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   After about 5 seconds, the `flight-control` sidecar ends the request:

   ```text
   wget: server returned error: HTTP/1.1 504 Gateway Timeout
   ```
   {:.no-copy-code}

   The `flight-control-timeout` policy from [Target workloads and services](/mesh/target-workloads-and-services/) gives `flight-control` a 5-second request timeout, so the caller stops waiting before the delayed response arrives.

1. Delete the delay policy:

   ```sh
   kubectl delete meshfaultinjection test-check-in-api-latency -n kong-air-production
   ```

## Slow down responses

1. Create a 3 KiB file in the `check-in-api` container, which serves it on `/manifest.bin`.
   The Pod name that `check-in-api` returns on `/` is too short to show a bandwidth limit, and a larger file would take longer than the 5-second request timeout of `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -c check-in-api -- \
     sh -c 'head -c 3072 /dev/urandom > /tmp/manifest.bin'
   ```

1. Create a `MeshFaultInjection` that limits each `check-in-api` response to `flight-control` to 1 kbps.
   Unlike a delay, it forwards the request right away and slows the response body on its way back:

   ```sh
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
               type: Exact
               value: spiffe://internal.kongair.com/ns/kong-air-production/sa/flight-control
         default:
           http:
             - responseBandwidth:
                 limit: "1kbps"
                 percentage: 100
   EOF
   ```

1. Download the file from `flight-control`, and print the time before and after the download:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- sh -c \
     'date +%s; wget -q -T 60 -O /dev/null http://check-in-api.kong-air-production.svc.cluster.local:8080/manifest.bin; date +%s'
   ```

   The two timestamps are about 3 seconds apart, because the `check-in-api` sidecar sends the 3 KiB body at 1 KiB per second:

   ```text
   1792750000
   1792750003
   ```
   {:.no-copy-code}

## Validate

1. Delete the throttle policy:

   ```sh
   kubectl delete meshfaultinjection test-check-in-api-throttle -n kong-air-production
   ```

1. Call `check-in-api` from `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- \
     wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The command prints the Pod name immediately, as in the baseline, so no fault remains.
