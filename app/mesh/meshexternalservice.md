---
title: MeshExternalService
description: Reach a service outside the mesh as a first-class destination through the zone egress, which can originate TLS to it.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - service-mesh
  - traffic-control
related_resources:
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: MeshService
    url: /mesh/meshservice/
  - text: MeshPassthrough policy
    url: /mesh/policies/meshpassthrough/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
---

`MeshExternalService` makes a destination outside the mesh into a resource the mesh understands.
A policy can name it in `spec.to[].targetRef`, a route can send traffic to it in `backendRefs`,
and the mesh can originate TLS to it, so an external API or database is governed by the same
timeouts, retries and circuit breakers as anything inside the mesh.

`MeshExternalService` replaces the legacy `ExternalService` resource, which is removed in 3.0.

The resource isn't a policy: there is no `targetRef`, because it *is* the destination. On
Kubernetes, it's accepted only in the system namespace.

Traffic to a `MeshExternalService` always goes through a [mesh-scoped zone egress](/mesh/mesh-scoped-zone-proxies/)
in the client's zone. The client's sidecar sends the request to the egress over mesh mTLS, and
the egress connects to the endpoints. This path requires the following:

* A zone egress for the mesh in the client's zone, selected by an initialized `MeshIdentity`.
  Without one, the destination has no endpoints.
* A `MeshIdentity` that selects the client proxies. A client without an identity gets no route
  to the destination, and the request fails locally with a 503.
* A [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) on the egress that allows the
  caller. The egress denies a request when no allow rule matches.
* The `MeshExternalService` in the client's `reachableBackends` (the `kuma.io/reachable-backends`
  annotation on Kubernetes). A proxy gets no outbound for a destination it doesn't list.

## Reach an external API over TLS

{% policy_yaml %}
```yaml
type: MeshExternalService
mesh: default
name: external-api
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: api.example.com
      port: 443
  tls:
    enabled: true
    version:
      min: TLS12
    verification:
      mode: Secured
      serverName: api.example.com
```
{% endpolicy_yaml %}

## MeshExternalService and MeshPassthrough

Both deal with traffic leaving the mesh, and they aren't alternatives.

[MeshPassthrough](/mesh/policies/meshpassthrough/) lets a proxy reach an address the mesh knows
nothing about, without giving it a name. Nothing can target that traffic: no policy applies to
it, and the mesh doesn't originate TLS.

A `MeshExternalService` gives the destination an identity in the mesh, a VIP and a hostname, so
policies and routes can name it. Use it for the dependencies that matter enough to govern, and
`MeshPassthrough` for everything else.

## Traffic matching

`spec.match` describes the traffic that should be routed through this resource.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`type`"
    value: "`HostnameGenerator`, the only value and the default. A hostname is generated for the service and the VIP answers on it."
  - field: "`port`"
    value: "The port a client dials, 1 to 65535."
  - field: "`protocol`"
    value: "`tcp`, the default, or `http`, `http2`, `grpc`. Anything else is rejected."
{% endtable %}

`protocol` decides which policies can apply. An HTTP-based value is what lets
[MeshHTTPRoute](/mesh/policies/meshhttproute/) and the L7 parts of `MeshTimeout` and
`MeshRetry` reach this destination.

There is no `tls` protocol value here. Where the zone egress should originate TLS, set
`protocol` to what the application speaks and turn on `spec.tls`; see [Originating TLS](#originating-tls).

## Endpoints

`spec.endpoints[]` is where the traffic actually goes. Each takes an `address` (an IP or a
hostname) and a `port`.

`priority` enables failover: lower wins, 0 is primary, and traffic moves to the next level when
the endpoints above it are unhealthy.

```yaml
endpoints:
  - address: api.example.com
    port: 443
    priority: 0
  - address: api-dr.example.com
    port: 443
    priority: 1
```

An address that is neither an IP nor a hostname is rejected with
`address has to be a valid IP or hostname`.

## Originating TLS

`spec.tls.enabled` makes the zone egress originate TLS to the endpoints, which is what lets an
application speak plaintext to a destination that requires TLS. The client's sidecar sends the
request to the egress over mesh mTLS.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`version.min` / `version.max`"
    value: "Bound the negotiated version, from `TLS10` to `TLS13`, or `TLSAuto` to leave that end to Envoy."
  - field: "`allowRenegotiation`"
    value: "Permit TLS renegotiation. Off by default, and best left off."
  - field: "`verification.mode`"
    value: "`Secured`, the default, verifies both the CA and the SAN. `SkipSAN`, `SkipCA` and `SkipAll` each drop part or all of that."
  - field: "`verification.serverName`"
    value: "Overrides the SNI the egress sends. Must be a valid DNS name. Defaults to the first endpoint's address when it is a hostname."
  - field: "`verification.subjectAltNames`"
    value: "Names to verify in the certificate, each `Exact` or `Prefix`."
  - field: "`verification.caCert`"
    value: "The CA to verify the endpoint against, as a secure data source."
  - field: "`verification.clientCert` / `clientKey`"
    value: "A client certificate and key for mutual TLS to the endpoint. Each requires the other."
{% endtable %}

Defining `clientCert` without `clientKey` is rejected with
`must be defined when clientCert is defined`, and the reverse likewise.

The three data source fields accept `type: Secret` or `type: InsecureInline` only. `File` and
`EnvVar` are rejected because they would make the control plane read its own filesystem and
environment. This applies even when `spec.extension` is set.

{:.warning}
> `verification.mode` is the field to be deliberate about. `SkipAll` and `SkipCA` mean the
> egress accepts any certificate the endpoint presents, which removes the guarantee that
> TLS was there to provide. `SkipSAN` still checks that the certificate chains to a trusted CA.

## Status

`status.vip.ip` is the address the generated hostname resolves to, and `status.addresses` lists
the hostnames themselves with the generator that produced each. `status.hostnameGenerators`
carries per-generator status, which is where to look when an expected hostname wasn't produced.

## Extensions

`spec.extension` hands configuration to a named extension, and in its presence `endpoints` and
`tls` are no longer required: the extension validates its own configuration instead. An
extension with an empty `type` is rejected.

## Schema

{% json_schema MeshExternalServices %}
