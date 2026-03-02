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
    1. **Assign dedicated DNS**: Give external APIs friendly internal names (e.g., `aeropay.ext.svc`).
    2. **Enable Observability**: Get metrics and logs for outbound calls just like internal services.
    3. **Apply Resiliency**: Use `MeshHTTPRoute` to configure retries and timeouts for external dependencies.
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

First, we define how external services will be named within Kong Air using a `HostnameGenerator`. This creates a dedicated internal domain space for our external dependencies.

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: external-services
  namespace: {{site.mesh_system_namespace}}
spec:
  template: '{{ .DisplayName }}.ext.kongair.com'
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
```

## 3. Defining the RDS Database (TCP)

Kong Air uses a managed PostgreSQL instance for flight data. By defining it as a `MeshExternalService`, the `booking-svc` can reach it via `flight-db.ext.kongair.com` using its standard database driver.

> [!NOTE]
> The application uses the **friendly mesh hostname** (`flight-db.ext.kongair.com`) and **plain TCP**. The sidecar intercepts this and routes it to the actual AWS RDS endpoint.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: flight-db
  namespace: kong-air-production
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
      port: 5432
```

## 4. Securing AeroPay (HTTPS with TLS Origination)

For the AeroPay API, Sarah (the Security Architect) wants to ensure all traffic is encrypted, but she doesn't want developers managing Stripe-specific CA bundles. `MeshExternalService` handles the TLS origination at the sidecar.

> [!IMPORTANT]
> The application calls the AeroPay service using **standard HTTP** (not HTTPS) at the mesh-internal address `http://aeropay-api.ext.kongair.com`. The sidecar then upgrades this to **HTTPS** before it leaves the mesh.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: aeropay-api
  namespace: kong-air-sec
spec:
  match:
    type: HostnameGenerator
    port: 443
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


## 6. Adding Resiliency with MeshHTTPRoute

Because AeroPay is now a first-class citizen, Devin (the Developer) can apply standard mesh policies to it. If AeroPay is momentarily slow or returns a 5xx error, the mesh can automatically retry.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: aeropay-retry-policy
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: "/"
          default:
            filters:
              - type: RequestRetry
                requestRetry:
                  http:
                    numRetries: 3
                    retryOn: ["5xx", "connect-failure"]

> [!TIP]
> While `MeshHTTPRoute` is the modern standard for HTTP-specific retries, you can also use **MeshRetry** for broader service-level retries or **MeshCircuitBreaker** to prevent the mesh from overwhelming an external service that is struggling.
```

## Summary

By using `MeshExternalService`, Kong Air has achieved:
1. **Zero-Trust**: No traffic leaves the mesh unless explicitly defined.
2. **Simplified Dev**: Developers use `aeropay-api.ext.kongair.com` instead of complex external URLs.
3. **Operational Excellence**: Centralized control over retries and TLS for all third-party dependencies.
