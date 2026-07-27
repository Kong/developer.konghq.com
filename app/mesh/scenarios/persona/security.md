---
title: Sarah the Security Architect
content_type: reference
layout: reference
description: How Sarah enforces zero-trust security, passenger data protection, and aviation governance for Kong Air.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
products:
  - mesh
works_on:
  - on-prem
  - konnect
---

Sarah is the Lead Security Architect at **Kong Air**. In the airline industry, security is not just about data; it's about passenger safety and global regulatory compliance. Sarah uses {{site.mesh_product_name}} to implement a **Zero-Trust** security model that protects passenger PII, the booking gateway, and internal flight control APIs.

## Workload identity with `MeshIdentity`

Sarah's foundation is **`MeshIdentity`**, the resource that issues a unique SPIFFE identity to every workload in the mesh. In practice, the exact SPIFFE ID comes from the `MeshIdentity` template Sarah chooses, and on Kubernetes the best-practice path is the ServiceAccount-based form described in [Manage workload identity and mTLS](/mesh/scenarios/manage-workload-identity-and-mtls/). Downstream policies (mTLS, traffic permission, audit) all hang off that identity. `MeshIdentity` replaces older IP- and tag-based trust models.

For Kong Air, Sarah uses the `Bundled` provider with an external CA from HashiCorp Vault, see [Integrate an external CA](/mesh/scenarios/integrate-an-external-ca/) for the Vault wiring.

## Strict mTLS with `MeshTLS`

Sarah moves away from IP-based firewall rules to a modern, identity-centric model using **MeshTLS**.

- **Strict mTLS**: Sarah enforces `mode: Strict` across the entire airline mesh. Every service must present a valid SPIFFE certificate issued by `MeshIdentity`; plaintext is refused.
- **Modern TLS versions**: Constrained to TLS 1.2 / 1.3 to satisfy aviation compliance audits.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kong-air-core-security
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        mode: Strict
        tlsVersion:
          min: TLS12
          max: TLS13
```

{:.info}
> The older `MeshTLS.spec.from` form is on the deprecation list and emits a warning on apply. Prefer the `rules` shape shown above for new policies.

## Fine-grained authorization

Sarah implements a "Default Deny" policy. No service can communicate with another unless she explicitly authorizes it using **MeshTrafficPermission**.

### Protecting the flight database
Sarah ensures that only `flight-control` can access the sensitive `flight-db`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: protect-flight-db
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: flight-db
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: <flight-control-spiffe-id>
```

This ties authorization to the caller's authenticated SPIFFE identity: the policy attaches to the `flight-db` proxies and allows only the `flight-control` identity.

{:.info}
> Older policies expressed this with a top-level `kind: MeshService` target and a `from[]` block naming another `MeshService`. Both top-level `MeshService` targeting and the `from` shape are on the deprecation list, use the `Dataplane` selector + SPIFFE-id `allow` rule shown above.

Replace `<flight-control-spiffe-id>` with the actual SPIFFE ID emitted by your `MeshIdentity` template. On the Kubernetes best-practice path, that is usually a ServiceAccount-based identity rather than a short `spiffe://<mesh>/<workload>` form.

{:.info}
> To allow communication between broad security zones (e.g., `zone: dmz` to `zone: internal`), Sarah uses a `Dataplane` selector with `labels:` at the top level. Top-level `MeshSubset` / `MeshServiceSubset` are older targeting shapes, see the [Target workloads and services](/mesh/scenarios/target-workloads-and-services/).

## External security and governance

Sarah's security posture extends beyond the mesh boundaries.

### Gateway authentication (JWT)
External requests from passengers enter through `booking-gateway` ({{site.base_gateway}}, operated by Ollie). Sarah configures the gateway to validate passenger JWTs (OpenID Connect) before translating that identity into the mesh.

### Egress control and filtering
When internal services need to fetch weather data from `weather-api` (a SaaS provider), Sarah uses **ZoneEgress** and `MeshExternalService` (defined by Ollie) to strictly control and log these outbound connections.

`MeshExternalService` traffic is **deny-by-default** at the ZoneEgress listener itself, so the policy targets the **zone-proxy `Dataplane`** and matches both the caller's authenticated identity (`spiffeID`) and the destination external service (`sni`). The computed label `kuma.io/listener-zoneegress: enabled` selects ZoneEgress listeners, and `sectionName` narrows the rule to a specific listener when needed.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-weather-api-egress
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
    sectionName: ze-port
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: <check-in-api-spiffe-id>
            sni:
              type: Exact
              value: <generated-weather-api-sni>
```

Replace `<check-in-api-spiffe-id>` with the actual SPIFFE ID emitted by your `MeshIdentity` template, and `<generated-weather-api-sni>` with the SNI for your `MeshExternalService`. In 2.14 the SNI format is `sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>`, see the [Manage external services with MeshExternalService](/mesh/scenarios/manage-external-services-with-meshexternalservice/) for how to derive it.

{:.warning}
> Older `kind: MeshExternalService` targeting is gone in 2.14. Earlier releases allowed a `MeshTrafficPermission` to target the external service directly (top-level `targetRef.kind: MeshExternalService` with a `from[]` block naming the calling `MeshService`). That form is **rejected by the admission webhook in 2.14**. The listener-targeted form above is the only supported model for mesh-scoped ZoneEgress.

## Governance and audit trails

To comply with aviation audits, Sarah must be able to prove who talked to what and when.

- **Immutable Logs**: Sarah uses **MeshAccessLog** (configured by Ollie) to ensure every authorization decision is logged to a tamper-proof backend.
- **Policy Ownership**: Sarah manages security policies in a dedicated `kong-air-sec` namespace, using Kubernetes RBAC to ensure that only her team can modify mTLS or Traffic Permissions, even if Devin's team manages their own routes.

## Sarah's result
By implementing {{site.mesh_product_name}}, Sarah has achieved a higher level of security than traditional perimeter-based models. She has cryptographic proof of every service identity, granular control over every data flow, and a complete audit trail for the entire **Kong Air** digital ecosystem.
