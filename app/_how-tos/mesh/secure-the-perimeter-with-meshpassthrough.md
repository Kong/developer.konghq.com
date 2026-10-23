---
title: Secure the perimeter with MeshPassthrough
content_type: how_to
permalink: /mesh/secure-the-perimeter-with-meshpassthrough/
description: Use the MeshPassthrough policy to control outbound traffic to destinations outside the mesh, and move the Kong Air mesh from open outbound access to an allowlist.
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
  position: 10
tldr:
  q: How do I control traffic to services outside the mesh?
  a: |
    On a control plane that sets `restrictOutbound` to `false`, apply a **MeshPassthrough** policy to:
    1. **Block unknown destinations** with `passthroughMode: None`.
    2. **Allow specific destinations** with `passthroughMode: Matched` and `appendMatch` entries (for example, `*.google.com` on port 80).
    3. **Keep one auditable record** of the external destinations your workloads can reach.
prereqs:
  inline:
    - title: Transparent proxy
      content: |
        `MeshPassthrough` applies only to sidecars that run with transparent proxying.
        The Kubernetes sidecar injector turns on transparent proxying by default.
        For a proxy without it, the control plane skips the policy and records a warning.
cleanup:
  inline:
    - title: Remove the passthrough policies
      include_content: md/mesh/v3/cleanup/meshpassthrough
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Manage external services with MeshExternalService"
    url: "/mesh/manage-external-services-with-meshexternalservice/"
related_resources:
  - text: MeshPassthrough
    url: /mesh/policies/meshpassthrough/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: Prepare the mesh for production
    url: /mesh/prepare-the-mesh-for-production/
---

## The open mesh and the secure mesh

### Open mesh

In an open mesh, a sidecar forwards traffic to any external destination.
Envoy sends that traffic through its "Original Destination" cluster, which connects to the address the application dialed.

The Kong Air mesh starts open because the Kong Air control plane sets `restrictOutbound` to `false`.
With that setting, a proxy that no `MeshPassthrough` policy selects forwards traffic to any destination.
{{site.mesh_product_name}} 3.0 defaults `restrictOutbound` to `true`.
With the default, a proxy that no `MeshPassthrough` policy selects drops that traffic instead.
Check the setting on your own control plane to know which state you start from.
[Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) turns the setting on for Kong Air.

An open mesh has the following weaknesses:
*   Risk: If an attacker compromises a workload, the workload can send data to any server on the internet.
*   Visibility: Nothing records or controls which external services your workloads call.

### Secure mesh (zero-trust)

In a secure mesh, you use `MeshPassthrough` to list the outbound destinations that workloads can reach.
*   Benefit: A policy controls the traffic that leaves the mesh, through an explicit allowlist.
*   Auditability: One declarative record lists the external destinations that workloads can reach. That record is useful evidence for controls like PCI, HIPAA, or SOC 2.

`MeshPassthrough` controls the destinations that a sidecar can reach but that the mesh doesn't model as services.
Use it for the long tail of outbound calls.
When a destination matters enough to name, model it as a `MeshExternalService` instead, as in [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## How MeshPassthrough decides

A `MeshPassthrough` policy sets what a sidecar does with traffic to unknown destinations through its `passthroughMode` field.
In this guide, you move Kong Air from `All` (every unknown destination passes) to `None` (no unknown destination passes), then to `Matched` (only the destinations in `appendMatch` pass).
A policy that leaves out `passthroughMode` uses `Matched`, so a policy without `appendMatch` entries blocks every unknown destination.
For the full behavior of each mode, see [MeshPassthrough modes](/mesh/policies/meshpassthrough/#modes).

### Where the policy lives

The examples in this guide create policies in `kong-air-production`, the application namespace.
In an application namespace, a `MeshPassthrough` policy reaches only the proxies in that namespace.
`targetRef.kind: Mesh` therefore selects every Kong Air proxy in `kong-air-production`, so an application team can set its own perimeter.
To set one perimeter for every namespace in the zone, create the policy in `{{site.mesh_namespace}}` instead.
For how the namespace sets a policy's reach, see [Policy scope](/mesh/policy-targeting/#policy-scope).

## Move the mesh from open to allowlisted

Apply the following steps in order.
Each step replaces the previous policy, so delete the old policy before you apply the next one.
That way, only one `Mesh`-scoped `MeshPassthrough` policy is in force at a time.

1. Record the starting point. Pick a destination that your cluster can resolve and reach, and confirm that `check-in-api` reaches it before any policy exists. Without this baseline, you can't tell a policy block from a DNS failure, because both fail with a non-zero exit status:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.google.com
   ```

   Expected result: the command prints the response body.
   {:.no-copy-code}

1. Make the open posture explicit with an `allow-all-passthrough` policy. `passthroughMode: All` states the behavior that the mesh already has, so an audit can read it as a declared baseline:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
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
       passthroughMode: All
   EOF
   ```

1. Close the perimeter with a `secure-perimeter` policy that sets `passthroughMode: None`. Delete `allow-all-passthrough` first. Otherwise, `allow-all-passthrough` keeps winning on name order, and nothing changes:

   ```sh
   kubectl delete meshpassthrough allow-all-passthrough -n kong-air-production
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
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
       passthroughMode: None
   EOF
   ```

   Every Kong Air proxy in `kong-air-production` now reaches only the destinations that the mesh knows about. The sidecar drops traffic to any other destination.

1. Reopen the destinations you decided to allow with a `selective-passthrough` policy. `appendMatch` accepts `Domain`, `IP`, and `CIDR` entries. Each entry takes an optional `port`, and a `protocol` that defaults to `tcp`. A `Domain` entry can't use `tcp` or `mysql`, so set its `protocol`. An exact domain always needs a `port`, because the sidecar resolves the domain itself and connects to that port. A wildcard domain needs a `port` with `http`, `http2`, or `grpc`:

   ```sh
   kubectl delete meshpassthrough secure-perimeter -n kong-air-production
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
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
         - type: Domain
           value: "*.google.com"
           port: 80
           protocol: http
         - type: IP
           value: "203.0.113.10"
           port: 443
           protocol: tls
         - type: CIDR
           value: "198.51.100.0/24"
           port: 443
           protocol: tls
   EOF
   ```

   A match combines a destination, a port, and a protocol. The `*.google.com` entry on port 80 over HTTP doesn't allow the same host on port 443, so an application that upgrades to HTTPS needs its own entry. For the validation rules on wildcards, ports, and protocols, see [MeshPassthrough](/mesh/policies/meshpassthrough/).

{:.info}
> Use a `Mesh`-level `MeshPassthrough` policy to set a security baseline, then use a `Dataplane` selector to grant exceptions to the workloads that need broader access.
> A `Dataplane` selector is more specific than `Mesh`, so the exception wins for the proxies it matches.
> The baseline stays in place for every other proxy.
> See [Policy precedence](/mesh/policy-targeting/#policy-precedence).

## Interaction with egress gateways

`MeshPassthrough` and a mesh-scoped zone egress control different traffic.
The sidecar enforces `MeshPassthrough` on traffic to destinations that the mesh doesn't model, and it connects to those destinations directly.
A zone egress carries `MeshExternalService` traffic.
On the zone egress, `MeshTrafficPermission` denies every call until a rule allows the caller to reach that destination.
An HTTP call gets `403 Forbidden`, and a TCP connection closes.
The zone egress also isn't on the default cross-zone path, because a sidecar connects directly to the remote zone ingress.
For both paths, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).
To send a dependency through the zone egress, model it as a `MeshExternalService`, as in [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## Validate

1. Confirm that the policy blocks a destination outside the allowlist. Use a host that your cluster can resolve and reach, so that only the policy can cause a failure:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.bing.com
   ```

   Expected result: the command fails with a non-zero exit status and prints no response body. The sidecar's port 80 filter chain has no route for `www.bing.com`, so the sidecar answers with `503 Service Unavailable`.
   {:.no-copy-code}

1. Confirm that the `*.google.com` entry still allows traffic to that host on port 80:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.google.com
   ```

   Expected result: the command prints the response body.
   {:.no-copy-code}

1. Confirm that each match applies to one port and one protocol. The port 80 entry doesn't cover the same host on port 443:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- https://www.google.com
   ```

   Expected result: the command fails. If the workload needs HTTPS to this host, add a second `appendMatch` entry for port 443 with `protocol: tls`.
   {:.no-copy-code}

The control plane sends policies to the proxies over xDS within a few seconds, and the proxies don't need a restart.
If a result looks stale, wait and run the command again.
