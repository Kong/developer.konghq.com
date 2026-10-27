---
title: Target workloads and services
content_type: how_to
permalink: /mesh/target-workloads-and-services/
description: Scope {{site.mesh_product_name}} policies to a group of proxies with a Dataplane label selector, and to a named destination with a MeshService.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
  - kongctl
products:
  - mesh
works_on:
  - on-prem
  - konnect
series:
  id: mesh-kong-air-scenario
  position: 4
tldr:
  q: How do I target groups of proxies and services?
  a: |
    Use two selectors:
    1. A top-level `targetRef` of kind `Dataplane` with `labels`, to scope a policy to a group of proxies, such as a zone or a team.
    2. A `MeshService` in `spec.to[].targetRef` or a route's `backendRefs`, to address one named destination, such as a canary variant.
next_steps:
  - text: "How-to: Deploy an OpenTelemetry collector"
    url: "/mesh/deploy-an-opentelemetry-collector/"
related_resources:
  - text: MeshService
    url: /mesh/meshservice/
  - text: Policy targeting
    url: /mesh/policy-targeting/
---

Kong Air scopes policies in two ways.
Some settings apply to a group of proxies, such as every sidecar in one zone.
Other settings apply to one named destination, such as the canary version of a service.
A `Dataplane` label selector covers the first case, and a `MeshService` covers the second.
For the full targeting model, see [Policy targeting](/mesh/policy-targeting/).

## Select a group of proxies with Dataplane labels

Kong Air gives every sidecar in `zone1` a 30-second request timeout, which is longer than the 15-second default, because some `zone1` services call slow back-office systems.
Create a `MeshTimeout` in the system namespace that selects these proxies by their computed `kuma.io/zone` label:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: regional-baseline
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: zone1
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 30s' | kubectl apply -f -
```


## Name destinations with MeshService

A `MeshService` names one destination, so a policy can address it in `spec.to[].targetRef`.
The zone control plane generates a `MeshService` for each Kubernetes `Service`.
For how the control plane generates them, see [MeshService sources](/mesh/meshservice/#meshservice-sources).

The team that owns `check-in-api` wants every caller to retry failed requests to it.
A policy in the destination's namespace becomes a producer policy when each `to[]` entry selects a local `MeshService` by `kuma.io/display-name`, `k8s.kuma.io/namespace`, and `kuma.io/zone`.
A producer policy reaches every caller of that destination, in any namespace.

1. Create a `MeshRetry` in `kong-air-production` that retries requests to `check-in-api` that fail with a `5xx` status:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshRetry
   metadata:
     name: check-in-api-retry
     namespace: kong-air-production
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     to:
       - targetRef:
           kind: MeshService
           labels:
             kuma.io/display-name: check-in-api
             k8s.kuma.io/namespace: kong-air-production
             kuma.io/zone: zone1
         default:
           http:
             numRetries: 3
             perTryTimeout: 2s
             retryOn:
               - 5xx' | kubectl apply -f -
   ```

1. Check that the control plane gave the policy the `producer` role:

   ```sh
   kubectl get meshretry check-in-api-retry -n kong-air-production \
     -o jsonpath='{.metadata.labels.kuma\.io/policy-role}{"\n"}'
   ```

1. Get the name of the policy on the global control plane.
   When the zone syncs a policy to the global control plane, the global control plane adds a hash suffix to its name:

   ```sh
   export RETRY_NAME=$(kongctl get mesh meshretries --mesh kong-air-mesh -o json \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" -r \
     --jq '.items[] | select(.name | startswith("check-in-api-retry")) | .name')
   ```

1. Inspect the policy to see which proxies it reaches:

   ```sh
   kongctl inspect mesh meshretry "$RETRY_NAME" \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" --mesh kong-air-mesh
   ```

   The policy reaches every proxy that can call `check-in-api`, including the zone ingress and zone egress of `kong-air-mesh`.
   On each of these proxies, the retries apply only to requests sent to `check-in-api`:

   ```text
   MESH           NAME
   kong-air-mesh  check-in-api-7c4756644b-gncds-55274dvzw…
   kong-air-mesh  flight-control-75c96dd768-j4mr6-f52w6v4…
   kong-air-mesh  kong-mesh-kong-air-mesh-egress-7c599494…
   kong-air-mesh  kong-mesh-kong-air-mesh-ingress-67bdc77…
   kong-air-mesh  passenger-portal-7f5f54d874-mfqvn-czw47…
   kong-air-mesh  passenger-portal-v2-7fbf8f8655-wzklr-42…
   ```
   {:.no-copy-code}

## Validate

Check that a `Dataplane` label selector scopes a policy to only the intended workloads in `kong-air-production`.

`kubectl get dataplanes` lists the `Dataplane` objects that the zone control plane creates for each pod.
It doesn't show which proxies a policy selected, because the control plane computes that selection.
Use [kongctl](/kongctl/) to ask the control plane instead.

1. List the proxies that the control plane knows about, with the labels that a `targetRef` can select:

   ```sh
   kongctl get mesh dataplanes --mesh kong-air-mesh -o yaml \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

   Each Kong Air workload has its own `app` and `version` labels, and the control plane adds the `kuma.io/` labels.
   The command lists every proxy in the mesh, including the zone ingress and zone egress.

1. Create a `MeshTimeout` that selects only `flight-control`:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTimeout
   metadata:
     name: flight-control-timeout
     namespace: kong-air-production
     labels:
       kuma.io/mesh: kong-air-mesh
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: flight-control
     to:
       - targetRef:
           kind: Mesh
         default:
           http:
             requestTimeout: 5s' | kubectl apply -f -
   ```

1. Get the names of both timeout policies on the global control plane:

   ```sh
   export BASELINE_NAME=$(kongctl get mesh meshtimeouts --mesh kong-air-mesh -o json \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" -r \
     --jq '.items[] | select(.name | startswith("regional-baseline")) | .name')
   export FLIGHT_CONTROL_TIMEOUT_NAME=$(kongctl get mesh meshtimeouts --mesh kong-air-mesh -o json \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" -r \
     --jq '.items[] | select(.name | startswith("flight-control-timeout")) | .name')
   ```

1. Inspect the zone-wide policy to see which proxies it selected:

   ```sh
   kongctl inspect mesh meshtimeout "$BASELINE_NAME" \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" --mesh kong-air-mesh
   ```

   The zone-wide policy selected every proxy in `zone1`.
   A policy in the system namespace gets the `system` role, which reaches every proxy in the zone.

   ```text
   MESH           NAME
   kong-air-mesh  check-in-api-7c4756644b-gncds-55274dvzw…
   kong-air-mesh  flight-control-75c96dd768-j4mr6-f52w6v4…
   kong-air-mesh  kong-mesh-kong-air-mesh-egress-7c599494…
   kong-air-mesh  kong-mesh-kong-air-mesh-ingress-67bdc77…
   kong-air-mesh  passenger-portal-7f5f54d874-mfqvn-czw47…
   kong-air-mesh  passenger-portal-v2-7fbf8f8655-wzklr-42…
   ```
   {:.no-copy-code}

1. Inspect the workload-scoped policy:

   ```sh
   kongctl inspect mesh meshtimeout "$FLIGHT_CONTROL_TIMEOUT_NAME" \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN" --mesh kong-air-mesh
   ```

   The workload-scoped policy selected only the proxy with a matching `app` label:

   ```text
   MESH           NAME
   kong-air-mesh  flight-control-75c96dd768-j4mr6-f52w6v4…
   ```
   {:.no-copy-code}

