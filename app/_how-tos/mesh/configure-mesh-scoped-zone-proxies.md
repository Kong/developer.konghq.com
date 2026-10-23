---
title: Configure mesh-scoped zone proxies
content_type: how_to
permalink: /mesh/configure-mesh-scoped-zone-proxies/
description: Give a {{site.mesh_product_name}} mesh its own zone ingress and zone egress, so you can target them with policies, observe them per mesh, and control traffic to external services.
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
  position: 9
tldr:
  q: How do I give one mesh its own zone proxies for policies and observability?
  a: |
    Give the mesh its own zone proxies:
    1. Enable a dedicated ingress and egress for the mesh in the zone control plane's Helm values. For the steps, see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).
    2. Target the proxies with policies that support zone proxies, using the `kuma.io/listener-zoneingress` and `kuma.io/listener-zoneegress` labels.
    3. Allow each caller to reach each `MeshExternalService` through the zone egress with a `MeshTrafficPermission`.

    Cross-zone calls keep the original caller's identity, because the zone ingress forwards them without decrypting.
cleanup:
  inline:
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Secure the perimeter with MeshPassthrough"
    url: "/mesh/secure-the-perimeter-with-meshpassthrough/"
related_resources:
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
---

`kong-air-mesh` carries passenger personally identifiable information (PII).
Kong Air must verify, observe, and govern its cross-zone and external traffic separately from other meshes.
Mesh-scoped zone proxies give `kong-air-mesh` its own zone ingress and zone egress:

<!-- vale off -->
{% table %}
columns:
  - title: What Kong Air gets
    key: outcome
  - title: What it means
    key: meaning
rows:
  - outcome: "A verifiable identity on cross-zone calls"
    meaning: "The zone ingress forwards cross-zone connections without decrypting them. The destination proxy sees the original caller's Secure Production Identity Framework for Everyone (SPIFFE) identity, so it can authenticate every cross-zone call from `kong-air-mesh`."
  - outcome: "Zone proxies they can govern"
    meaning: "Policies that support zone proxies can target the `kong-air-mesh` proxies directly. For the supported policies, see [Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection)."
  - outcome: "Observability scoped to one mesh"
    meaning: "Metrics and logs from the zone proxies cover only the traffic of `kong-air-mesh`."
  - outcome: "A governable egress perimeter"
    meaning: "Traffic to `MeshExternalService` destinations passes the zone egress, which you can target with `MeshTrafficPermission`. Cross-zone traffic goes from the sidecar directly to the remote zone ingress."
{% endtable %}
<!-- vale on -->

Each mesh-scoped zone proxy is a `Dataplane` in the mesh, the same resource kind as an application sidecar.
So a policy can select a zone proxy by its labels and its listener role.

## Confirm the Helm values that gave your mesh its own zone proxies

`kong-air-mesh` already has its own zone proxies.
[Install {{site.mesh_product_name}} and deploy Kong Air](/mesh/install-kong-mesh-and-deploy-kong-air/) sets a `meshes:` entry in the zone control plane's Helm values.
The entry names `kong-air-mesh` and enables its `ingress` and `egress`:

```yaml
kuma:
  controlPlane:
    # ...
  meshes:
    - name: kong-air-mesh
      ingress:
        enabled: true
      egress:
        enabled: true
```
{:.no-copy-code}

The `meshes:` entry makes the Helm chart create an ingress Deployment and an egress Deployment for `kong-air-mesh`, each with its own Service and ServiceAccount.
To add the same zone proxies on a self-managed zone control plane, add the same `meshes:` entry to its Helm values and upgrade the release.
For the full Helm walkthrough, see [Deploy mesh-scoped zone proxies](/mesh/zone-proxies/).

## Confirm the proxies belong to your mesh

The zone proxies for `kong-air-mesh` are members of the mesh.
Each zone proxy is a `Dataplane` with the `kuma.io/mesh: kong-air-mesh` label.

1. Check that the zone proxy pods for `kong-air-mesh` are running:

   ```bash
   kubectl get pods -n kong-mesh-system \
     -l "kuma.io/mesh=kong-air-mesh"
   ```

1. List the `Dataplane` resources that the control plane holds for `kong-air-mesh`:

   ```bash
   kongctl get mesh dataplanes --control-plane-name "$MESH_CP" --mesh kong-air-mesh
   ```

1. Get the zone ingress `Dataplane`.
   Its name is the pod name followed by the namespace:

   ```bash
   kongctl get mesh dataplanes kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn.kong-mesh-system \
     --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   The zone ingress `Dataplane` belongs to `kong-air-mesh` and exposes a `ZoneIngress` listener:

   ```yaml
   kri: kri_dp_kong-air-mesh_zone1_kong-mesh-system_kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn_
   labels:
     k8s.kuma.io/service-account: kong-mesh-kong-air-mesh-ingress
     k8s.kuma.io/zone-proxy-type: ingress
     kuma.io/listener-zoneingress: enabled
     kuma.io/mesh: kong-air-mesh
     kuma.io/origin: zone
     kuma.io/zone: zone1
   mesh: kong-air-mesh
   name: kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn.kong-mesh-system
   networking:
     address: 10.42.0.30
     admin:
       port: 9901
     listeners:
       - address: 10.42.0.30
         name: "10001"
         port: 10001
         type: ZoneIngress
   ```
   {:.no-copy-code}

   {:.info}
   > To target one listener, set `sectionName` to the listener `name`, here `"10001"`.
   > For Helm-deployed proxies without named ports, the name defaults to the port number as a string: `"10001"` for zone ingress and `"10002"` for zone egress.
   >
   > A healthy listener has no `state` field.
   > The output omits `state` when it has its default value, `Ready`, so `state` appears only when the listener is `NotReady`.

1. List the `MeshZoneAddress` resources that tell other zones where to reach the ingresses of `kong-air-mesh`:

   ```bash
   kongctl get mesh meshzoneaddresses --control-plane-name "$MESH_CP" --mesh kong-air-mesh -o yaml
   ```

   ```yaml
   items:
     - kri: kri_mza_kong-air-mesh_zone1_kong-mesh-system_kong-mesh-kong-air-mesh-ingress_
       labels:
         kuma.io/mesh: kong-air-mesh
         kuma.io/origin: zone
         kuma.io/zone: zone1
       mesh: kong-air-mesh
       name: kong-mesh-kong-air-mesh-ingress.kong-mesh-system
       spec:
         address: 203.0.113.42  # public LoadBalancer IP
         port: 10001
       type: MeshZoneAddress
   total: 1
   ```
   {:.no-copy-code}

   Each zone publishes its own `MeshZoneAddress` and receives the entries of the other zones, so `total` grows with the deployment.
   The labels tell the entries apart.
   `kuma.io/origin: zone` marks the entry that this zone published.
   `kuma.io/origin: global` marks an entry synced from the zone named in `kuma.io/zone`.

If you scale the zone ingress to zero, the control plane withdraws its `MeshZoneAddress`.
Other zones then stop routing to an ingress that doesn't respond.

## Target the proxies with policy

Kong Air targets its zone proxies with the policies that support zone proxy listeners.
A policy selects the proxies with `targetRef.kind: Dataplane` and the `kuma.io/listener-zoneingress: enabled` or `kuma.io/listener-zoneegress: enabled` label.
A `sectionName` narrows the policy to one listener.
For the supported policies and what each one does on a zone proxy, see [Proxy and traffic selection](/mesh/mesh-scoped-zone-proxies/#proxy-and-traffic-selection).

The following `MeshMetric` collects metrics from the `kong-air-mesh` zone ingress:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: kong-air-ingress-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneingress: enabled
  default:
    sidecar:
      includeUnused: false
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```

Other policies that support zone proxies use the same `targetRef`.

## Govern what leaves through the egress

The `kong-air-mesh` zone egress denies traffic to a `MeshExternalService` until a `MeshTrafficPermission` allows it.
Kong Air opens one external destination at a time with a `MeshTrafficPermission` that targets the zone egress.
For how the zone egress authorizes callers, see [Authorize zone proxy traffic](/mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic) and [Allow one caller to one external destination](/mesh/mesh-scoped-zone-proxies/#allow-one-caller-to-one-external-destination).

The following `MeshTrafficPermission` allows `flight-control` to reach the `flight-db` external service through the zone egress:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: flight-db-access
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
            sni:
              type: Exact
              value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
```

The entry allows a connection only when both the caller's SPIFFE ID and the destination Server Name Indication (SNI) match.
For how to find each value, see [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## Validate

1. Check that the zone ingress and zone egress pods for `kong-air-mesh` are `Running`:

   ```sh
   kubectl get pods -n kong-mesh-system -l "kuma.io/mesh=kong-air-mesh"
   ```

   Both pods show `2/2` and `Running`.
   Each zone proxy pod runs the proxy container next to a `kuma-sidecar` container:

   ```text
   NAME                                               READY   STATUS    RESTARTS   AGE
   kong-mesh-kong-air-mesh-egress-5d8f7c9b6d-p4x2q    2/2     Running   0          2m
   kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn   2/2     Running   0          2m
   ```
   {:.no-copy-code}

1. Check that each zone proxy belongs to `kong-air-mesh` and has the expected role:

   ```sh
   kubectl get pods -n kong-mesh-system -l kuma.io/mesh=kong-air-mesh \
     -o custom-columns='NAME:.metadata.name,MESH:.metadata.labels.kuma\.io/mesh,TYPE:.metadata.labels.k8s\.kuma\.io/zone-proxy-type'
   ```

   The output shows one ingress and one egress for `kong-air-mesh`:

   ```text
   NAME                                               MESH            TYPE
   kong-mesh-kong-air-mesh-egress-5d8f7c9b6d-p4x2q    kong-air-mesh   egress
   kong-mesh-kong-air-mesh-ingress-77499bbc58-kkssn   kong-air-mesh   ingress
   ```
   {:.no-copy-code}

The mesh-scoped zone proxies are healthy, and their `kuma.io/mesh` label binds each one to `kong-air-mesh`.
