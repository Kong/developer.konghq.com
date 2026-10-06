---
title: Manage external services with MeshExternalService
content_type: how_to
permalink: /mesh/manage-external-services-with-meshexternalservice/
description: Learn how to manage external dependencies like APIs and databases as first-class mesh citizens, enabling observability, resiliency, and dedicated DNS.
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
  q: How do I manage specific external services as part of my mesh?
  a: |
    Use **MeshExternalService** to:
    1. **Assign dedicated DNS**: Give external APIs stable internal names (for example `aeropay-api.extsvc.mesh.local`).
    2. **Enable Observability**: Get metrics and logs for outbound calls just like internal services.
    3. **Apply Resiliency**: Use `MeshRetry`, `MeshTimeout`, and related mesh policies to configure retries and timeouts for external dependencies.
prereqs:
  inline:
    - title: Mesh-scoped zone egress
      content: |
        A mesh-scoped zone egress for `kong-air-mesh`. [Install {{site.mesh_product_name}} and deploy Kong Air](/mesh/install-kong-mesh-and-deploy-kong-air/) already deploys one, through the same Helm `meshes:` entry that creates the zone proxy `Deployment` and the `Service` the control plane reads the listener address and port from. See [Configure mesh-scoped zone proxies](/mesh/configure-mesh-scoped-zone-proxies/) to confirm it's running, or to add the same `meshes:` entry to a different zone control plane. A deployment without its `Service` registers as an ordinary `Dataplane` and never becomes a zone egress.
    - title: Workload identity
      content: |
        A `MeshIdentity` whose selector covers the zone proxies in `{{site.mesh_namespace}}` as well as the application workloads. See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).
cleanup:
  inline:
    - title: Remove the external service definitions
      include_content: md/mesh/v3/cleanup/external-services
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Validate resilience with fault injection"
    url: "/mesh/validate-resilience-with-fault-injection/"
related_resources:
  - text: MeshExternalService
    url: /mesh/meshexternalservice/
  - text: MeshRetry
    url: /mesh/policies/meshretry/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

## Why MeshExternalService?

In the previous scenario, we secured the perimeter using `MeshPassthrough`. However, for critical dependencies like AeroPay (Kong Air's payment provider) or the core RDS Database, we need more than just an "allowlist."

We want these dependencies to feel like internal services:
- Consistent naming: No more hardcoded IP addresses or external URLs.
- Traffic control: The ability to retry failed calls to AeroPay without changing application code.
- Security: TLS origination at the sidecar, so the application doesn't need to manage external certificates.

## Set the naming standard

On Kubernetes, {{site.mesh_product_name}} ships with a default `HostnameGenerator` that assigns each zone-local `MeshExternalService` a generated hostname and a virtual IP. For the hostname format, the VIP CIDR, and how sidecar TLS origination works, see [MeshExternalService](/mesh/meshexternalservice/).

If Kong Air wants a custom naming scheme, that is an operator-level customization of `HostnameGenerator`, not something each application team should redefine in every scenario.

## How the traffic leaves the mesh

When workloads have an identity from `MeshIdentity`, a sidecar does not dial an external endpoint itself. It routes `MeshExternalService` traffic to the mesh-scoped zone egress that belongs to the same mesh, and the egress makes the outbound call. That extra hop is what gives the mesh one enforcement point for every external dependency.


## Define the RDS database

Kong Air uses a managed PostgreSQL instance for flight data. By defining it as a `MeshExternalService`, the application can reach it through a mesh-generated hostname instead of hardcoding the AWS endpoint directly.

{:.info}
> On Kubernetes, `MeshExternalService` can only be created in the system namespace (`{{site.mesh_namespace}}`). A zone control plane connected to a global control plane requires every resource created in that namespace to carry `kuma.io/origin: zone`, and rejects it otherwise, which applies to the `MeshTrafficPermission` and `MeshRetry` in this guide as well. In an application namespace the control plane computes the label for you. See [Resource scoping](/mesh/resource-scoping/).

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: flight-db
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
      port: 5432
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
```

This keeps the application configuration simple while still aiming for encrypted traffic between the sidecar and the managed database.

## Restrict database access by workload

Defining `flight-db` does not grant anyone access to it. The mesh-scoped zone egress `Dataplane` is deny-all by default for `MeshExternalService` traffic, so every call returns `403 Forbidden` until a policy names the caller. Kong Air wants exactly one caller, `flight-control`, so grant access per workload with `MeshTrafficPermission`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: flight-db-access
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
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

Each `allow` entry pairs a source identity (the workload SPIFFE ID from mTLS) with a destination (the external service SNI). A connection is allowed only when both match, any unmatched connection is dropped.

### Derive the SNI

The SNI for a zone-local `MeshExternalService` follows this deterministic format:

```
sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>
```

The final segment is the listener's section name, which for a `MeshExternalService` is its `match.port`. Substitute the values directly from the resource metadata. For `flight-db` created in zone `zone1`:

```
sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
```

To look up the zone name at runtime:

```bash
kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
  -l kuma.io/listener-zoneegress=enabled \
  -o jsonpath='{.items[0].metadata.labels.kuma\.io/zone}{"\n"}'
```

Expected output:

```text
zone1
```
{:.no-copy-code}

{:.info}
> Use the fully qualified `dataplanes.kuma.io`. If the {{site.gateway_operator_product_name}} is installed in the same cluster, the short name `dataplane` resolves to `dataplanes.gateway-operator.konghq.com` instead and the command returns nothing.

### Derive the SPIFFE ID

{{site.mesh_product_name}} issues SPIFFE IDs with the format:

```
spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>
```

The trust domain comes from the `MeshIdentity` that issued the certificate. When the built-in backend generates it, the default format is `<mesh>.<zone>.mesh.local`. For `flight-control` in zone `zone1`, running in the `kong-air-production` namespace with the `flight-control` Kubernetes service account, the SPIFFE ID is:

```
spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/flight-control
```

Read the resolved trust domain from the `MeshTrust` that the identity generates. `MeshIdentity` does not publish it in its own status:

```bash
kubectl get meshtrust kong-air-identity -n {{site.mesh_namespace}} \
  -o jsonpath='{.spec.trustDomain}{"\n"}'
```

Expected output:

```text
kong-air-mesh.zone1.mesh.local
```
{:.no-copy-code}

{:.info}
> Multiple workloads, multiple rules. Add more entries under `rules[0].default.allow` to grant additional workloads access to the same or different external services. To allow a workload to reach any external service through zone egress, omit the `sni` field from that entry.

## Secure AeroPay (HTTPS with TLS origination)

For the AeroPay API, the security architect wants to ensure all traffic is encrypted, but does not want developers managing third-party CA bundles in application code. `MeshExternalService` is the resource intended to handle TLS origination at the sidecar.

{:.info}
> If Kong Air wants developers to call the service with plain HTTP inside the mesh, the internal match port should be an HTTP port such as `80`, while the upstream endpoint can still be `443`. The mesh-generated hostname will still come from the `HostnameGenerator`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: aeropay-api
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: api.aeropay.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: api.aeropay.com
```

## Add resiliency with MeshRetry

Because AeroPay is now a first-class citizen, the developer can apply standard mesh policies to it. If AeroPay is momentarily slow or returns a 5xx error, the mesh can automatically retry. Retries are configured with the `MeshRetry` policy, `MeshHTTPRoute` filters cover header rewrites, redirects, and mirroring, but not retries.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: aeropay-retry-policy
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  to:
    - targetRef:
        kind: MeshExternalService
        labels:
          kuma.io/display-name: aeropay-api
      default:
        http:
          numRetries: 3
          retryOn:
            - 5xx
            - ConnectFailure
            - GatewayError
```

{:.info}
> A top-level `spec.targetRef` accepts only `Mesh` or `Dataplane`, so `MeshRetry` attaches to the clients whose retry behavior it configures, and names the destination in the `to[]` list. Destinations are selected by `labels`, not by `name`. It cannot target a `MeshHTTPRoute` (a route).

{:.info}
> Pair this with `MeshCircuitBreaker` to stop the mesh from hammering an external service that is already struggling, and `MeshTimeout` to bound the total time spent retrying.

## Summary

By using `MeshExternalService`, Kong Air has achieved:
1. Explicit outbound inventory: External dependencies are represented as named resources instead of unmanaged passthrough destinations.
2. Stable internal naming: Developers use mesh-generated names such as `aeropay-api.extsvc.mesh.local`.
3. Access control at the egress: `MeshTrafficPermission` on the zone egress Dataplane restricts which workloads can reach each external service, paired with the deny-all default in mesh-scoped zone proxies.
4. Centralized policy control: Retries, timeouts, and TLS settings live in mesh policy rather than scattered application config.

## Validate

1. Confirm both `MeshExternalService` resources were accepted and given a mesh-generated hostname:

   ```sh
   kubectl get meshexternalservice -n {{site.mesh_namespace}}
   ```

   Expected output, the `HOSTNAME` column confirms each external dependency got a stable internal name:

   ```text
   NAME          HOSTNAME
   aeropay-api   aeropay-api.extsvc.mesh.local
   flight-db     flight-db.extsvc.mesh.local
   ```
   {:.no-copy-code}

1. Confirm a mesh-scoped zone egress is carrying `kong-air-mesh`. Everything else in this scenario depends on it, and an empty result is the cause of a `503` that DNS cannot explain:

   ```sh
   kubectl get dataplanes.kuma.io -n {{site.mesh_namespace}} \
     -l kuma.io/listener-zoneegress=enabled,kuma.io/mesh=kong-air-mesh
   ```

   Expected output: one `Dataplane`, named after the zone egress pod.
   {:.no-copy-code}

1. Confirm `flight-control`, the workload authorized by `flight-db-access`, can resolve the generated hostname to its mesh-assigned virtual IP:

   ```sh
   kubectl exec -n kong-air-production deploy/flight-control -- nslookup flight-db.extsvc.mesh.local
   ```

   Expected output: the hostname resolves to an address in the `MeshExternalService` VIP range, confirming `flight-db` is reachable through its generated name rather than the raw RDS endpoint.
   {:.no-copy-code}

1. Confirm the permission is doing the work. Call the AeroPay hostname from a workload no `allow` entry names, and the zone egress rejects it:

   ```sh
   kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 10 -O- http://aeropay-api.extsvc.mesh.local
   ```

   Expected output: `403 Forbidden`. The connection reached the zone egress and was denied there, which is the deny-all default doing its job. Grant access by adding an `allow` entry for that workload's SPIFFE ID and the AeroPay SNI.
   {:.no-copy-code}
