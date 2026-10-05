---
title: Security architect
content_type: reference
layout: reference
description: How the security architect enforces zero-trust security, passenger data protection, and aviation governance for Kong Air.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
  - /mesh/persona/
products:
  - mesh
works_on:
  - on-prem
  - konnect
---

The security architect is the Lead Security Architect at Kong Air. In the airline industry, security is not just about data; it's about passenger safety and global regulatory compliance. The security architect uses {{site.mesh_product_name}} to implement a Zero-Trust security model that protects passenger PII, the booking gateway, and internal flight control APIs.

## Workload identity and strict mTLS

The security architect's foundation is `MeshIdentity`, which issues a unique SPIFFE identity to every workload in the mesh. Every downstream control (mTLS, traffic permission, audit) hangs off that identity. On top of it the security architect enforces `MeshTLS` in `mode: Strict` across the entire airline mesh, so every service must present a valid SPIFFE certificate issued by `MeshIdentity` and plaintext is refused, with negotiation constrained to TLS 1.2 / 1.3 for aviation compliance audits.

See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/) for the `MeshIdentity` and `MeshTLS` configuration, and [Integrate an external CA](/mesh/integrate-an-external-ca/) for the HashiCorp Vault wiring behind the security architect's `Bundled` provider.

## Fine-grained authorization

The security architect implements a "Default Deny" policy. No service can communicate with another unless the security architect explicitly authorizes it using MeshTrafficPermission.

### Protecting the flight database
The security architect ensures that only `flight-control` can access the sensitive `flight-db`.

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
> A top-level `targetRef` accepts only `Mesh` or `Dataplane`, and `MeshTrafficPermission` expresses authorization through `rules[]` with `allow`, `deny`, or `allowWithShadowDeny`. The `Dataplane` selector plus a SPIFFE-id `allow` rule is the shape shown here.

Replace `<flight-control-spiffe-id>` with the actual SPIFFE ID emitted by your `MeshIdentity` template. On the Kubernetes best-practice path, that is usually a ServiceAccount-based identity rather than a short `spiffe://<mesh>/<workload>` form.

{:.info}
> To allow communication between broad security zones (for example, `zone: dmz` to `zone: internal`), the security architect uses a `Dataplane` selector with `labels:` at the top level. See [Target workloads and services](/mesh/target-workloads-and-services/).

## External security and governance

The security architect's security posture extends beyond the mesh boundaries.

### Gateway authentication and end-user identity
External passenger requests enter through `booking-gateway` ({{site.base_gateway}}, operated by the operator), which validates passenger JWTs against Kong Air's OpenID Connect provider. That check establishes which passenger is calling. It does not change which workload the mesh sees calling.

Kong Air runs two identity planes, and the security architect has to reason about both:

<!-- vale off -->
{% table %}
columns:
  - title: Identity
    key: identity
  - title: What it identifies
    key: subject
  - title: How it travels
    key: travels
  - title: What enforces it
    key: enforces
rows:
  - identity: "Workload identity"
    subject: "The calling service, for the lifetime of its pod."
    travels: "The SPIFFE ID in the X.509 certificate presented on the mTLS connection."
    enforces: "`MeshTLS` and `MeshTrafficPermission`."
  - identity: "End-user identity"
    subject: "One passenger, for one request."
    travels: "Request headers the gateway sets after it validates the token."
    enforces: "The gateway, and `MeshOPA` at the receiving sidecar."
{% endtable %}
<!-- vale on -->

`MeshIdentity` issues certificates to workloads, attested from the pod and its ServiceAccount, so a SPIFFE ID cannot vary per request. `MeshTrafficPermission` matches on `spiffeID` and `sni`, and on nothing else. Once a request crosses into the mesh, every passenger is the same caller: `booking-gateway`. The passenger identity continues as application-layer data, and the mesh does not convert it into a mesh identity.

#### Make the propagated claim trustworthy

A header is worth only as much as the guarantee that nothing else could have set it. Two controls supply that guarantee together:

1. The gateway strips any client-supplied copy of the trusted headers on ingress, so a passenger cannot assert their own consumer ID.
1. A `MeshTrafficPermission` on `passenger-portal` allows only the gateway's SPIFFE ID, so no other workload in the mesh can connect directly and inject a forged header.

#### Enforce the claim in the sidecar with MeshOPA

For a service handling passenger PII, the security architect can stop relying on the application to honor the claim and move the decision into the proxy. `MeshOPA` runs Envoy external authorization against Open Policy Agent, with the agent built into the {{site.mesh_product_name}} sidecar rather than deployed separately. The Rego policy receives the HTTP request, including the `Authorization` header, and returns a decision before the application is reached:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: passenger-token-check
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  default:
    appendPolicies:
      - rego:
          inlineString: |
            package envoy.authz

            import input.attributes.request.http as http_request

            jwks := "<your OpenID Connect provider's JWKS>"

            default allow = false

            token = {"valid": valid, "payload": payload} {
                [_, encoded] := split(http_request.headers.authorization, " ")
                [valid, _, payload] := io.jwt.decode_verify(encoded, {"cert": jwks})
            }

            allow {
                token.valid
                token.payload.aud == "kong-air-booking"
            }
```

Replace `<your OpenID Connect provider's JWKS>` with the verification material for the provider the gateway already trusts, so the sidecar and the gateway accept the same tokens.

Three things this gives the security architect:

*   Defense in depth. A compromised or buggy service cannot skip the passenger check, because the check runs before the request reaches it.
*   One decision point. The same Rego runs for every workload the policy targets, so each team does not have to rebuild claim validation in its own language.
*   Audit evidence. OPA decision logs record each allow and deny, which pairs with `MeshAccessLog` to show both the workload that connected and the passenger claim that was accepted.


### Egress control and filtering
When internal services need to fetch weather data from `weather-api` (a SaaS provider), the security architect uses the zone egress listeners and `MeshExternalService` (defined by the operator) to strictly control and log these outbound connections.

`MeshExternalService` traffic is deny-by-default at the zone egress listener itself, so the security architect's `MeshTrafficPermission` targets the zone-proxy `Dataplane` (the computed label `kuma.io/listener-zoneegress: enabled`, narrowed with `sectionName`) and its `allow` rule matches both the caller's authenticated identity (`spiffeID`) and the destination external service (`sni`). The SNI format is `sni.extsvc.<mesh>.<zone>.<namespace>.<name>.<port>`. See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/) for the full egress `MeshTrafficPermission` and how to derive the SNI.

## Governance and audit trails

To comply with aviation audits, the security architect must be able to prove who talked to what and when.

- Immutable Logs: The security architect uses MeshAccessLog (configured by the operator) to ensure every authorization decision is logged to a tamper-proof backend.
- Policy Ownership: The security architect manages security policies in a dedicated `kong-air-sec` namespace, using Kubernetes RBAC to ensure that only the security team can modify mTLS or Traffic Permissions, even if the developer's team manages their own routes.

## The security architect's result
By implementing {{site.mesh_product_name}}, the security architect has achieved a higher level of security than traditional perimeter-based models. The security architect has cryptographic proof of every service identity, granular control over every data flow, and a complete audit trail for the entire Kong Air digital ecosystem.
