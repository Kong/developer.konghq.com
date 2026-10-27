---
title: Security architect
content_type: reference
layout: reference
description: How the security architect controls workload identity, mTLS, authorization, and the mesh perimeter for Kong Air.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "{{site.mesh_product_name}} scenarios"
    url: /mesh/scenarios/
  - text: Developer
    url: /mesh/scenarios/persona/developer/
  - text: Operator
    url: /mesh/scenarios/persona/operator/
  - text: Create a security policy
    url: /mesh/create-a-security-policy/
  - text: Manage workload identity and mTLS
    url: /mesh/manage-workload-identity-and-mtls/
  - text: Integrate an external CA
    url: /mesh/integrate-an-external-ca/
  - text: Send traffic between zones
    url: /mesh/send-traffic-between-zones/
  - text: Secure the perimeter with MeshPassthrough
    url: /mesh/secure-the-perimeter-with-meshpassthrough/
  - text: Manage external services with MeshExternalService
    url: /mesh/manage-external-services-with-meshexternalservice/
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: Resource scoping
    url: /mesh/resource-scoping/
---
The security architect leads security at Kong Air.
In the airline industry, security covers passenger data, safety, and regulatory compliance.
The security architect uses {{site.mesh_product_name}} to build a zero-trust model: every workload has a verified identity, every connection is encrypted, and every call is explicitly allowed.

## Workload identity and strict mTLS

The security architect's foundation is `MeshIdentity`.
It gives each workload that it selects a Secure Production Identity Framework for Everyone (SPIFFE) identity, carried in an X.509 certificate.
Every other control depends on that identity.

When a proxy has an identity, it accepts only mTLS connections and denies every caller that no `MeshTrafficPermission` allows.
Kong Air's compliance rules require mTLS on every connection, so the security architect also applies a mesh-wide `MeshTLS` policy that sets `mode: Strict` explicitly instead of relying on the default.
See [Create a security policy](/mesh/create-a-security-policy/).

## Fine-grained authorization

The security architect builds on the default deny and allows only the calls that each service needs.

### Allow callers by identity

A `MeshTrafficPermission` has two parts:

* The top-level `targetRef` selects the proxies that receive the traffic, for example the proxies labeled `app: check-in-api`.
* The `rules` match the callers by their SPIFFE ID, for example the identity of `flight-control`.

A permission can't match callers by their labels.
The SPIFFE ID contains the trust domain, the namespace, and the service account, so each Kong Air workload runs as its own Kubernetes `ServiceAccount` to get its own identity.
See [Create a security policy](/mesh/create-a-security-policy/) and [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/).

### Allow callers from another zone

`passenger-portal` in `zone1` calls `baggage-api` in `zone2`.
The zone ingress of `zone2` doesn't decrypt the connection, so the `baggage-api` sidecar sees the `zone1` SPIFFE ID of `passenger-portal`, and the permission in `zone2` allows that identity.
See [Send traffic between zones](/mesh/send-traffic-between-zones/).

### Control access to external services

`flight-db` and AeroPay run outside the mesh, so every request to them leaves through the zone egress, which denies `MeshExternalService` traffic by default.
The security architect applies a `MeshTrafficPermission` to the zone egress for each dependency, which matches both the caller's SPIFFE ID and the destination's server name indication (SNI).
Only `flight-control` reaches `flight-db`, and only `passenger-portal` reaches AeroPay.
See [Manage external services with MeshExternalService](/mesh/manage-external-services-with-meshexternalservice/).

## Trust across zones and external CAs

### Trust across zones

With the `Bundled` provider, each zone generates its own certificate authority (CA) and trust domain, and doesn't trust the certificates of the other zone.
The security architect copies the `MeshTrust` of each zone into the other zone, so proxies in each zone accept the certificates of both.
See [Manage workload identity and mTLS](/mesh/manage-workload-identity-and-mtls/).

### External CA

Kong Air already runs a corporate public key infrastructure (PKI).
The security architect moves `flight-control` to a `MeshIdentity` with the `certmanager` extension provider, so cert-manager signs its certificates and the CA private key never leaves cert-manager.
The new identity uses its own trust domain, so the security architect updates every `MeshTrafficPermission` that matches the old SPIFFE ID before the switch.
See [Integrate an external CA](/mesh/integrate-an-external-ca/).

## Perimeter control

Kong Air's control planes start with open outbound access, so a sidecar can reach any external destination.
The security architect closes the perimeter with a `MeshPassthrough` policy, then allows only the external destinations that Kong Air needs.
See [Secure the perimeter with MeshPassthrough](/mesh/secure-the-perimeter-with-meshpassthrough/).

## Audit trails

Audits require Kong Air to prove which service called which other service, and when:

* Access logs: The [operator](/mesh/scenarios/persona/operator/)'s `MeshAccessLog` policies record every request, including the requests that a `MeshTrafficPermission` denied. See [Observe mesh traffic in practice](/mesh/observe-mesh-traffic-in-practice/).
* Policy ownership: The security architect creates mesh-wide security policies, such as `MeshIdentity` and `MeshTLS`, in the system namespace. Kubernetes RBAC on the system namespace makes sure that only the security team can change them. A policy in an application namespace reaches only the proxies in that namespace. See [Policy scope](/mesh/policy-targeting/#policy-scope).

With {{site.mesh_product_name}}, the security architect has a cryptographic identity for every service, controls every data flow, and keeps an audit trail for all of Kong Air.
