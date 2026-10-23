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
The security architect leads security at Kong Air.
In the airline industry, security covers data, passenger safety, and global regulatory compliance.
The security architect uses {{site.mesh_product_name}} to build a zero-trust model that protects passenger personal data, the booking gateway, and the internal flight control APIs.

## Workload identity and strict mTLS

The security architect's foundation is `MeshIdentity`.
It gives each workload that it selects a Secure Production Identity Framework for Everyone (SPIFFE) identity, carried in an X.509 certificate.
Every other control, such as mTLS, traffic permissions, and audit, depends on that identity.

When a proxy has an identity, it accepts only mTLS connections and rejects plaintext.
The security architect also applies a `MeshTLS` policy across the whole mesh.
The policy sets `mode: Strict` explicitly and limits connections to TLS 1.2 and 1.3, as aviation compliance audits require.

For the configuration, see [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).
To sign the certificates with a CA that Kong Air controls, such as HashiCorp Vault, see [Integrate an external CA](/mesh/integrate-an-external-ca/).

## Fine-grained authorization

Once a proxy has an identity, it denies every caller that no `MeshTrafficPermission` allows.
The security architect builds on this default deny and allows only the calls that each service needs.

### Allow callers by identity

A `MeshTrafficPermission` has two parts:

* The top-level `targetRef` selects the proxies that receive the traffic, for example the proxies labeled `app: check-in-api`.
* The `rules` match the callers by their SPIFFE ID, for example the identity of `flight-control`.

A permission can't match callers by their labels or their zone.
To allow every caller from one zone, the security architect matches the trust domain of that zone with a SPIFFE ID prefix.
See [Create a security policy](/mesh/create-a-security-policy/) and [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/).

### Protect the flight database

Only `flight-control` can access `flight-db`, the Amazon RDS database that stores flight data.
`flight-db` runs outside the mesh, so the operator registers it as a `MeshExternalService`, and every request to it leaves through the zone egress.
The security architect applies a `MeshTrafficPermission` to the zone egress, which matches both the caller's SPIFFE ID and the destination's server name indication (SNI).
See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## Security outside the mesh

The security architect also controls the requests that enter and leave the mesh.

### Gateway authentication and passenger identity

Passenger requests enter through `booking-gateway`, a {{site.base_gateway}} deployment that the operator runs.
The gateway validates each passenger's JWT against Kong Air's OpenID Connect provider.
That check tells the services which passenger is calling.
It doesn't change which workload the mesh sees as the caller.

Kong Air uses two kinds of identity, and the security architect plans for both:

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
    subject: "The calling service, for the lifetime of its Pod."
    travels: "The SPIFFE ID in the X.509 certificate of the mTLS connection."
    enforces: "The sidecars, with the certificates from `MeshIdentity` and the rules of `MeshTrafficPermission`."
  - identity: "Passenger identity"
    subject: "One passenger, for one request."
    travels: "Request headers that the gateway sets after it validates the token."
    enforces: "The gateway, and `MeshOPA` in the receiving sidecar."
{% endtable %}
<!-- vale on -->

`MeshIdentity` issues one certificate per workload, so the SPIFFE ID can't change from request to request.
`MeshTrafficPermission` matches only `spiffeID` and `sni`.
Inside the mesh, every passenger request comes from the same caller, `booking-gateway`.
The passenger identity travels as application data, and the mesh doesn't turn it into a workload identity.

#### Make the passenger headers trustworthy

A header is trustworthy only if nothing else could have set it.
The security architect uses two controls together:

1. The gateway removes any copy of the trusted headers that the client sent, so a passenger can't set their own consumer ID.
1. A `MeshTrafficPermission` on `passenger-portal` allows only the gateway's SPIFFE ID, so no other workload in the mesh can connect and send a forged header.

#### Check the passenger token in the sidecar with MeshOPA

For a service that handles passenger personal data, the security architect moves the token check from the application into the sidecar.
`MeshOPA` runs Open Policy Agent (OPA) inside the {{site.mesh_product_name}} sidecar and uses it for Envoy external authorization.
The Rego policy receives the HTTP request, including the `Authorization` header, and decides before the request reaches the application:

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
          type: InsecureInline
          insecureInline:
            value: |
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

Replace `<your OpenID Connect provider's JWKS>` with the verification keys of the provider that the gateway uses, so the sidecar and the gateway accept the same tokens.
To keep the policy out of the `MeshOPA` resource, store it in a Secret instead. See [MeshOPA](/mesh/policies/meshopa/).

`MeshOPA` gives the security architect three benefits:

* **Defense in depth**: A compromised or faulty service can't skip the passenger check, because the sidecar runs the check before the request reaches the service.
* **One decision point**: The same Rego policy runs for every workload that the policy selects, so teams don't rebuild token validation in their own languages.
* **Audit evidence**: When the security architect turns on OPA decision logs in `agentConfig`, they record each allow and deny. Together with `MeshAccessLog`, they show the workload that connected and the passenger claim that the sidecar accepted.

### Egress control

Internal services fetch weather data from `weather-api`, a SaaS provider.
The operator registers `weather-api` as a `MeshExternalService`, so every request to it leaves through the zone egress.
The zone egress denies `MeshExternalService` traffic by default.
The security architect allows each caller with a `MeshTrafficPermission` on the zone egress, as for `flight-db`.
See [Authorize zone proxy traffic](/mesh/policies/meshtrafficpermission/#authorize-zone-proxy-traffic).

## Governance and audit trails

Aviation audits require Kong Air to prove which service called which other service, and when:

* **Access logs**: The operator's `MeshAccessLog` policies record every request, including the requests that a `MeshTrafficPermission` denied. The security architect sends these logs to a backend that prevents changes to stored logs.
* **Policy ownership**: The security architect creates security policies, such as `MeshTLS` and `MeshTrafficPermission`, on the global control plane or in the system namespace of each zone. Kubernetes RBAC on the system namespace makes sure that only the security team can change them. Application teams still manage their own routes in their own namespaces.

A policy in an application namespace reaches only the proxies in that namespace, so a separate security namespace can't hold zone-wide policies.
See [Policy scope](/mesh/policy-targeting/#policy-scope).

With {{site.mesh_product_name}}, the security architect has a cryptographic identity for every service, controls every data flow, and keeps an audit trail for all of Kong Air.
