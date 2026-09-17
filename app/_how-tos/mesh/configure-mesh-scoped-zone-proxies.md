---
title: Configure mesh-scoped zone proxies
content_type: how_to
permalink: /mesh/configure-mesh-scoped-zone-proxies/
description: Give each mesh its own dedicated zone ingress and egress, with per-mesh workload identity, targetable policy, isolated observability, and a deny-by-default egress perimeter.
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
    Give the mesh its own dedicated zone proxies:
    1. Deploy a dedicated ingress and egress pair for it (see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/)).
    2. Target the proxies with mesh-scoped policy using the `kuma.io/listener-zoneingress` / `kuma.io/listener-zoneegress` labels (see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/)).
    3. Cross-zone traffic now carries the mesh's own SPIFFE identity, honors its policies, and reports its own metrics.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
next_steps:
  - text: "Route across zones with canary rollouts and color rings"
    url: "/mesh/route-across-zones-with-canary-rollouts-and-color-rings/"
related_resources:
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: Apply policies to mesh-scoped zone proxies
    url: /mesh/zone-proxy-policies/
---

`kong-air-mesh` carries passenger PII, so its cross-zone traffic must present a verifiable mTLS identity and remain independently observable and governable. Mesh-scoped zone proxies give the mesh a dedicated ingress and egress for that traffic:

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
    meaning: "Metrics and logs cover the traffic carried by `kong-air-mesh`."
  - outcome: "A deny-by-default perimeter"
    meaning: "The egress refuses outbound traffic unless a policy explicitly allows it, no more open forwarding."
{% endtable %}
<!-- vale on -->

Each mesh-scoped proxy is a `Dataplane` inside the mesh, the same resource kind used for application sidecars. Policies can therefore select a zone proxy by its labels and listener role.

## Give your mesh its own zone proxies

Add a `meshes:` entry to each zone control plane's Helm values, name the mesh, and enable its `ingress` and `egress`. This gives `kong-air-mesh` its own ingress and egress Deployment, each with its own Service and ServiceAccount. For the Helm values and upgrade commands, see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).

## Confirm the proxies belong to your mesh

Once the pods are `Running`, you can see that the zone proxies are now first-class members of `kong-air-mesh`, each one a `Dataplane` carrying the mesh label.

1. Confirm the zone proxy pods are running:

   ```bash
   kubectl get pods -n kong-mesh-system \
     -l "kuma.io/mesh=kong-air-mesh"
   ```

1. Inspect the zone ingress `Dataplane` resource:

   ```bash
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
   {:.no-copy-code}

   {:.info}
   > The listener `name` (here `"10001"`) is what you use in `sectionName` to target one specific listener. For Helm-deployed proxies with no named ports it defaults to the port number as a string, `"10001"` for zone ingress and `"10002"` for zone egress.

1. Check the `MeshZoneAddress` that the control plane publishes so other zones can reach this mesh's ingress:

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
   {:.no-copy-code}

If you scale the zone ingress to zero, its `MeshZoneAddress` is withdrawn automatically, so other zones stop routing to a dead endpoint.

## Apply per-mesh identity, policy, and observability

Because the proxies are `Dataplane` resources in `kong-air-mesh`, supported mesh policies can target them. Select them with `targetRef.kind: Dataplane` and the `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled` labels, adding a `sectionName` to target one specific listener by name.

For the full policy-targeting recipes, giving cross-zone traffic a verifiable `MeshIdentity`, scoping `MeshMetric` observability to one mesh, and setting `MeshTimeout` and `MeshAccessLog` on the proxies, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## A deny-by-default egress perimeter

A mesh-scoped egress is closed by default: every `MeshExternalService` is SNI-matched at the listener and refused unless a `MeshTrafficPermission` explicitly allows the caller's SPIFFE identity. You decide exactly what may leave the mesh.

Grant each caller the access it needs with a `MeshTrafficPermission` that targets the zone-egress `Dataplane` and matches the caller's `spiffeID` together with the destination `sni`. Without an allow rule, the egress refuses the request with a `503` before `MeshPassthrough` or any other policy evaluates, so add the permissions before you route real traffic through it. For the policy YAML and the SNI format, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## Validate

1. Confirm the mesh-scoped ingress and egress pods for `kong-air-mesh` are `Running`:

   ```sh
   kubectl get pods -n kong-mesh-system -l "kuma.io/mesh=kong-air-mesh"
   ```

   Expected output, both pods `1/1` and `Running`:

   ```text
   NAME                                               READY   STATUS    RESTARTS   AGE
   kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn   1/1     Running   0          2m
   kong-mesh-kong-air-mesh-egress-5d8f7c9b6d-p4x2q    1/1     Running   0          2m
   ```
   {:.no-copy-code}

1. Confirm each proxy is attributed to the right mesh and has the role you expect:

   ```sh
   kubectl get pods -n kong-mesh-system -l kuma.io/mesh=kong-air-mesh \
     -o custom-columns='NAME:.metadata.name,MESH:.metadata.labels.kuma\.io/mesh,TYPE:.metadata.labels.k8s\.kuma\.io/zone-proxy-type'
   ```

   Expected output, one ingress and one egress for the mesh:

   ```text
   NAME                                               MESH            TYPE
   kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn   kong-air-mesh   ingress
   kong-mesh-kong-air-mesh-egress-5d8f7c9b6d-p4x2q    kong-air-mesh   egress
   ```
   {:.no-copy-code}

   {:.info}
   > Check the pods rather than `kubectl get dataplanes`. A zone proxy's `Dataplane` is generated by the control plane and is not a Kubernetes object, so it does not appear in `kubectl` output. To see it, query the control plane with `kumactl inspect dataplanes`.

Together, these confirm the mesh-scoped proxies are healthy and that each one is bound to `kong-air-mesh` by its `kuma.io/mesh` label.
