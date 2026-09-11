---
title: Mesh Traffic Permission
name: MeshTrafficPermissions
products:
- mesh
description: Control which clients can reach a service, based on workload identity.
content_type: plugin
type: policy
icon: meshtrafficpermission.png
tags:
- access-control
- authorization
- security
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtrafficpermission"
- text: MeshIdentity policy
  url: "/mesh/policies/meshidentity/"
- text: Migrate mesh mTLS to MeshIdentity
  url: "/mesh/migrate-mtls-to-meshidentity/"
- text: Issue identity with the MeshIdentity bundled provider
  url: "/mesh/issue-identity-with-meshidentity/"
---

`MeshTrafficPermission` is inbound authorization for the mesh. It answers two questions:

1. Which destination workload enforces the policy?
1. Which authenticated client identities may connect to it?

`spec.targetRef` selects the destination. `spec.rules` evaluates the SPIFFE ID presented by the
calling workload. Client addresses and data plane tags are not part of the authorization
decision.

{:.warning}
> `MeshTrafficPermission` is enforced only on mTLS listeners for workloads selected by
> [MeshIdentity](/mesh/policies/meshidentity/). A workload with no identity has no mTLS listener
> for this policy to protect. Define the required permissions before, or at the same time as,
> activating `MeshIdentity`. A plaintext connection accepted by a permissive `MeshTLS` listener
> presents no workload identity and is not authorized by `MeshTrafficPermission`.

Once a workload has an identity, authorization is default-deny. A client must match an `allow`
or `allowWithShadowDeny` entry in a policy that applies to the destination. Otherwise, the
connection is denied.

## Allow a namespace to reach one workload

This policy allows every identity in the `storefront` namespace to connect to workloads labeled
`app: orders`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: allow-storefront-to-orders
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: orders
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/storefront/
```
{% endpolicy_yaml %}

Read the policy from the destination back to the caller:

- `targetRef` selects the `orders` data plane proxies that enforce the policy.
- `rules[].default.allow` contains the client identities those proxies accept.
- `Prefix` groups all service accounts under the `storefront` namespace.
- Every other client is denied unless another applicable policy allows it.

There is no `to` array. Access control is enforced inbound at the destination.

## How authorization is evaluated

For each request, the proxy walks the matchers in a fixed order:

1. A request matching any `deny` matcher is **denied**.
1. Otherwise, a request matching any `allow` or `allowWithShadowDeny` matcher is **allowed**.
1. A request matching nothing is **denied**.

Every `deny` across every policy that applies to the proxy is evaluated before any `allow`,
so a `deny` cannot be overridden by a later or narrower `allow`. A service owner cannot grant
access that a mesh-wide `deny` has withdrawn.

{:.warning}
> **Do not write a mesh-wide deny-all and then allow services back in.** That pattern comes
> from {{site.mesh_product_name}} 2.x, where the last matching rule won, and it does not
> work here: a blanket `deny` matches every client and no later `allow` can re-open it.
>
> A mesh is already closed. With no `MeshTrafficPermission` in place, nothing is allowed, so
> write only the `allow` rules for the traffic you want.

## Exclude clients from a broader allow

A `deny` is useful as an exception to an `allow`. In this example, the destination accepts
clients from the trust domain except for the `legacy` namespace and one service account:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: trust-domain-with-exceptions
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: orders
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/legacy/
          - spiffeID:
              type: Exact
              value: spiffe://default.default.mesh.local/ns/storefront/sa/retired-client
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/
```
{% endpolicy_yaml %}

The two `deny` entries are evaluated first. The broader `allow` then admits every other client
from the trust domain. A policy containing only the `deny` entries would not open access for
anyone; unmatched traffic is already denied.

## Match on identity or SNI

A matcher selects clients by one of two fields.

{% table %}
columns:
  - title: Field
    key: field
  - title: Matches on
    key: matches
  - title: "`type`"
    key: type
rows:
  - field: "`spiffeID`"
    matches: "The SPIFFE ID of the calling workload, issued by `MeshIdentity`."
    type: "`Exact` or `Prefix`"
  - field: "`sni`"
    matches: "The SNI carried on the TLS connection. Used on zone egress, where the destination is identified by SNI rather than by client identity."
    type: "`Exact` only"
{% endtable %}

`spiffeID` is the matcher for service-to-service access, since it names the client.
`sni` accepts only `Exact`, and its value has to be a DNS subdomain.

`Prefix` is how you address a group. A Kubernetes SPIFFE ID is structured as
`spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`, so a prefix ending after the
namespace selects every workload in it:

```yaml
- spiffeID:
    type: Prefix
    value: spiffe://default.default.mesh.local/ns/observability/
```

Prefix matching compares the literal string; it does not understand SPIFFE ID path segments.
Keep the trailing `/` when matching a namespace. Without it, a prefix ending in
`/ns/observability` also matches a namespace such as `observability-test`.

In a SPIFFE ID, the trust domain is the text after `spiffe://` and before the next `/`. In the
example above, it is `default.default.mesh.local`.

Replace that example value with the domain used by your client identities. The exact value is
in `MeshIdentity.status.trustDomain`, and the corresponding
[`MeshTrust`](/mesh/policies/meshtrust/) repeats it in `spec.trustDomain`. For example, if
`spec.trustDomain` is `payments.eu.mesh.local`, a namespace matcher starts with:

```yaml
value: spiffe://payments.eu.mesh.local/ns/observability/
```

Do not copy `default.default.mesh.local` unless that is the value shown in your resources.

## Observe a deny before enforcing it

`allowWithShadowDeny` allows a matching client but also records a shadow-deny decision. Combine
it with the allow rule the destination already uses to observe the effect of moving one group
into `deny`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: shadow-deny-legacy
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        allowWithShadowDeny:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/legacy/
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/
```
{% endpolicy_yaml %}

Requests from `legacy` still succeed because `allowWithShadowDeny` is also an allow. Review the
Envoy RBAC shadow decisions in your configured access logs and metrics. When the observed
traffic is safe to block, move the matcher from `allowWithShadowDeny` to `deny` and leave the
broader `allow` in place.

## Scope authorization to destinations

`targetRef` controls where the authorization rules are enforced:

| Target | Effect |
| --- | --- |
| `kind: Mesh` | Enforce the rules on every identified workload in the mesh. |
| `kind: Dataplane` with `labels` | Enforce the rules only on matching destination proxies. |
| `kind: Dataplane` with `labels` and `sectionName` | Enforce the rules only on one named inbound of those proxies. |

Omitting `targetRef` has the same effect as `kind: Mesh`.

### Narrow authorization to one port

`targetRef.sectionName` applies the rules to a single named inbound of the selected proxy,
leaving its other ports alone. This is how a mesh-wide allow rule gets overridden on one
admin port:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTrafficPermission
name: deny-observability-ns
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
    sectionName: backend-admin-api
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local/ns/observability/
```
{% endpolicy_yaml %}

### Authorize zone proxy traffic

`MeshTrafficPermission` applies to a mesh-scoped zone proxy like any other `Dataplane`.
Select the proxy role and zone with `targetRef.labels`, and the listener with
`targetRef.sectionName`.

`sectionName` matches the listener's `name` in
`Dataplane.networking.listeners[]`. A listener with no `name` set takes its port number as
its name, so on a Helm install with default ports that means `10001` for zone ingress and
`10002` for zone egress. Read the listener names from the `Dataplane` rather than assuming
the defaults:

```sh
kubectl get dataplane <zone-proxy> -n kong-mesh-system -o jsonpath='{.spec.networking.listeners}'
```

On zone egress, the destination is matched by SNI:

{% policy_yaml namespace=kong-mesh-system %}
```yaml
type: MeshTrafficPermission
name: deny-external-service-kube
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/listener-zoneegress: enabled
      kuma.io/zone: zone-1
    sectionName: "10002"
  rules:
    - default:
        deny:
          - sni:
              type: Exact
              value: sni.extsvc.default.zone-1.kong-mesh-system.external-service-kube.80
```
{% endpolicy_yaml %}

This `deny` is an exception to any applicable `allow` entries. It does not allow other
destinations by itself; unmatched traffic remains denied.

For a walkthrough, see [Apply policies to mesh-scoped zone proxies](/mesh/zone-proxy-policies/).

## Validate the authorization outcome

Validate the outcome from both sides of the boundary:

1. Confirm that `targetRef` selects the intended destination proxy and, when set, the intended
   `sectionName`.
1. Read the client's issued SPIFFE ID and compare the complete value with the `Exact` or
   `Prefix` matcher. Do not infer it from workload labels.
1. Send a request from a client that should be allowed and confirm that it reaches the
   destination.
1. Send the same request from a client that should not match and confirm that it is denied.
1. Where `allowWithShadowDeny` is present, confirm that traffic succeeds and that the shadow
   decision appears in the configured RBAC telemetry.
1. Confirm that every protected destination has a `MeshIdentity`. A successful plaintext
   request does not prove that `MeshTrafficPermission` allowed it.

For more detail about destination selectors and inbound policy matching, see
[How policies select traffic](/mesh/policy-targeting/).
