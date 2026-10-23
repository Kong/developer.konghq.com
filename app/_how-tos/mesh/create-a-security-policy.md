---
title: Create a security policy
description: Give every Kong Air workload a workload identity with {{site.mesh_product_name}}, which turns on mTLS and default-deny authorization, then allow one service to call another with a traffic permission.
content_type: how_to
permalink: /mesh/create-a-security-policy/
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
series:
  id: mesh-kong-air-scenario
  position: 2
tldr:
  q: How do I secure my services with {{site.mesh_product_name}}?
  a: |
    Secure your mesh in three steps:
    1. Issue SPIFFE workload certificates with `MeshIdentity`. Proxies with an identity require mTLS and deny every caller that no permission allows.
    2. Make `Strict` mTLS explicit with a mesh-wide `MeshTLS` policy.
    3. Allow each caller explicitly with a `MeshTrafficPermission` policy.
related_resources:
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
next_steps:
  - text: "Reference: Policy targeting and precedence"
    url: "/mesh/policy-targeting-and-precedence/"
  - text: "How-to: Split traffic with MeshService resources"
    url: "/mesh/split-traffic-with-meshservice-resources/"
---

## Confirm the unsecured baseline

Before you add any security resources, confirm that `flight-control` can reach `check-in-api`:

```sh
kubectl exec -n kong-air-production deploy/flight-control -- \
  wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
```

The `check-in-api` application responds with its pod hostname.

## Issue workload identity with `MeshIdentity`

The [`MeshIdentity`](/mesh/policies/meshidentity/) resource gives each workload an identity and a certificate.
Kong Air runs in one zone for now, so this guide uses the `Bundled` provider with `autogenerate`.
With this setting, the zone control plane generates its own certificate authority (CA).
For other providers, see [Providers](/mesh/policies/meshidentity/#providers).
For trust across zones, see [Multi-zone meshes](/mesh/policies/meshidentity/#multi-zone-meshes).

{:.warning}
> On Kubernetes, you can only create a `MeshIdentity` in the system namespace (`{{site.mesh_namespace}}`).
> See [Resource scoping](/mesh/resource-scoping/).

1. Create a `MeshIdentity` that issues certificates to every workload in `kong-air-mesh`:

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
       path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}' | kubectl apply -f -
   ```

1. Restart the Kong Air workloads, so each sidecar gets a certificate from `kong-air-identity`:

   ```sh
   kubectl rollout restart deployment -n kong-air-production
   ```

1. Check that each data plane proxy received its certificate from `kong-air-identity`:

   ```sh
   kubectl get dataplaneinsights -n kong-air-production -o yaml | grep -A4 issuedBackend
   ```

   The output shows one entry for each data plane proxy.
   The generated KRI changes from zone to zone, but every `issuedBackend` contains `kong-air-identity`.
   An empty value means that the `MeshIdentity` selector doesn't match the workload.

The `kong-air-identity` resource gives every workload a Secure Production Identity Framework for Everyone (SPIFFE) ID.
The ID path contains the workload's namespace and Kubernetes service account:

```text
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/check-in-api
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/passenger-portal
```
{:.no-copy-code}

{:.info}
> The `kong-air-identity` resource doesn't set `spiffeID.trustDomain`, so the control plane uses the default template, `{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`.
> For `kong-air-mesh` in `zone1`, the trust domain is `kong-air-mesh.zone1.mesh.local`.
> See [SPIFFE ID](/mesh/policies/meshidentity/#spiffe-id).

Now that every proxy has a workload identity, the Kong Air proxies change behavior in two ways:
* Every inbound runs in `Strict` mode, so it accepts only mTLS connections.
* Every inbound denies callers that no `MeshTrafficPermission` allows.

No `MeshTrafficPermission` exists yet, so `check-in-api` now rejects `flight-control` with `403 Forbidden`.
For details, see [Identity requirements](/mesh/policies/meshtrafficpermission/#identity-requirements).

## Make strict mTLS explicit with `MeshTLS`

The [`MeshTLS`](/mesh/policies/meshtls/) policy sets the TLS mode, versions, and ciphers for mesh connections.
Kong Air's proxies already run in `Strict` mode because they have a workload identity.
Kong Air's compliance rules require mTLS on every connection, so you record that requirement in a mesh-wide `MeshTLS` policy.
With this policy in place, the configuration states the `Strict` mode explicitly instead of relying on the default.

1. Create a mesh-wide `MeshTLS` policy that sets the mode to `Strict`:

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

   In `Strict` mode, the receiving proxy accepts only connections with a valid mTLS certificate.
   The proxy rejects plaintext connections before it checks any traffic permission.

1. Confirm that `check-in-api` still rejects calls from `flight-control`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The request fails:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

   The `check-in-api` sidecar returns the `403`, and the request never reaches the application.
   The sidecar denies `flight-control` because no `MeshTrafficPermission` allows it yet.

## Authorize service-to-service traffic

A [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy lets a caller reach a destination.
We recommend that you target the receiving data plane proxy and allow the caller's SPIFFE ID explicitly, because the SPIFFE ID comes from the caller's verified certificate.

Each Kong Air workload runs as its own Kubernetes `ServiceAccount`.
The SPIFFE ID contains the zone, the namespace, and the service account name.
The `flight-control` workload runs in `zone1` as the `flight-control` service account, so its SPIFFE ID is `spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control`.

Create a `MeshTrafficPermission` that allows `flight-control` to call `check-in-api`:

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
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control' | kubectl apply -f -
```

{:.info}
> * The control plane takes a few seconds to send a `MeshTrafficPermission` change to the data plane proxies.
>   If a request returns an unexpected result right after you apply a policy, wait and try again.
> * The receiving proxy enforces `MeshTrafficPermission`, so `check-in-api` makes the decision.
> * When permissions overlap, any matching `deny` wins over every `allow`.
>   See [Overlapping permissions](/mesh/policies/meshtrafficpermission/#overlapping-permissions).

## Validate

1. Confirm that `flight-control` can now reach `check-in-api`:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The response contains the `check-in-api` pod hostname:

   ```text
   check-in-api-6b8f9c9d4f-x7z2p
   ```
   {:.no-copy-code}

1. Confirm that `check-in-api` still denies every other workload.
   No `MeshTrafficPermission` allows `passenger-portal` to reach `check-in-api`, so the same request from `passenger-portal` fails:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- wget -q -T 5 -O- http://check-in-api.kong-air-production.svc.cluster.local:8080/
   ```

   The request fails with the same error as before:

   ```text
   wget: server returned error: HTTP/1.1 403 Forbidden
   ```
   {:.no-copy-code}

These two results confirm that the policy has the right scope.
The policy allows `flight-control`, and `check-in-api` still denies every other workload by default.
