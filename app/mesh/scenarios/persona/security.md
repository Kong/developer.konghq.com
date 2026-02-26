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

Sarah is the Lead Security Architect at **Kong Air**. In the airline industry, security is not just about data; it's about passenger safety and global regulatory compliance. Sarah uses {{site.mesh_product_name}} to implement a **Zero-Trust** security model that protects frequent flyer data, payment systems, and internal flight control APIs.

## 1. Modern Identity Deep-Dive

Sarah moves away from insecure, IP-based firewall rules to a modern, identity-centric model using **MeshTLS**.

- **Strict mTLS**: Sarah enforces `mode: Strict` across the entire airline mesh. This ensures all traffic is encrypted and that every service (from the booking engine to the galley inventory) must present a valid, mesh-issued certificate.
- **Automated Rotation**: Sarah configures the mesh to rotate certificates every 24 hours, minimizing the impact of a potential credential compromise.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kong-air-core-security
  namespace: kong-air-sec
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

## 2. Fine-Grained Authorization

Sarah implements a "Default Deny" policy. No service can communicate with another unless she explicitly authorizes it using **MeshTrafficPermission**.

### Protecting the Frequent Flyer Database
Sarah ensures that only the `ticket-booking` service can access the sensitive `frequent-flyer-db`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: protect-frequent-flyer-data
  namespace: kong-air-sec
spec:
  targetRef:
    kind: MeshService
    name: frequent-flyer-db
  from:
    - targetRef:
        kind: MeshService
        name: ticket-booking
      default:
        action: Allow
```

{% tip %}
Sarah uses **`MeshSubset`** to allow communication between broad security zones (e.g., `zone: dmz` to `zone: internal`). See the [Subsets & Targeting Guide](/mesh/scenarios/subsets-and-targeting/) for details on cross-cutting targeting.
{% endtip %}

## 3. External Security & Governance

Sarah's security posture extends beyond the mesh boundaries.

### Gateway Authentication (JWT)
External requests from the Kong Air mobile app enter through **Kong Gateway**. Sarah configures the gateway to validate passenger JWTs (OpenID Connect) before translating that identity into the mesh.

### Egress Control and Filtering
When internal services need to fetch weather data from a third-party provider, Sarah uses **ZoneEgress** and `MeshExternalService` to strictly control and log these outbound connections.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-weather-api-egress
  namespace: kong-air-sec
spec:
  targetRef:
    kind: MeshService
    name: global-weather-provider
  from:
    - targetRef:
        kind: MeshService
        name: flight-planning-svc
      default:
        action: Allow
```

{% tip %}
The traffic permission above controls which services can _reach_ `global-weather-provider`. Combined with a `MeshExternalService` definition and `ZoneEgress`, this ensures only `flight-planning-svc` is allowed to traverse the egress to the external weather API.
{% endtip %}

## 4. Governance & Audit Trails

To comply with aviation audits, Sarah must be able to prove who talked to what and when.

- **Immutable Logs**: Sarah uses **MeshAccessLog** (configured by Ollie) to ensure every authorization decision is logged to a tamper-proof backend.
- **Policy Ownership**: Sarah manages security policies in a dedicated `kong-air-sec` namespace, using Kubernetes RBAC to ensure that only her team can modify mTLS or Traffic Permissions, even if Devin's team manages their own routes.

## Sarah's Result
By implementing {{site.mesh_product_name}}, Sarah has achieved a higher level of security than traditional perimeter-based models. She has cryptographic proof of every service identity, granular control over every data flow, and a complete audit trail for the entire **Kong Air** digital ecosystem.
