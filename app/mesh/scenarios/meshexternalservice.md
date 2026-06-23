---
title: "First-Class Dependencies: MeshExternalService"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: Learn how to manage external dependencies like APIs and databases as first-class mesh citizens, enabling observability, resiliency, and dedicated DNS.
products:
  - mesh
tldr:
  q: How do I manage specific external services as part of my mesh?
  a: |
    Use **MeshExternalService** to:
    1. **Assign dedicated DNS**: Give external APIs stable internal names (for example `aeropay-api.extsvc.mesh.local`).
    2. **Enable Observability**: Get metrics and logs for outbound calls just like internal services.
    3. **Apply Resiliency**: Use `MeshRetry`, `MeshTimeout`, and related mesh policies to configure retries and timeouts for external dependencies.
prereqs:
  inline:
    - title: Architecture
      content: |
        A running {{site.mesh_product_name}} deployment with ZoneEgress enabled. If you use mesh-scoped zone proxies, deploy them through the Helm `meshes:` list and keep the mesh in `spec.meshServices.mode: Exclusive`.
    - title: Policy
      content: |
        mTLS must be enabled on the `Mesh`.
next_steps:
  - text: "Chaos Engineering: Fault Injection"
    url: "/mesh/scenarios/chaos-engineering/"
---
## 1. Why MeshExternalService?

In the previous scenario, we secured the perimeter using `MeshPassthrough`. However, for critical dependencies like **AeroPay** (Kong Air's payment provider) or the core **RDS Database**, we need more than just an "allowlist."

We want these dependencies to feel like internal services:
- **Consistent Naming**: No more hardcoded IP addresses or external URLs.
- **Traffic Control**: The ability to retry failed calls to AeroPay without changing application code.
- **Security**: TLS origination at the sidecar, so the application doesn't need to manage external certificates.

## 2. Setting the Naming Standard

On Kubernetes, {{site.mesh_product_name}} already ships with a default `HostnameGenerator` for zone-local `MeshExternalService` resources. That generator produces hostnames in the form:

```text
<display-name>.extsvc.mesh.local
```

{% tip %}
For example, a zone-local `MeshExternalService` named `aeropay-api` is assigned the hostname `aeropay-api.extsvc.mesh.local` and a VIP from the external-service CIDR (`242.0.0.0/8`).
{% endtip %}

If Kong Air wants a custom naming scheme, that is an **operator-level customization** of `HostnameGenerator`, not something each application team should redefine in every scenario.

## 3. Defining the RDS Database

Kong Air uses a managed PostgreSQL instance for flight data. By defining it as a `MeshExternalService`, the application can reach it through a mesh-generated hostname instead of hardcoding the AWS endpoint directly.

{% tip %}
On Kubernetes in multi-zone mode, `MeshExternalService` is a **system-namespace resource**. On a Zone CP, it must be created in `{{site.mesh_namespace}}` and carry the label `kuma.io/origin: zone`.
{% endtip %}

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

## 4. Restricting Database Access by Workload

The `flight-db` MeshExternalService is now reachable from any workload that routes through zone egress, too broad for a production database. Only `flight-control` should have direct access.

With **mesh-scoped zone proxies** (Kong Mesh 2.14+), the zone egress Dataplane is **deny-all by default** for `MeshExternalService` traffic. Grant access per workload with `MeshTrafficPermission`:

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
              value: spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
            sni:
              type: Exact
              value: sni.extsvc.kong-air-mesh.zone1.{{site.mesh_namespace}}.flight-db.5432
```

Each `allow` entry pairs a **source identity** (the workload SPIFFE ID from mTLS) with a **destination** (the external service SNI). A connection is allowed only when both match, any unmatched connection is dropped.

### Deriving the SNI

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
kubectl get dataplane -n {{site.mesh_namespace}} \
  -l kuma.io/listener-zoneegress=enabled \
  -o jsonpath='{.items[0].metadata.labels.kuma\.io/zone}'
```

### Deriving the SPIFFE ID

{{site.mesh_product_name}} issues SPIFFE IDs with the format:

```
spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>
```

The trust domain is set in the `MeshIdentity` backend (the `trustDomain` field, or the auto-generated `<mesh-name>.mesh.local` when using the built-in backend). For `flight-control` running in the `kong-air-production` namespace with the `flight-control` Kubernetes service account:

```
spiffe://kong-air-mesh.mesh.local/ns/kong-air-production/sa/flight-control
```

To look up the trust domain from the active identity backend:

```bash
kubectl get meshidentity -n {{site.mesh_namespace}} \
  -o jsonpath='{.items[0].spec.spiffeID.trustDomain}'
```

{% tip %}
Multiple workloads, multiple rules. Add more entries under `rules[0].default.allow` to grant additional workloads access to the same or different external services. To allow a workload to reach *any* external service through zone egress, omit the `sni` field from that entry.
{% endtip %}

{% tip %}
The `deny-all by default` behavior is specific to **mesh-scoped zone proxies** introduced in 2.14. If you are still using the legacy global `ZoneEgress`, set `spec.routing.defaultForbidMeshExternalServiceAccess: true` on the `Mesh` resource to enforce a mesh-wide deny.
{% endtip %}

## 5. Securing AeroPay (HTTPS with TLS Origination)

For the AeroPay API, Sarah (the Security Architect) wants to ensure all traffic is encrypted, but she doesn't want developers managing third-party CA bundles in application code. `MeshExternalService` is the resource intended to handle TLS origination at the sidecar.

{% tip %}
If Kong Air wants developers to call the service with plain HTTP inside the mesh, the **internal match port** should be an HTTP port such as `80`, while the upstream endpoint can still be `443`. The mesh-generated hostname will still come from the `HostnameGenerator`.
{% endtip %}

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

### Troubleshooting: external calls fail with a 503

{% warning %}
If a request through a mesh-scoped zone egress fails with the following, the zone egress proxy has **no workload identity certificate**:

```
503 Service Unavailable
TLS error: Secret is not supplied by SDS
```
{% endwarning %}

**Why it happens.** The zone egress proxies run in `{{site.mesh_namespace}}`. If your `MeshIdentity` selector matches only an application namespace (for example `kong-air-production`), nothing selects the zone proxies, so the control plane issues them no certificate. The SDS secret backing the egress's mTLS leg is never delivered, and the connection fails on the in-mesh mTLS hop before it ever reaches the external endpoint. (This is why even a plain-HTTP `MeshExternalService` reproduces it: the failing leg is the hop to the egress, not the external TLS origination.)

**The fix: make sure a `MeshIdentity` selects the zone proxies.** A `MeshIdentity` only covers the dataplanes its selector matches (an absent selector matches *nothing*). The cleanest fix is a **single mesh-wide identity** that covers both your apps and the zone proxies with one CA, selecting on the mesh label rather than an app namespace:

```yaml
apiVersion: kuma.io/v1alpha1
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
        kuma.io/mesh: kong-air-mesh   # every dataplane in the mesh, incl. zone proxies
  provider:
    type: Bundled
    bundled:
      insecureAllowSelfSigned: true
      autogenerate: { enabled: true }
      meshTrustCreation: Enabled
  spiffeID:
    path: /ns/{% raw %}{{ .Namespace }}{% endraw %}/sa/{% raw %}{{ .ServiceAccount }}{% endraw %}
    trustDomain: kong-air-mesh.mesh.local
```

The mesh-wide `MeshIdentity` from [Getting Started](/mesh/scenarios/getting-started-policy/) already covers the zone proxies. If yours is instead scoped to a single app namespace, **broaden its selector** to the mesh label rather than adding a second identity. Apply it at the Global CP, then restart the zone proxies so they pick up a certificate:

```bash
# The mesh-scoped zone-proxy deployments carry the kuma.io/mesh label.
kubectl rollout restart deployment -n {{site.mesh_namespace}} -l kuma.io/mesh=kong-air-mesh

# Verify the egress now has an issued identity (its DataplaneInsight is named after the pod):
ZE=$(kubectl get pods -n {{site.mesh_namespace}} \
  -l k8s.kuma.io/zone-proxy-type=egress -o jsonpath='{.items[0].metadata.name}')
kubectl get dataplaneinsight -n {{site.mesh_namespace}} "$ZE" \
  -o jsonpath='{.status.mTLS.issuedBackend}'
# → a non-empty kri_mid_... backend (empty means no MeshIdentity selects the zone proxies)
```

{% tip %}
**Multi-zone:** prefer a **shared external CA** (Vault, cert-manager, or ACM, see [Enterprise PKI](/mesh/scenarios/external-ca-vault/)) over `autogenerate`. With `autogenerate`, every `MeshIdentity` mints its own per-zone CA, and each one then needs the same cross-zone `MeshTrust` reconciliation described in [Workload Identity](/mesh/scenarios/workload-identity/#cross-zone-trust-with-autogenerated-cas). A shared root means apps **and** zone proxies in **every** zone chain to one CA, so this just works. Avoid adding a separate per-namespace `autogenerate` identity for the zone proxies in multi-zone, it multiplies the CAs you have to reconcile.
{% endtip %}

## 6. Adding Resiliency with MeshRetry

Because AeroPay is now a first-class citizen, Devin can apply standard mesh policies to it. If AeroPay is momentarily slow or returns a 5xx error, the mesh can automatically retry. Retries are configured with the **`MeshRetry`** policy, `MeshHTTPRoute` filters cover header rewrites, redirects, and mirroring, but **not retries**.

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
        name: aeropay-api
      default:
        http:
          numRetries: 3
          retryOn:
            - 5xx
            - ConnectFailure
            - GatewayError
```

{% tip %}
Pair this with **`MeshCircuitBreaker`** to stop the mesh from hammering an external service that is already struggling, and **`MeshTimeout`** to bound the total time spent retrying.
{% endtip %}

## Summary

By using `MeshExternalService`, Kong Air has achieved:
1. **Explicit outbound inventory**: External dependencies are represented as named resources instead of ad hoc passthrough destinations.
2. **Stable internal naming**: Developers use mesh-generated names such as `aeropay-api.extsvc.mesh.local`.
3. **Access control at the egress**: `MeshTrafficPermission` on the zone egress Dataplane restricts which workloads can reach each external service, paired with the deny-all default in mesh-scoped zone proxies.
4. **Centralized policy control**: Retries, timeouts, and TLS settings live in mesh policy rather than scattered application config.
