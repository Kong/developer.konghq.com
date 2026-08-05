---
title: Secure the perimeter with MeshPassthrough
content_type: how_to
layout: how-to
permalink: /mesh/scenarios/secure-the-perimeter-with-meshpassthrough/
description: Learn how to control outbound traffic to external services using the MeshPassthrough policy, moving from an open mesh to a zero-trust perimeter.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I control traffic to services outside the mesh?
  a: |
    By default, {{site.mesh_product_name}} allows all outbound traffic. Use **MeshPassthrough** to:
    1. **Restrict access** by setting `passthroughMode: None`.
    2. **Allowlist destinations** by matching specific domains (for example, `*.google.com`).
    3. **Enable visibility** by managing the mesh perimeter explicitly.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment.
    - title: Resources
      content: |
        A client workload (for example, `check-in-api`) to test outbound connectivity.
next_steps:
  - text: "Manage external services with MeshExternalService"
    url: "/mesh/scenarios/manage-external-services-with-meshexternalservice/"
related_resources:
  - text: MeshPassthrough
    url: /mesh/policies/meshpassthrough/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

## The "open mesh" vs. "secure mesh"

### Open mesh (default)
Sidecars allow all traffic to any external destination. This is handled by the Envoy "Original Destination" cluster.
*   Risk: If a workload is compromised, it can exfiltrate data to any server on the internet.
*   Visibility: No centralized logging or control over what external services are being consumed.

### Secure mesh (zero-trust)
Using `MeshPassthrough`, you explicitly define which outbound destinations are allowed.
*   Benefit: Policy-driven control and an explicit allowlist for traffic leaving the mesh.
*   Auditability: A single, declarative record of which external destinations workloads may reach, useful evidence for controls like PCI, HIPAA, or SOC 2.

{:.info}
> Interaction with mesh-scoped ZoneEgress. If you've enabled mesh-scoped ZoneEgress (the `meshes:` Helm list, see [Multi-zone architecture](/mesh/scenarios/multi-zone-architecture/)), `MeshExternalService` traffic flowing through that listener is deny-by-default at the ZE itself, SNI-matched per external service. A `MeshTrafficPermission` `Allow` for the caller's SPIFFE identity is required even before `MeshPassthrough` gets a chance to evaluate. `MeshPassthrough` remains the right control for non-`MeshExternalService` egress.

## Configure MeshPassthrough

The `MeshPassthrough` policy defines how the proxy handles traffic that doesn't match any known `MeshService` or `MeshExternalService`. For the full field reference (`passthroughMode` and its defaults, `appendMatch`, supported match types, and protocol rules), see [MeshPassthrough](/mesh/policies/meshpassthrough/).

### Step 1: Broad "allow" (default behavior)
With no `MeshPassthrough` policy in place, the mesh allows all outbound passthrough, so the effective behavior matches `passthroughMode: All`. The example below makes that explicit.

{% navtabs "passthrough-allow-all" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: allow-all-passthrough
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: All' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshPassthrough
name: allow-all-passthrough
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: All' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 2: "Deny all" (secure posture)
To tighten security, change the mode to `None`. This blocks all traffic that isn't explicitly defined in your mesh.

{% navtabs "passthrough-deny-all" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: secure-perimeter
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshPassthrough
name: secure-perimeter
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Selective passthrough
You can allow specific destinations even without defining a formal `MeshExternalService` by listing them under `appendMatch`, as shown below. For the match field semantics and validation rules, see [MeshPassthrough](/mesh/policies/meshpassthrough/).

{% navtabs "passthrough-matched" %}
{% navtab "Kubernetes (Zone CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: selective-passthrough
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: IP
        value: "1.2.3.4"
        port: 443
        protocol: tls
      - type: CIDR
        value: "10.0.0.0/8"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.google.com"
        port: 80
        protocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Zone CP)" %}
```bash
echo 'type: MeshPassthrough
name: selective-passthrough
mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: IP
        value: "1.2.3.4"
        port: 443
        protocol: tls
      - type: CIDR
        value: "10.0.0.0/8"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.google.com"
        port: 80
        protocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Interaction with egress gateways

For maximum security, combine `MeshPassthrough` with a ZoneEgress.
1.  Direct mode: Sidecar tries to call the external service directly. `MeshPassthrough` logic happens in the sidecar.
2.  Egress mode: Sidecar is forced to route external traffic to the `ZoneEgress`. Once the destination is a `MeshExternalService`, the mesh-scoped ZoneEgress listener is deny-by-default and needs a matching `MeshTrafficPermission` allow before `MeshPassthrough` ever evaluates.

{:.info}
> Use `MeshPassthrough` at the `Mesh` level to set a global security baseline, then use more specific `Dataplane` selectors (by `labels:`) to grant exceptions to the workloads that need broader internet access.
