---
title: Target workloads and services
content_type: how_to
permalink: /mesh/target-workloads-and-services/
description: How to scope policies in {{site.mesh_product_name}} using Dataplane labels for proxy groups and MeshService for explicit destinations.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How should I target groups of proxies and services?
  a: |
    Modern {{site.mesh_product_name}} uses two targeting primitives:
    1. `Dataplane` with `labels:` at the top level of a policy, to scope it to a slice of the fleet (a zone, an environment, a team).
    2. `MeshService` in `spec.to[].targetRef` and `backendRefs`, to address explicit destinations (including canaries and blue/green variants).
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
    - title: kongctl
      include_content: md/mesh/v3/prereqs/kongctl
cleanup:
  inline:
    - title: Remove the timeout policies
      include_content: md/mesh/v3/cleanup/target-workloads-and-services
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Observe mesh traffic in practice"
    url: "/mesh/observe-mesh-traffic-in-practice/"
related_resources:
  - text: MeshService
    url: /mesh/meshservice/
  - text: Introduction to policies
    url: /mesh/policies-introduction/
---

{{site.mesh_product_name}} uses two targeting primitives: a `Dataplane` label selector for scoping a policy to a group of proxies, and explicit `MeshService` (and `MeshMultiZoneService`, `MeshExternalService`) resources for addressing destinations. For the full targeting model and the per-policy `targetRef` support matrices, see [Policies](/mesh/policies-introduction/) and [MeshService](/mesh/meshservice/). This page focuses on how Kong Air applies those primitives.

## Dataplane with labels: the cross-cutting proxy policy

Use a top-level `targetRef` of `Dataplane` with a `labels:` selector when you want to apply a policy to a group of proxies based on shared environmental traits, rather than their specific service identity.

The labels you select on are the ones the control plane computes for each proxy. They combine the pod's own labels, such as `app` and `version`, with mesh metadata such as `kuma.io/zone`, `kuma.io/workload`, and `k8s.kuma.io/namespace`. You don't set the `kuma.io/` labels yourself.

### Example: regional timeouts

To give every sidecar in `zone1` the same timeout, perhaps because of known cross-zone latency, select the proxies on their computed `kuma.io/zone` label:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: regional-baseline
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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
          requestTimeout: 15s' | kubectl apply -f -
```

{:.warning}
> A zone-wide policy has to live in the system namespace (`{{site.mesh_namespace}}`). The control plane computes `kuma.io/policy-role` from where a policy lives and what it targets. This policy in an application namespace computes to `consumer`, which selects only proxies in that same namespace, so the `kuma.io/zone: zone1` selector would never reach past it. In `{{site.mesh_namespace}}` it computes to `system`, which carries no namespace restriction. See [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/).

A zone control plane connected to a global control plane requires every resource created in the system namespace to carry `kuma.io/origin: zone`, and rejects it otherwise. In an application namespace the control plane computes the label for you. See [Resource scoping](/mesh/resource-scoping/).

## Explicit MeshService: the standard

In {{site.mesh_product_name}}, you manage rollout-oriented "subsets" (like Canary vs. Stable) by creating distinct `MeshService` resources. This is called explicit subsetting. The control plane can also generate baseline `MeshService` resources automatically for workloads; the explicit resources in this section are for the cases where you want named, independently routable destinations. For how generated `MeshService` resources match workloads, see [MeshService](/mesh/meshservice/).

By naming your subsets explicitly, your routing rules become clear, predictable, and easy to audit. This model moves away from implicit tag-matching and toward a first-class resource management system.

{:.info}
> For a step-by-step tutorial on implementing rollouts using this model, see [Split traffic with MeshService resources](/mesh/split-traffic-with-meshservice-resources/).


## Why use explicit MeshServices?

1.  Deterministic Routing: The Control Plane resolves named resources directly to a known set of IP addresses, making the mesh more reliable at scale.
2.  Granular Metrics: You get separate metrics for `passenger-portal-v1` and `passenger-portal-v2` automatically, with no tag filtering to reconstruct them.
3.  Kubernetes Native: This pattern matches how Argo CD, Flagger, and the Gateway API handle traffic splitting, so existing automation tooling works the same way.

## Validate

Confirm that a `Dataplane` label selector scopes a policy to the intended workload, and no others, in `kong-air-production`.

Sidecar proxies have no `Dataplane` object in the Kubernetes API, so `kubectl` can't show you which proxies a selector matched. Ask the control plane instead, using [kongctl](/kongctl/).

1. List the proxies the control plane knows about, with the labels a `targetRef` can select on:

   ```sh
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   Each Kong Air workload carries its own `app` and `version` labels, and the control plane adds the `kuma.io/` ones. The `flight-control` entry, with the other two proxies omitted:

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

1. Apply a `MeshTimeout` scoped only to `flight-control`, using the same `Dataplane` label-selector pattern as the [regional timeouts example](#example-regional-timeouts). This one targets a single workload rather than a whole zone, so it belongs in the application namespace:

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
             requestTimeout: 15s' | kubectl apply -f -
   ```

1. Ask which proxies the zone-wide policy selected. Name the policy as `<name>.<namespace>`:

   ```sh
   kongctl get mesh inspect meshtimeout regional-baseline.{{site.mesh_namespace}} \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh
   ```

   It selected all three, because a policy in the system namespace computes to the `system` role, which carries no namespace restriction:

   ```text
   MESH           NAME
   kong-air-mesh  check-in-api-7c4756644b-gncds.kong-air-…
   kong-air-mesh  flight-control-75c96dd768-j4mr6.kong-ai…
   kong-air-mesh  passenger-portal-7f5f54d874-mfqvn.kong-…
   ```
   {:.no-copy-code}

1. Ask the same question of the workload-scoped policy:

   ```sh
   kongctl get mesh inspect meshtimeout flight-control-timeout.kong-air-production \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh
   ```

   It selected only the proxy whose `app` label matched:

   ```text
   MESH           NAME
   kong-air-mesh  flight-control-75c96dd768-j4mr6.kong-ai…
   ```
   {:.no-copy-code}

`kongctl get mesh inspect` reports what the control plane computed rather than what you wrote, so it is the authoritative answer to whether a selector matched what you intended. The pod name suffixes differ in your own cluster, and long names are shortened to fit the column. Policies take a few seconds to reach the proxies, so if a result looks stale, run the command again.
