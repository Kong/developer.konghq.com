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
  position: 11
tldr:
  q: How do I control traffic to services outside the mesh?
  a: |
    On a control plane that sets `restrictOutbound` to `false`, apply a `MeshPassthrough` policy to:
    1. Block unknown destinations with `passthroughMode: None`.
    2. Allow specific destinations with `passthroughMode: Matched` and `appendMatch` entries (for example, `httpbin.konghq.com` on port 80).
    3. Keep one auditable record of the external destinations your workloads can reach.
faqs:
  - q: What happens to traffic to unknown destinations when no `MeshPassthrough` policy selects a proxy?
    a: |
      It depends on the `restrictOutbound` setting of the control plane.
      {{site.mesh_product_name}} 3.0 defaults `restrictOutbound` to `true`, so a proxy that no `MeshPassthrough` policy selects drops that traffic.
      The Kong Air control plane sets `restrictOutbound` to `false`, so its proxies forward that traffic to any destination, through the Envoy "Original Destination" cluster.
      [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) turns the setting on for Kong Air.
  - q: What does each `passthroughMode` do?
    a: |
      `All` lets traffic to every unknown destination pass, `None` lets none pass, and `Matched` lets only the destinations in `appendMatch` pass.
      A policy that leaves out `passthroughMode` uses `Matched`, so a policy without `appendMatch` entries blocks every unknown destination.
      For the full behavior of each mode, see [MeshPassthrough modes](/mesh/policies/meshpassthrough/#modes).
  - q: Which values can an `appendMatch` entry use?
    a: |
      `appendMatch` accepts `Domain`, `IP`, and `CIDR` entries.
      Each entry takes an optional `port`, and a `protocol` that defaults to `tcp`.
      A `Domain` entry can't use `tcp` or `mysql`, so set its `protocol`.
      An exact domain always needs a `port`, because the sidecar resolves the domain itself and connects to that port.
      A wildcard domain needs a `port` with `http`, `http2`, or `grpc`.

      A match combines a destination, a port, and a protocol, so an entry for a host on port 80 over HTTP doesn't allow the same host on port 443.
      For the validation rules, see [MeshPassthrough](/mesh/policies/meshpassthrough/).
  - q: How do I set one perimeter for every namespace in the zone?
    a: |
      Create the `MeshPassthrough` policy in `{{site.mesh_namespace}}` instead of `kong-air-production`.
      A policy in an application namespace reaches only the proxies in that namespace, and a policy in the system namespace reaches every proxy in the zone.
      For how the namespace sets a policy's reach, see [Policy scope](/mesh/policy-targeting/#policy-scope).
  - q: How do I give one workload broader outbound access than the baseline?
    a: |
      Keep the `Mesh`-level `MeshPassthrough` policy as the baseline, and add a policy with a `Dataplane` selector for the workloads that need broader access.
      A `Dataplane` selector is more specific than `Mesh`, so the exception wins for the proxies it matches, and the baseline stays in place for every other proxy.
      See [Policy precedence](/mesh/policy-targeting/#policy-precedence).
  - q: When should I use `MeshExternalService` instead of `MeshPassthrough`?
    a: |
      Use `MeshPassthrough` for the long tail of outbound calls to destinations that the mesh doesn't model.
      The sidecar enforces it and connects to those destinations directly.

      When a destination matters enough to name, model it as a `MeshExternalService`, as in [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).
      `MeshExternalService` traffic goes through the zone egress, where a `MeshTrafficPermission` must allow each caller.
      For both paths, see [Traffic paths](/mesh/mesh-scoped-zone-proxies/#traffic-paths).
  - q: Does `MeshPassthrough` work without transparent proxying?
    a: |
      No. `MeshPassthrough` applies only to sidecars that run with transparent proxying.
      The Kubernetes sidecar injector turns it on by default.
      For a proxy without it, the control plane skips the policy and records a warning.
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

The Kong Air mesh starts open: its control plane sets `restrictOutbound` to `false`, so a sidecar forwards traffic to any external destination.
In this guide, close the perimeter with a `MeshPassthrough` policy, then update the same policy to allow only the external destinations that Kong Air needs.

## Record the baseline

Confirm that `check-in-api` reaches an external destination before any policy exists.
Pick a destination that your cluster can resolve and reach, so that you can tell a policy block from a DNS failure later:

```sh
kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://httpbin.konghq.com/ip
```

The command prints the IP address that `httpbin.konghq.com` saw:

```json
{
  "origin": "203.0.113.25"
}
```
{:.no-copy-code}

## Close the perimeter

1. Create a `kong-air-perimeter` policy with `passthroughMode: None`:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: MeshPassthrough
   metadata:
     name: kong-air-perimeter
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

1. Call the same destination again:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://httpbin.konghq.com/ip
   ```

   The command fails with a non-zero exit status and prints no response body.
   The Kong Air proxies in `kong-air-production` now reach only the destinations that the mesh knows about.

## Allow selected destinations

Update `kong-air-perimeter` to `passthroughMode: Matched`, so only the destinations in `appendMatch` pass:

```sh
kubectl apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshPassthrough
metadata:
  name: kong-air-perimeter
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
        value: httpbin.konghq.com
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

## Validate

1. Confirm that the policy blocks a destination outside the allowlist.
   Use a host that your cluster can resolve and reach, so that only the policy can cause a failure:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://httpbin.org/ip
   ```

   The command fails with a non-zero exit status and prints no response body.
   The sidecar has no route for `httpbin.org` on port 80, so it answers with `503 Service Unavailable`.

1. Confirm that the `httpbin.konghq.com` entry allows traffic to that host on port 80:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://httpbin.konghq.com/ip
   ```

   The command prints the IP address that `httpbin.konghq.com` saw:

   ```json
   {
     "origin": "203.0.113.25"
   }
   ```
   {:.no-copy-code}

1. Confirm that the port 80 entry doesn't cover the same host on port 443:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- https://httpbin.konghq.com/ip
   ```

   The command fails.
   If the workload needs HTTPS to this host, add a second `appendMatch` entry for port 443 with `protocol: tls`.
