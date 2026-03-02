---
title: "Securing the Perimeter: MeshPassthrough"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Learn how to control outbound traffic to external services using the MeshPassthrough policy, moving from an open mesh to a zero-trust perimeter.
products:
  - mesh
tldr:
  q: How do I control traffic to services outside the mesh?
  a: |
    By default, Kong Mesh allows all outbound traffic. Use **MeshPassthrough** to:
    1. **Restrict access** by setting `passthroughMode: None`.
    2. **Whitelist destinations** by matching specific domains (e.g., `*.google.com`).
    3. **Enable visibility** by managing the mesh perimeter explicitly.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment.
    - title: Resources
      content: |
        A client workload (e.g., `client-blu`) to test outbound connectivity.
next_steps:
  - text: "First-Class Dependencies: MeshExternalService"
    url: "/mesh/scenarios/meshexternalservice/"
---
## 1. The "Open Mesh" vs. "Secure Mesh"

### Open Mesh (Default)
Sidecars allow all traffic to any external destination. This is handled by the Envoy "Original Destination" cluster.
*   **Risk**: If a workload is compromised, it can exfiltrate data to any server on the internet.
*   **Visibility**: No centralized logging or control over what external services are being consumed.

### Secure Mesh (Zero-Trust)
Using `MeshPassthrough`, you explicitly define which outbound destinations are allowed.
*   **Benefit**: Cryptographic proof and policy-driven control over the mesh boundary.
*   **Compliance**: Meets requirements for PCI, HIPAA, and SOC2 regarding outbound data flow.

## 2. Configuring MeshPassthrough

The `MeshPassthrough` policy defines how the proxy handles traffic that doesn't match any known `MeshService` or `MeshExternalService`.

### Step 1: Broad "Allow" (Default Behavior)
By default, {{site.mesh_product_name}} acts as if this policy exists with `passthroughMode: All`.

{% navtabs "passthrough-allow-all" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: allow-all-passthrough
  namespace: kong-air-production
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: All' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: allow-all-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: All' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 2: "Deny All" (Secure Posture)
To tighten security, change the mode to `None`. This blocks all traffic that isn't explicitly defined in your mesh.

{% navtabs "passthrough-deny-all" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: secure-perimeter
  namespace: kong-air-production
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: secure-perimeter
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: None' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Selective Passthrough
You can allow traffic based on IP ranges (CIDR) or ports, even without defining a formal `MeshExternalService`.

{% navtabs "passthrough-matched" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: selective-passthrough
  namespace: kong-air-production
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: IP
        value: "1.2.3.4/32"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.google.com"
        port: 80
        protocol: http' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshPassthrough
name: selective-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: IP
        value: "1.2.3.4/32"
        port: 443
        protocol: tls
      - type: Domain
        value: "*.google.com"
        port: 80
        protocol: http' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

{% tip %}
`Domain`-type entries in `appendMatch` **must** include a `protocol` field (e.g., `http`, `tls`, `grpc`). The API will reject the resource without it.
{% endtip %}

## 3. Interaction with Egress Gateways

For maximum security, combine `MeshPassthrough` with a **ZoneEgress**.
1.  **Direct Mode**: Sidecar tries to call the external service directly. `MeshPassthrough` logic happens in the sidecar.
2.  **Egress Mode**: Sidecar is forced to route external traffic to the `ZoneEgress`. The `MeshPassthrough` policy can be applied at the `ZoneEgress` level to create a centralized "Chokepoint" for the entire zone.

{% tip %}
Use `MeshPassthrough` at the `Mesh` level to set a global security baseline, then use more specific `MeshService` targetRefs to grant exceptions to specific services that need broader internet access.
{% endtip %}
