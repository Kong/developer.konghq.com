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
        A running {{site.mesh_product_name}} deployment with **ZoneEgress** enabled.
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

On Kubernetes, {{site.mesh_product_name}} already ships with a default `HostnameGenerator` for zone-local `MeshExternalService` resources. In the validated 2.13 environment, that generator produced hostnames in the form:

```text
<display-name>.extsvc.mesh.local
```

{% tip %}
**Validated 2.13 behavior.** A zone-local `MeshExternalService` named `aeropay-api` was assigned the hostname `aeropay-api.extsvc.mesh.local` and a VIP from the external-service CIDR (`242.0.0.0/8`).
{% endtip %}

If Kong Air wants a custom naming scheme, that is an **operator-level customization** of `HostnameGenerator`, not something each application team should redefine in every scenario.

## 3. Defining the RDS Database

Kong Air uses a managed PostgreSQL instance for flight data. By defining it as a `MeshExternalService`, the application can reach it through a mesh-generated hostname instead of hardcoding the AWS endpoint directly.

> [!NOTE]
> On Kubernetes in multi-zone mode, `MeshExternalService` is a **system-namespace resource**. On a Zone CP, it must be created in `{{site.mesh_system_namespace}}` and carry the label `kuma.io/origin: zone`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: flight-db
  namespace: {{site.mesh_system_namespace}}
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

## 4. Securing AeroPay (HTTPS with TLS Origination)

For the AeroPay API, Sarah (the Security Architect) wants to ensure all traffic is encrypted, but she doesn't want developers managing third-party CA bundles in application code. `MeshExternalService` is the resource intended to handle TLS origination at the sidecar.

> [!IMPORTANT]
> If Kong Air wants developers to call the service with plain HTTP inside the mesh, the **internal match port** should be an HTTP port such as `80`, while the upstream endpoint can still be `443`. The mesh-generated hostname will still come from the `HostnameGenerator`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: aeropay-api
  namespace: {{site.mesh_system_namespace}}
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

{% warning %}
**Engineering validation still required for TLS origination on this 2.13 setup.** In the live validation environment, Kubernetes accepted the `MeshExternalService`, generated the hostname, and programmed the outbound listener, but requests to public HTTPS endpoints failed with:

```text
503 Service Unavailable
TLS error: Secret is not supplied by SDS
```

So the naming and scoping model is validated, but the HTTPS-origination path still needs final engineering confirmation before we present it as fully proven.
{% endwarning %}

## 5. Adding Resiliency with MeshRetry

Because AeroPay is now a first-class citizen, Devin can apply standard mesh policies to it. If AeroPay is momentarily slow or returns a 5xx error, the mesh can automatically retry. Retries are configured with the **`MeshRetry`** policy — `MeshHTTPRoute` filters cover header rewrites, redirects, and mirroring, but **not retries**.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: aeropay-retry-policy
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
    kuma.io/origin: zone
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
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
3. **Centralized policy control**: Retries, timeouts, and TLS settings live in mesh policy rather than scattered application config.
