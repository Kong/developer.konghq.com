---
title: "Persona: Sarah the Security Architect"
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/scenarios/persona/
description: A deep-dive into how Sarah enforces zero-trust security, passenger data protection, and aviation governance for Kong Air.
products:
  - mesh
---

Sarah is the Lead Security Architect at **Kong Air**. In the airline industry, security is not just about data; it's about passenger safety and global regulatory compliance. Sarah uses {{site.mesh_product_name}} to implement a **Zero-Trust** security model that protects passenger PII, the booking gateway, and internal flight control APIs.

## 1. Workload identity with `MeshIdentity`

Sarah's foundation is **`MeshIdentity`** — the resource that issues a unique SPIFFE identity to every workload in the mesh. Each service runs as `spiffe://kong-air-mesh/<workload-name>`, and downstream policies (mTLS, traffic permission, audit) all hang off that identity. `MeshIdentity` replaces older IP- and tag-based trust models. See [Workload Identity & Trust](/mesh/scenarios/workload-identity/) for the full setup.

For Kong Air, Sarah uses the `Bundled` provider with an external CA from HashiCorp Vault — see [External CA & Vault Integration](/mesh/scenarios/external-ca-vault/) for the Vault wiring.

## 2. Strict mTLS with `MeshTLS`

Sarah moves away from IP-based firewall rules to a modern, identity-centric model using **MeshTLS**.

- **Strict mTLS**: Sarah enforces `mode: Strict` across the entire airline mesh. Every service must present a valid SPIFFE certificate issued by `MeshIdentity`; plaintext is refused.
- **Modern TLS versions**: Constrained to TLS 1.2 / 1.3 to satisfy aviation compliance audits.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kong-air-core-security
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        mode: Strict
        tlsVersion:
          min: TLS12
          max: TLS13
```

{% tip %}
**Recommended for 2.14+ — use `rules` instead of `from`.** `MeshTLS.spec.from` is on the deprecation list and emits a warning on apply. The same policy in the `rules` shape:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kong-air-core-security
  namespace: {{site.mesh_system_namespace}}
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
{% endtip %}

## 3. Fine-Grained Authorization

Sarah implements a "Default Deny" policy. No service can communicate with another unless she explicitly authorizes it using **MeshTrafficPermission**.

### Protecting the flight database
Sarah ensures that only `flight-control` can access the sensitive `flight-db`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: protect-flight-db
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: MeshService
    name: flight-db
  from:
    - targetRef:
        kind: MeshService
        name: flight-control
      default:
        action: Allow
```

{% tip %}
**Recommended for 2.14+ — `Dataplane` selector + SPIFFE-id allow rule.** Top-level `kind: MeshService` and `from`-style `MeshService` references are both on the deprecation list. The modern policy ties authorization to the caller's authenticated SPIFFE identity:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: protect-flight-db
  namespace: {{site.mesh_system_namespace}}
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
              value: spiffe://kong-air-mesh/flight-control
```
{% endtip %}

{% tip %}
To allow communication between broad security zones (e.g., `zone: dmz` to `zone: internal`), Sarah uses a `Dataplane` selector with `labels:` at the top level. Top-level `MeshSubset` / `MeshServiceSubset` are deprecated — see the [Targeting Guide](/mesh/scenarios/subsets-and-targeting/).
{% endtip %}

## 4. External Security & Governance

Sarah's security posture extends beyond the mesh boundaries.

### Gateway Authentication (JWT)
External requests from passengers enter through `booking-gateway` ({{site.base_gateway}}, operated by Ollie). Sarah configures the gateway to validate passenger JWTs (OpenID Connect) before translating that identity into the mesh.

### Egress Control and Filtering
When internal services need to fetch weather data from `weather-api` (a SaaS provider), Sarah uses **ZoneEgress** and `MeshExternalService` (defined by Ollie) to strictly control and log these outbound connections.

The legacy form below shows the older sidecar-oriented permission shape. It still works with current Kuma releases, but it does **not** reflect the new mesh-scoped ZoneEgress listener model introduced in 2.14.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-weather-api-egress
  namespace: {{site.mesh_system_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: MeshExternalService
    name: weather-api
  from:
    - targetRef:
        kind: MeshService
        name: check-in-api
      default:
        action: Allow
```

{% tip %}
**Recommended for 2.14+ — target the ZoneEgress listener directly.** With the new mesh-scoped ZoneEgress in 2.14, `MeshExternalService` traffic is **deny-by-default** at the ZoneEgress listener itself. The modern policy therefore targets the **zone-proxy `Dataplane`** and matches both:

- the caller's authenticated identity (`spiffeID`)
- the destination external service (`sni`)

The computed label `kuma.io/listener-zoneegress: enabled` selects ZoneEgress listeners, and `sectionName` narrows the rule to the specific listener when needed.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-weather-api-egress
  namespace: {{site.mesh_system_namespace}}
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
              value: spiffe://kong-air-mesh/check-in-api
            sni:
              type: Exact
              value: <generated-weather-api-sni>
```

Replace `<generated-weather-api-sni>` with the actual SNI for your `MeshExternalService`. In 2.14 the format is derived from the external-service identity and looks like `sni.extsvc.<mesh>...`; the exact segments depend on whether the resource is global- or zone-originated. If Sarah wants a sidecar-level policy instead, she can still target the client workload or the `MeshExternalService`. But for the new mesh-scoped ZoneEgress model, this listener-targeted form is the one that matches the 2.14 data path and deny-by-default behavior.
{% endtip %}

## 5. Governance & Audit Trails

To comply with aviation audits, Sarah must be able to prove who talked to what and when.

- **Immutable Logs**: Sarah uses **MeshAccessLog** (configured by Ollie) to ensure every authorization decision is logged to a tamper-proof backend.
- **Policy Ownership**: Sarah manages security policies in a dedicated `kong-air-sec` namespace, using Kubernetes RBAC to ensure that only her team can modify mTLS or Traffic Permissions, even if Devin's team manages their own routes.

## Sarah's Result
By implementing {{site.mesh_product_name}}, Sarah has achieved a higher level of security than traditional perimeter-based models. She has cryptographic proof of every service identity, granular control over every data flow, and a complete audit trail for the entire **Kong Air** digital ecosystem.
