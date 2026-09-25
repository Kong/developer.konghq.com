---
title: Secure the perimeter with MeshPassthrough
content_type: how_to
permalink: /mesh/secure-the-perimeter-with-meshpassthrough/
description: Learn how to control outbound traffic to external services using the MeshPassthrough policy, moving from an open mesh to a zero-trust perimeter.
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
tldr:
  q: How do I control traffic to services outside the mesh?
  a: |
    By default, {{site.mesh_product_name}} allows all outbound traffic. Use **MeshPassthrough** to:
    1. **Restrict access** by setting `passthroughMode: None`.
    2. **Allowlist destinations** by matching specific domains (for example, `*.google.com`).
    3. **Enable visibility** by managing the mesh perimeter explicitly.
prereqs:
  inline:
    - title: Kong Air demo deployment
      content: |
        A running {{site.mesh_product_name}} deployment with the Kong Air demo apps in `kong-air-mesh`. See [Get started with your first policy](/mesh/get-started-with-your-first-policy/).
    - title: Transparent proxy
      content: |
        `MeshPassthrough` only applies to sidecars running with transparent proxy, which is the default for the Kubernetes sidecar injector. The control plane records a policy warning and skips the proxy otherwise.
cleanup:
  inline:
    - title: Remove the passthrough policies
      include_content: md/mesh/v3/cleanup/meshpassthrough
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "Manage external services with MeshExternalService"
    url: "/mesh/manage-external-services-with-meshexternalservice/"
related_resources:
  - text: MeshPassthrough
    url: /mesh/policies/meshpassthrough/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
  - text: Policy targeting and precedence
    url: /mesh/policy-targeting-and-precedence/
---

## The open mesh and the secure mesh

### Open mesh (default)

Sidecars allow all traffic to any external destination. This is handled by the Envoy "Original Destination" cluster.
*   Risk: If a workload is compromised, it can exfiltrate data to any server on the internet.
*   Visibility: No centralized logging or control over what external services are being consumed.

### Secure mesh (zero-trust)

Using `MeshPassthrough`, you explicitly define which outbound destinations are allowed.
*   Benefit: Policy-driven control and an explicit allowlist for traffic leaving the mesh.
*   Auditability: A single, declarative record of which external destinations workloads may reach, useful evidence for controls like PCI, HIPAA, or SOC 2.

`MeshPassthrough` governs the destinations a sidecar can reach that are not modelled in the mesh. It is the control for the long tail of outbound calls. Once a destination is important enough to name, model it as a `MeshExternalService` instead, which is the subject of the next scenario.

## How MeshPassthrough decides

A `MeshPassthrough` policy carries a single `passthroughMode`:

<!-- vale off -->
{% table %}
columns:
  - title: Mode
    key: mode
  - title: Effect
    key: effect
  - title: Does `appendMatch` apply?
    key: append
rows:
  - mode: "`All`"
    effect: "Every unmatched outbound destination is reachable. This is the open mesh."
    append: "No"
  - mode: "`None`"
    effect: "No unmatched outbound destination is reachable."
    append: "No"
  - mode: "`Matched`"
    effect: "Only the destinations listed in `appendMatch` are reachable."
    append: "Yes"
{% endtable %}
<!-- vale on -->

Two defaults are easy to confuse, and they point in opposite directions:

* With **no** `MeshPassthrough` policy at all, the `Mesh` controls passthrough through `networking.outbound.passthrough`, which is `true` when unset. Outbound traffic is open.
* With a `MeshPassthrough` policy whose `passthroughMode` is **omitted**, the policy defaults to `Matched`. A `Matched` policy with no `appendMatch` entries reaches nothing, so omitting the field is a deny, not a no-op.

{:.warning}
> When several `MeshPassthrough` policies select the same proxy, only one `passthroughMode` survives. Policies are ordered by how specific their `targetRef` is, so a `Dataplane` selector beats a `Mesh` selector. Policies with the same kind of `targetRef` are broken by name, and the alphabetically first name wins. A leftover `allow-all-passthrough` therefore silently overrides a later `secure-perimeter`. Delete the policy you are replacing rather than layering another one on top. See [Policy targeting and precedence](/mesh/policy-targeting-and-precedence/).

### Where the policy lives

The examples in this guide create policies in `kong-air-production`, the application namespace. The control plane computes `kuma.io/policy-role: workload-owner` for a single-item policy in an application namespace, and that role restricts the policy to proxies in the same namespace. `targetRef.kind: Mesh` therefore means "every Kong Air proxy in this namespace", which is what an application team should be able to set for itself.

To set a perimeter for the whole mesh, including workloads in other namespaces, create the policy in `{{site.mesh_namespace}}` instead, where it computes to the `system` role and carries no namespace restriction. On a zone control plane connected to a global control plane, a policy in the system namespace must also carry `kuma.io/origin: zone`. See [Resource scoping](/mesh/resource-scoping/).

{:.info}
> Interaction with mesh-scoped zone egress. A mesh-scoped zone egress is **deny-all** by default for `MeshExternalService` traffic. Every `MeshExternalService` filter chain ends in a deny, so a call returns `403 Forbidden` until a `MeshTrafficPermission` names both the caller's SPIFFE ID and the destination SNI. `MeshPassthrough` is the control for everything that is not modelled as an external service. See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## Move the mesh from open to allowlisted

Each step replaces the previous one. Apply them in order, deleting the policy you are moving on from, so that exactly one `Mesh`-scoped `MeshPassthrough` policy is in force at a time.

1. Record the starting point. Pick a destination your cluster can resolve and reach, and confirm it works before any policy exists. Without this baseline you cannot tell a policy block apart from a DNS failure, because both produce a silent non-zero exit:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.google.com
   ```

   Expected result: the command prints the response body.
   {:.no-copy-code}

1. Make the open posture explicit. `passthroughMode: All` states the behavior the mesh already has, which is useful as a declared baseline that an audit can read:

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

1. Close the perimeter. Delete the open policy first, otherwise it keeps winning on name order and nothing changes:

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

   Every Kong Air proxy in `kong-air-production` now reaches only the destinations the mesh knows about. Traffic to anything else is dropped at the sidecar.

1. Reopen the destinations you have decided to allow. `appendMatch` accepts `Domain`, `IP`, and `CIDR` entries, each with an optional `port` and a `protocol` that defaults to `tcp`:

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

   A match is a destination, a port, and a protocol together. `*.google.com` on port 80 over HTTP does not allow the same host on port 443, so an application that upgrades to HTTPS needs its own entry. For the validation rules on wildcards, ports, and protocols, see [MeshPassthrough](/mesh/policies/meshpassthrough/).

{:.info}
> Use `MeshPassthrough` at the `Mesh` level to set a security baseline, then use a `Dataplane` selector to grant exceptions to the workloads that need broader access. A `Dataplane` selector is more specific than `Mesh`, so the exception wins for the proxies it matches and leaves the baseline in place for everything else.

## Interaction with egress gateways

For a perimeter you can audit centrally, combine `MeshPassthrough` with a zone egress.

1. Direct mode: the sidecar calls the external destination itself, and `MeshPassthrough` is enforced in the sidecar.
1. Egress mode: outbound traffic is routed to the zone egress. Traffic to a `MeshExternalService` leaves through that proxy and is governed there with `MeshTrafficPermission`, which denies it until a rule allows the caller. Passthrough traffic, which by definition has no `MeshExternalService`, is still decided by `MeshPassthrough` at the sidecar.

## Validate

1. Confirm a destination outside the allowlist is blocked. Use a host that succeeded in the baseline step, so a failure now can only come from the policy:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.bing.com
   ```

   Expected result: the command fails with a non-zero exit status and prints no response body. The sidecar has no filter chain for this destination, so the connection is dropped rather than refused.
   {:.no-copy-code}

1. Confirm the allowlist entry still works:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.google.com
   ```

   Expected result: the command prints the response body.
   {:.no-copy-code}

1. Confirm the match is port-specific and protocol-specific. The same host on port 443 is not covered by the port 80 entry:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- https://www.google.com
   ```

   Expected result: the command fails. Add a second `appendMatch` entry for port 443 with `protocol: tls` if the workload needs HTTPS to this host.
   {:.no-copy-code}

Policies reach the proxies over xDS within a few seconds and need no restart. If a result looks stale, wait and run the command again.
