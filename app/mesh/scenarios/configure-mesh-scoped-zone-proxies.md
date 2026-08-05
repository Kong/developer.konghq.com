---
title: Configure mesh-scoped zone proxies
content_type: how_to
layout: how-to
permalink: /mesh/scenarios/configure-mesh-scoped-zone-proxies/
description: Give each mesh its own dedicated zone ingress and egress in {{site.mesh_product_name}} 2.14, with per-mesh workload identity, targetable policy, isolated observability, and a deny-by-default egress perimeter for cross-zone traffic.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I give one mesh its own identity, policies, and observability on cross-zone traffic?
  a: |
    Give the mesh its own dedicated zone proxies instead of sharing one global pair:
    1. Put the mesh in `spec.meshServices.mode: Exclusive`.
    2. Deploy a dedicated ingress and egress pair for it (see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/)).
    3. Target the proxies with mesh-scoped policy using the `kuma.io/listener-zoneingress` / `kuma.io/listener-zoneegress` labels (see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/)).
    4. Cross-zone traffic now carries the mesh's own SPIFFE identity, honors its policies, and reports its own metrics.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps and `meshServices.mode: Exclusive` on the `kong-air-mesh` Mesh. See [Get started with your first policy](/mesh/scenarios/get-started-with-your-first-policy/).
next_steps:
  - text: "Route across zones with canary rollouts and color rings"
    url: "/mesh/scenarios/route-across-zones-with-canary-rollouts-and-color-rings/"
related_resources:
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: Apply policies to mesh-scoped zone proxies
    url: /mesh/zone-proxy-policies/
---

Cross-zone traffic used to be the one place where every mesh in a zone looked the same. Before {{site.mesh_product_name}} 2.14, a single ZoneIngress and ZoneEgress carried traffic for **all** meshes in a zone. That meant `kong-air-mesh` could not present its own identity on the wire, could not have its own timeouts or access logs on cross-zone calls, and shared one blended observability view with every other mesh in the zone.

For Kong Air that was a compliance blocker. `kong-air-mesh` carries passenger PII, and auditors require its cross-zone traffic to present a verifiable mTLS identity distinct from any other mesh sharing the zone. A single shared egress made that impossible.

**Mesh-scoped zone proxies** give each mesh its own dedicated ingress and egress. For Kong Air, that turns the shared perimeter into one they fully own:

<!-- vale off -->
{% table %}
columns:
  - title: What Kong Air gets
    key: outcome
  - title: What it means
    key: meaning
rows:
  - outcome: "A verifiable identity for cross-zone traffic"
    meaning: "The zone proxies receive a `MeshIdentity`-issued SPIFFE certificate, so cross-zone calls from `kong-air-mesh` are provably theirs, the compliance requirement that started this."
  - outcome: "Cross-zone traffic they can govern"
    meaning: "Any mesh-scoped policy (`MeshTimeout`, `MeshAccessLog`, `MeshRateLimit`, and more) can target the proxies directly."
  - outcome: "Observability scoped to one mesh"
    meaning: "Metrics and logs cover only `kong-air-mesh`, instead of a blend of every mesh in the zone."
  - outcome: "A deny-by-default perimeter"
    meaning: "The egress refuses outbound traffic unless a policy explicitly allows it, no more open forwarding."
{% endtable %}
<!-- vale on -->

This is possible because each mesh-scoped proxy is just an ordinary `Dataplane` inside the mesh, the same kind of resource as an application sidecar. That is the whole trick: anything you can do to a workload, you can now do to your zone proxies.

## Turn on Exclusive mode

Mesh-scoped proxies are only generated for a mesh running in `Exclusive` mode. Confirm it first:

```bash
kumactl get mesh kong-air-mesh -o yaml | grep -A3 "meshServices:"
```

If `meshServices.mode` is not `Exclusive`, switch it on:

```bash
kubectl patch mesh kong-air-mesh \
  --type merge \
  -p '{"spec":{"meshServices":{"mode":"Exclusive"}}}'
```

## Give your mesh its own zone proxies

You ask for a dedicated pair of proxies per mesh in your zone Helm values, instead of the one cluster-wide pair. Here is what changes between the two models:

<!-- vale off -->
{% table %}
columns:
  - title: "&nbsp;"
    key: attribute
  - title: Shared (global zone proxies)
    key: shared
  - title: Dedicated (mesh-scoped zone proxies)
    key: dedicated
rows:
  - attribute: |
      **Scope**
    shared: |
      All meshes in the zone
    dedicated: |
      One mesh
  - attribute: |
      **Own SPIFFE identity**
    shared: |
      Not possible
    dedicated: |
      Yes, via `MeshIdentity`
  - attribute: |
      **Targetable by mesh policy**
    shared: |
      No
    dedicated: |
      Yes
  - attribute: |
      **Resource kind**
    shared: |
      `ZoneIngress` / `ZoneEgress`
    dedicated: |
      `Dataplane` with `networking.listeners[]`
  - attribute: |
      **Helm key**
    shared: |
      `kuma.ingress.enabled: true`
    dedicated: |
      `kuma.meshes[].ingress.enabled: true`
  - attribute: |
      **Policy selector**
    shared: |
      N/A
    dedicated: |
      `kuma.io/listener-zoneingress: enabled` / `kuma.io/listener-zoneegress: enabled`
{% endtable %}
<!-- vale on -->

{:.info}
> The two models can coexist during a migration window. The old `kuma.ingress.enabled: true` key and the new `kuma.meshes:` key are both honored in 2.14, so you can stand up the dedicated proxies before retiring the shared ones. See [Migrating from global zone proxies](#migrating-from-global-zone-proxies).

You request a dedicated pair per mesh by adding a `meshes:` entry to each zone CP's Helm values, naming the mesh and enabling its `ingress` and `egress`, then running `helm upgrade`. This gives `kong-air-mesh` its own ingress and egress Deployment, each with its own Service and ServiceAccount. For the full Helm `kuma.meshes[]` values and upgrade commands, see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).

{:.info}
> Use `combinedProxies` instead of separate `ingress` and `egress` entries when you want a single lower-footprint Deployment for a small or staging environment. The two shapes are mutually exclusive per mesh entry.

```yaml
meshes:
  - name: kong-air-mesh
    combinedProxies:
      enabled: true
```

## Confirm the proxies belong to your mesh

Once the pods are `Running`, you can see that the zone proxies are now first-class members of `kong-air-mesh`, each one a `Dataplane` carrying the mesh label:

```bash
kubectl get pods -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"

kubectl get dataplanes -n kong-mesh-system \
  -l "kuma.io/listener-zoneingress=enabled,kuma.io/mesh=kong-air-mesh" \
  -o yaml
```

A zone ingress Dataplane looks like this, note it belongs to `kong-air-mesh` and exposes a `ZoneIngress` listener:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Dataplane
metadata:
  name: kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/zone: zone1
    kuma.io/listener-zoneingress: enabled
    k8s.kuma.io/zone-proxy-type: ingress
spec:
  networking:
    address: 10.42.0.30
    listeners:
      - type: ZoneIngress
        address: 10.42.0.30
        port: 10001
        name: "10001"
        state: Ready
```

{:.info}
> The listener `name` (here `"10001"`) is what you use in `sectionName` to target one specific listener. For Helm-deployed proxies with no named ports it defaults to the port number as a string, `"10001"` for zone ingress and `"10002"` for zone egress.

Other zones learn how to reach this mesh's ingress through a `MeshZoneAddress` that the control plane publishes for it:

```bash
kubectl get meshzoneaddresses -n kong-mesh-system \
  -l "kuma.io/mesh=kong-air-mesh"
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshZoneAddress
metadata:
  name: kong-mesh-kong-air-mesh-ingress
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/zone: zone1
spec:
  address: 203.0.113.42  # public LoadBalancer IP
  port: 10001
```

If you scale the zone ingress to zero, its `MeshZoneAddress` is withdrawn automatically, so other zones stop routing to a dead endpoint.

## Apply per-mesh identity, policy, and observability

Because the proxies are ordinary `Dataplane` resources in `kong-air-mesh`, every mesh-scoped policy can now target them, the controls that were impossible with a shared global proxy. You select them with `targetRef.kind: Dataplane` and the `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled` labels, adding a `sectionName` to target one specific listener by name.

For the full policy-targeting recipes, giving cross-zone traffic a verifiable `MeshIdentity`, scoping `MeshMetric` observability to one mesh, and setting `MeshTimeout` and `MeshAccessLog` on the proxies, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## A deny-by-default egress perimeter

The shared egress forwarded any traffic that reached it. A mesh-scoped egress is closed by default: every `MeshExternalService` is SNI-matched at the listener and refused unless a `MeshTrafficPermission` explicitly allows the caller's SPIFFE identity. You decide exactly what may leave the mesh.

Grant each caller the access it needs with a `MeshTrafficPermission` that targets the zone-egress `Dataplane` and matches the caller's `spiffeID` together with the destination `sni`. Without an allow rule, the egress refuses the request with a `503` before `MeshPassthrough` or any other policy evaluates, so add the permissions before you route real traffic through it. For the policy YAML and the SNI format, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## Migrating from global zone proxies

The move is **additive**: stand up the mesh-scoped proxies alongside the existing global ones, confirm cross-zone traffic flows through the new pair, then retire the old.

```yaml
# Transition values, both models active simultaneously
kuma:
  ingress:
    enabled: true   # old global, leave until migration is confirmed
  egress:
    enabled: true   # old global, leave until migration is confirmed

  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true   # new mesh-scoped
      egress:
        enabled: true   # new mesh-scoped
```

Once traffic is flowing through the mesh-scoped proxies, remove the old keys:

```yaml
kuma:
  # ingress.enabled and egress.enabled removed
  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true
      egress:
        enabled: true
```

{:.warning}
> Scale down the old global ZoneIngress **before** removing its Helm key. Deleting the key without scaling first can cause a brief traffic interruption if KDS has not yet propagated the new proxies' `MeshZoneAddress` to other zones.

The old `ZoneIngress` and `ZoneEgress` resource kinds remain in the API for backward compatibility in 2.14, and are planned for deprecation in a future major release.
