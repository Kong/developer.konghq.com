---
title: Get started with your first policy
description: A hands-on guide to applying your first security policy with {{site.mesh_product_name}}, enabling mTLS and enforcing zero-trust traffic permissions.
content_type: how_to
permalink: /mesh/get-started-with-your-first-policy/
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - konnect
tags:
  - security
  - mtls
min_version:
  mesh: '3.0'
tldr:
  q: How do I secure my services with {{site.mesh_product_name}}?
  a: |
    Secure your mesh in three steps:
    1. Issue SPIFFE/X.509 workload certificates with `MeshIdentity`.
    2. Use `MeshTLS` to require those identities and reject unencrypted or unauthenticated traffic.
    3. Authorize traffic explicitly by creating `MeshTrafficPermission` policies for your services.
prereqs:
  inline:
    - title: A {{site.konnect_short_name}} account
      include_content: prereqs/products/konnect-account-only
    - title: A running Kubernetes cluster
      include_content: md/mesh/v3/prereqs/kubernetes-cluster
    - title: kongctl
      include_content: md/mesh/v3/prereqs/kongctl
    - title: Create the mesh and connect a Kubernetes zone
      include_content: md/mesh/v3/prereqs/konnect-zone
    - title: Deploy Kong Air
      include_content: md/mesh/v3/prereqs/kong-air-quickstart
cleanup:
  inline:
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
related_resources:
  - text: Issue identity with MeshIdentity
    url: /mesh/issue-identity-with-meshidentity/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
next_steps:
  - text: "Policy targeting and precedence"
    url: "/mesh/policy-targeting-and-precedence/"
---

This scenario starts with one connected Kubernetes zone. Use `kubectl` to manage its workloads and zone-local policies.

## Confirm the unsecured baseline

Before adding security policy, confirm that `flight-control` can reach `check-in-api`:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- \
  wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

The response is the `check-in-api` pod hostname. This establishes the baseline that the next two resources change: `MeshIdentity` gives the workloads authenticated identities, then `MeshTLS` requires those identities and closes the inbound listener until you explicitly authorize a caller.

## Issue workload identity with `MeshIdentity`

In {{site.mesh_product_name}}, workload identity is issued by the `MeshIdentity` resource. This one-zone scenario uses the `Bundled` provider with `autogenerate` as a quick starting point. For the full identity walkthrough, including production provider and multi-zone trust choices, see [Issue identity with MeshIdentity](/mesh/issue-identity-with-meshidentity/).

{:.warning}
> On Kubernetes, `MeshIdentity` can only be created in the system namespace (`{{site.mesh_namespace}}`). A zone control plane connected to a global control plane requires every resource created in that namespace to carry `kuma.io/origin: zone`, and rejects it otherwise, which is why this identity and the two policies that follow it all set the label. In an application namespace the control plane computes the label for you. See [Resource scoping](/mesh/resource-scoping/).

1. Apply the `MeshIdentity`:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshIdentity
   metadata:
     name: kong-air-identity
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
       kuma.io/origin: zone
   spec:
     selector:
       dataplane:
         matchLabels:
           kuma.io/mesh: kong-air-mesh
     provider:
       type: Bundled
       bundled:
         insecureAllowSelfSigned: true
         autogenerate:
           enabled: true
         meshTrustCreation: Enabled
     spiffeID:
       path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}' | kubectl apply -f -
   ```

1. Restart your workloads so each sidecar picks up a new certificate under the `MeshIdentity` backend:

   ```sh
   kubectl rollout restart deployment -n kong-air-production
   ```

1. Verify the identity is active:

   ```sh
   kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
   ```

   You should see one entry per dataplane. The generated KRI varies by zone, but every `issuedBackend` should contain `kong-air-identity`. An empty value means that the `MeshIdentity` selector did not match the workload.

This `MeshIdentity` gives every workload in the mesh a SPIFFE certificate with its Kubernetes service account encoded in the path:

```text
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/check-in-api
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/passenger-portal
```
{:.no-copy-code}

{:.info}
> `MeshIdentity` is an issuer, not an identity. It sets the CA/provider, the SPIFFE ID path template, and the trust domain. The actual SPIFFE ID is rendered per workload from that template. Every workload still gets a unique identity, and `MeshTrafficPermission` keeps full per-workload granularity even with one mesh-wide identity.
>
> Because this example omits `spiffeID.trustDomain`, the zone-aware default is `{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`. For `kong-air-mesh` in `zone1`, that becomes `kong-air-mesh.zone1.mesh.local`. `.Zone` is the zone name you set in `kuma.controlPlane.zone` when you connected the zone, so these identities change if you used a different one.
>
> Add more `MeshIdentity` resources only when a group of workloads needs different issuance (a different CA/provider, path scheme, or rotation policy), not to authorize app-to-app traffic.

## Enforce strict mTLS with `MeshTLS`

`MeshIdentity` issues certificates but does not enforce their use. 

1. Apply a `MeshTLS` policy to reject any unencrypted or unauthenticated traffic across the mesh:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTLS
   metadata:
     name: strict-mtls
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
       kuma.io/origin: zone
   spec:
     targetRef:
       kind: Mesh
     rules:
       - default:
           mode: Strict' | kubectl apply -f -
   ```

   With `MeshTLS` in `Strict` mode, every inbound connection must present a valid mTLS certificate. Unencrypted traffic is rejected at the proxy level before any RBAC evaluation.

1. Confirm that traffic is rejected by calling `check-in-api` from `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The request is now rejected:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   The `403` is the proxy refusing the connection, not the application responding. Every inbound listener in the mesh is closed until a `MeshTrafficPermission` opens it.

## Authorize service-to-service traffic

Now let's grant `flight-control` access to `check-in-api`. The best practice path is to target the receiving data plane and allow the caller's authenticated SPIFFE identity explicitly.

Because each workload runs as its own Kubernetes `ServiceAccount`, the SPIFFE ID encodes the zone, namespace, and service account name. `flight-control` runs in `zone1` as the `flight-control` `ServiceAccount`, so its SPIFFE ID is `spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control`. If you named your zone something other than `zone1` when you connected it, substitute that name in the trust domain:

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: check-in-api
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control' | kubectl apply -f -
```

{:.info}
> **Notes**
> * Policy changes are not always instantaneous. `MeshTrafficPermission` updates can take a few seconds to propagate to the data planes. If a request still succeeds or fails immediately after you apply a policy, wait and try again.
> * Unlike other policies, `MeshTrafficPermission` doesn't use most-specific-match precedence. The control plane evaluates every matching rule for a request, and if any matched rule produces a `Deny`, that deny wins. Keep this in mind before adding a broader allow policy alongside a narrower one. The broader rule won't automatically lose.
> * `MeshTrafficPermission` is enforced on the server side (the receiver's inbound Envoy listener). This means the RBAC decision happens at `check-in-api`, not at `flight-control`.

## Validate

1. Confirm `flight-control` can now reach `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   You should get the pod's hostname:

   ```text
   check-in-api-6b8f9c9d4f-x7z2p
   ```
   {:.no-copy-code}

1. Confirm every other workload is still denied. `passenger-portal` has no `MeshTrafficPermission` allowing it to reach `check-in-api`, so the same request from it should still fail:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   It fails with the same error as before:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

These two results confirm the policy is scoped correctly: `flight-control` is explicitly authorized, and every other workload remains blocked by the default-deny posture.
