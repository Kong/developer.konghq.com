---
title: Get started with your first policy
description: A hands-on guide to applying your first security policy with {{site.mesh_product_name}}, enabling mTLS and enforcing zero-trust traffic permissions.
content_type: how_to
permalink: /mesh/scenarios/get-started-with-your-first-policy/
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tags:
  - security
  - mtls
min_version:
  mesh: '2.14'
tldr:
  q: How do I secure my services with {{site.mesh_product_name}}?
  a: |
    Secure your mesh in three steps:
    1. Issue workload identity via `MeshIdentity` to encrypt all traffic with SPIFFE/X.509 certificates.
    2. Enforce strict mTLS via `MeshTLS` to reject any unencrypted or unauthenticated traffic.
    3. Authorize traffic explicitly by creating `MeshTrafficPermission` policies for your services.
prereqs:
  inline:
    - title: kubectl
      include_content: prereqs/tools/kubectl
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with the Kong Air demo
      include_content: prereqs/kubernetes/kong-air-quickstart
related_resources:
  - text: Issue identity with MeshIdentity
    url: /mesh/issue-identity-with-meshidentity/
  - text: Resource scoping
    url: /mesh/scenarios/resource-scoping/
  - text: Manage workload identity and mTLS
    url: /mesh/scenarios/manage-workload-identity-and-mtls/
next_steps:
  - text: "Policy targeting and precedence"
    url: "/mesh/scenarios/policy-targeting-and-precedence/"
---

## Issue workload identity with `MeshIdentity`

In {{site.mesh_product_name}} 2.14+, workload identity is issued by the `MeshIdentity` resource. This guide uses the `Bundled` provider with `autogenerate`, the recommended starting point. For the full identity walkthrough, including provider options and verification, see [Issue identity with MeshIdentity](/mesh/issue-identity-with-meshidentity/).

{:.warning}
> `MeshIdentity` must be created in the system namespace (`{{site.mesh_namespace}}`) on Kubernetes. Apply it against your Global CP.

1. Apply the `MeshIdentity`:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshIdentity
   metadata:
     name: kong-air-identity
     namespace: {{site.mesh_namespace}}
     labels:
       kuma.io/mesh: kong-air-mesh
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
       path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
       trustDomain: kong-air-mesh.mesh.local' | kubectl apply -f -
   ```

1. Restart your workloads so each sidecar picks up a new certificate under the `MeshIdentity` backend:

   ```sh
   kubectl rollout restart deployment -n kong-air-production
   ```

1. Verify the identity is active. `issuedBackend` should reference `kong-air-identity`:

   ```sh
   kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
   ```

   Expected output (one entry per dataplane), with the zone (`default` for a single-zone deployment) and system namespace encoded in the KRI:

   ```yaml
         issuedBackend: kri_mid_kong-air-mesh_default_kong-mesh-system_kong-air-identity_
         lastCertificateRegeneration: "2026-08-12T09:04:55.455276987Z"
         supportedBackends:
         - kri_mtrust_kong-air-mesh_default_kong-mesh-system_kong-air-identity_
   ```
   {:.no-copy-code}

This `MeshIdentity` gives every workload in the mesh a SPIFFE certificate with its Kubernetes service account encoded in the path:

```text
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/check-in-api
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/passenger-portal
```
{:.no-copy-code}

{:.info}
> Mesh-wide does not mean "one shared identity." A `MeshIdentity` is an issuer, not an identity: it sets the CA/provider, the SPIFFE ID path template, and the trust domain. The actual SPIFFE ID is rendered per workload from that template, so every workload still gets a unique identity (as the three distinct IDs above show), and `MeshTrafficPermission` keeps full per-workload granularity even with one mesh-wide identity.
>
> Add more `MeshIdentity` resources only when a group of workloads needs different issuance (a different CA/provider, path scheme, or rotation policy), not to authorize app-to-app traffic.

{:.warning}
> Multi-zone deployments need an extra cross-zone trust step. The `autogenerate: enabled: true` option lets each Zone CP generate its own CA independently. This is convenient but means each zone has a different CA, so cross-zone mTLS fails at the ZoneIngress TLS handshake. To fix this, create a combined `MeshTrust` on each zone containing all zones' CA bundles. See [Manage workload identity and mTLS](/mesh/scenarios/manage-workload-identity-and-mtls/) for the full procedure and the production alternative (shared CA or SPIRE).

## Enforce strict mTLS with `MeshTLS`

`MeshIdentity` issues certificates but does not enforce that they are used. Apply a `MeshTLS` policy to reject any unencrypted or unauthenticated traffic across the mesh:

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: strict-mtls
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict' | kubectl apply -f -
```

With `MeshTLS` in `Strict` mode, every inbound connection must present a valid mTLS certificate. Unencrypted traffic is rejected at the proxy level before any RBAC evaluation.

## Confirm the default-deny posture

{{site.mesh_product_name}} does not create any traffic permissions by default. With no `MeshTrafficPermission` policy in place, every inter-service request is denied, even between workloads that both have a valid identity.

Confirm this by calling `check-in-api` from `flight-control`, a service that isn't authorized to reach it yet:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

Expected result: the command fails, `wget` exits with a non-zero status and prints no response body, confirming the request was denied.
{:.no-copy-code}

{:.info}
> Policy changes are not always instantaneous. `MeshTrafficPermission` updates can take a few seconds to propagate to the dataplanes. If a request still succeeds or fails immediately after you apply a policy, wait a moment and test again before assuming the policy shape is wrong.

## Explicitly authorize service-to-service traffic

Now grant `flight-control` access to `check-in-api`. The best-practice path is to target the receiving dataplane and allow the caller's authenticated SPIFFE identity explicitly.

Because each workload runs as its own Kubernetes `ServiceAccount`, the SPIFFE ID encodes the service account name. `flight-control` runs as the `flight-control` `ServiceAccount`, so its SPIFFE ID is:

```text
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
```
{:.no-copy-code}

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-flight-control-to-check-in
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
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
              value: spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control' | kubectl apply -f -
```

{:.info}
> `MeshTrafficPermission` is a special case in {{site.mesh_product_name}}: it doesn't use most-specific-match precedence. The control plane evaluates every matching rule for a request, and if any matched rule produces a `Deny`, that deny wins. Keep this in mind before adding a broader allow policy alongside a narrower one, the broader rule won't automatically lose.

{:.info}
> `MeshTrafficPermission` is enforced on the server side (the receiver's inbound Envoy listener). This means the RBAC decision happens at `check-in-api`, not at `flight-control`.

{:.info}
> If you see older runbooks using `MeshSubset`, top-level `MeshService`, or `spec.from`, update them to `Dataplane` + `rules` to match the resource model used in this guide.

## Validate

1. Confirm `flight-control` can now reach `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected output: the pod's hostname, for example:

   ```text
   check-in-api-6b8f9c9d4f-x7z2p
   ```
   {:.no-copy-code}

1. Confirm every other workload is still denied. `passenger-portal` has no `MeshTrafficPermission` allowing it to reach `check-in-api`, so the same request from it should still fail:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   Expected result: the command fails and prints no response body, confirming the request is still denied.
   {:.no-copy-code}

Together, these two results confirm the policy is scoped correctly: `flight-control` is explicitly authorized, and every other workload remains blocked by the default-deny posture.
