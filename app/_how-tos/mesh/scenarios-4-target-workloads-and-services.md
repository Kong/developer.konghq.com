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

    To check which proxies a policy selected, run `kongctl inspect mesh <type> <name>.<namespace>`.
cleanup:
  inline:
    - title: Remove the timeout policies
      include_content: md/mesh/v3/cleanup/target-workloads-and-services
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
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

A top-level `targetRef` of kind `Dataplane` with `labels` selects proxies by the labels that the control plane computes for each one.
These labels combine the pod's own labels, such as `app` and `version`, with mesh labels such as `kuma.io/zone` and `k8s.kuma.io/namespace`.
The control plane sets the `kuma.io/` labels, so you don't set them yourself.
For the accepted values, see [`spec.targetRef`](/mesh/policy-targeting/#spec-targetref).

### Example: regional timeouts

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

Kong Air manages rollout variants, such as a canary and a stable version, as separate `MeshService` resources.
Each `MeshService` gives one variant a name that policies can address in `spec.to[].targetRef` and routes can address in `backendRefs`.
Its status reports how many proxies its selector matched and how many are healthy, so you can check each variant on its own.

The zone control plane also generates a `MeshService` for each Kubernetes `Service`.
For how the control plane generates them, see [MeshService sources](/mesh/meshservice/#meshservice-sources).

{:.info}
> For a step-by-step rollout with separate `MeshService` resources, see [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/).

## Validate

Check that a `Dataplane` label selector scopes a policy to only the intended workloads in `kong-air-production`.

`kubectl get dataplanes` lists the `Dataplane` objects that the zone control plane creates for each pod.
It doesn't show which proxies a policy selected, because the control plane computes that selection.
Use [kongctl](/kongctl/) to ask the control plane instead.

1. List the proxies that the control plane knows about, with the labels that a `targetRef` can select:

   ```sh
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   Each Kong Air workload has its own `app` and `version` labels, and the control plane adds the `kuma.io/` labels.
   The following output shows the `flight-control` entry and omits the other two proxies:

   ```yaml
   items:
       - creationTime: "2026-09-23T10:42:26Z"
         kri: kri_dp_kong-air-mesh_zone1_kong-air-production_flight-control-75c96dd768-j4mr6_
         labels:
           app: flight-control
           k8s.kuma.io/namespace: kong-air-production
           k8s.kuma.io/service-account: flight-control
           kubernetes.io/hostname: k3d-kuma-1-server-0
           kuma.io/display-name: flight-control-75c96dd768-j4mr6
           kuma.io/env: kubernetes
           kuma.io/mesh: kong-air-mesh
           kuma.io/origin: zone
           kuma.io/workload: flight-control
           kuma.io/zone: zone1
           pod-template-hash: 75c96dd768
           version: v1
         mesh: kong-air-mesh
         modificationTime: "2026-09-23T10:42:26Z"
         name: flight-control-75c96dd768-j4mr6.kong-air-production
         networking:
           address: 10.42.0.32
           admin:
               port: 9901
           inbound:
               - health:
                   ready: true
                 port: 8080
                 protocol: http
         type: Dataplane
   ```
   {:.no-copy-code}

1. Create a `MeshTimeout` that selects only `flight-control`, with the same `Dataplane` label selector as the [regional timeouts example](#example-regional-timeouts).
   `flight-control` must fail fast, so the policy sets a 5-second request timeout.
   This policy targets one workload instead of a whole zone, so you create it in the application namespace:

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

1. Inspect the zone-wide policy to see which proxies it selected.
   Name the policy as `<name>.<namespace>`:

   ```sh
   kongctl inspect mesh meshtimeout regional-baseline.{{site.mesh_namespace}} \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh
   ```

   The zone-wide policy selected all three proxies.
   A policy in the system namespace gets the `system` role, which reaches every proxy in the zone.
   For more information, see [Policy scope](/mesh/policy-targeting/#policy-scope).

   ```text
   MESH           NAME
   kong-air-mesh  check-in-api-7c4756644b-gncds.kong-air-…
   kong-air-mesh  flight-control-75c96dd768-j4mr6.kong-ai…
   kong-air-mesh  passenger-portal-7f5f54d874-mfqvn.kong-…
   ```
   {:.no-copy-code}

1. Inspect the workload-scoped policy:

   ```sh
   kongctl inspect mesh meshtimeout flight-control-timeout.kong-air-production \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh
   ```

   The workload-scoped policy selected only the proxy with a matching `app` label:

   ```text
   MESH           NAME
   kong-air-mesh  flight-control-75c96dd768-j4mr6.kong-ai…
   ```
   {:.no-copy-code}

`kongctl inspect mesh` reports the selection that the control plane computed.
That makes it the reliable check for whether a selector matched the proxies you intended.
Pod name suffixes differ in your cluster, and `kongctl` shortens long names to fit the column.
The zone control plane takes a few seconds to sync a new policy to the global control plane that `kongctl` queries.
If a result looks stale, run the command again.
