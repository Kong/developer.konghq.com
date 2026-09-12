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
---

`MeshTrafficPermission` controls which workloads can connect to a destination workload.
The destination's proxy checks the caller's identity against the policy's allow and deny rules.

`spec.targetRef` selects the destination proxies that enforce the policy. The entries under
`spec.rules[].default` identify the callers to allow or deny. For workload-to-workload traffic,
the caller is identified by its SPIFFE ID: a URI carried in its mTLS certificate. Client IP
addresses and client data plane tags do not determine access.

## Before you configure permissions

[MeshIdentity](/mesh/policies/meshidentity/) gives workloads their identities and certificates.
Both the caller and destination need identities for an mTLS connection. Define the required
permissions before, or at the same time as, enabling identity on the destination.

Authorization on these mTLS connections is default-deny. If no applicable permission allows
the caller, the destination proxy denies access. You do not need a deny-all policy.

These rules apply only to mTLS connections. A destination without a workload identity has no
mTLS listener for this policy to protect. If [MeshTLS](/mesh/policies/meshtls/) permits plaintext
connections, those connections bypass `MeshTrafficPermission` checks. Use `Strict` mode when
the destination must accept only authenticated, authorized traffic.

## Allow a namespace to reach one workload

This example allows callers in the `storefront` namespace to reach destination proxies labeled
`app: orders`. It assumes the default Kubernetes identity path.

Before applying it, replace `default.default.mesh.local` with the trust domain in the **caller's**
issued certificate. For a Bundled issuer with automatic trust creation, the corresponding
`MeshTrust.spec.trustDomain` publishes that value. The trust domain is the part between
`spiffe://` and the next `/`. For example, if that field contains `payments.eu.mesh.local`,
set `rules[].default.allow[].spiffeID.value` to
`spiffe://payments.eu.mesh.local/ns/storefront/`. Use that same domain when adapting the
later examples.

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
- `Prefix` matches identities starting with the supplied string. With the default Kubernetes
  path, this includes every service account in `storefront` in that trust domain.
- Other clients are denied unless another applicable policy allows them. A matching deny
  still takes precedence.

Keep the trailing `/`. A prefix ending in `/ns/storefront` would also match
`/ns/storefront-test/sa/client`. This is a string match, not a Kubernetes namespace selector.

There is no `to` array. Access control is enforced inbound at the destination.

## Match caller identities

Use `spiffeID.type: Exact` for one complete identity, or `Prefix` for identities that share
the same beginning.

| Match | Example value | Callers covered |
| --- | --- | --- |
| Exact service account | `spiffe://default.default.mesh.local/ns/storefront/sa/frontend` | All workloads using this identity, not just one replica. |
| Namespace prefix | `spiffe://default.default.mesh.local/ns/storefront/` | All service accounts in this namespace and trust domain, using the default Kubernetes path. |
| Trust-domain prefix | `spiffe://default.default.mesh.local/` | Every identity in this trust domain. |

The default Kubernetes identity path is `/ns/<namespace>/sa/<service-account>`. On Universal,
the default is `/workload/<workload>`. An exact Universal matcher could therefore use
`spiffe://default.default.mesh.local/workload/frontend`.

`MeshIdentity.spec.spiffeID.path` can customize these paths. If it is set, match the path the
caller actually receives. Read the trust domain from the caller's certificate. The corresponding
[MeshTrust](/mesh/policies/meshtrust/) publishes that domain in `spec.trustDomain` and its CA
certificates so peers can verify the identity. Trusting an
identity does not itself grant access.

For zone-egress destinations, use the separate [SNI matcher](#authorize-zone-proxy-traffic).

## How permissions combine

For the protected mTLS traffic, the effective authorization decision follows these rules:

1. A request matching any `deny` matcher is **denied**.
1. Otherwise, a request matching any `allow` or `allowWithShadowDeny` matcher is **allowed**.
1. A request matching nothing is **denied**.

Every `deny` across every policy that applies to the proxy is evaluated before any `allow`,
so a `deny` cannot be overridden by a later or narrower `allow`. YAML list order does not
change this result.

Allow entries also contribute across applicable policies. Suppose a mesh-wide policy allows
`storefront` and a second policy allows `payments` to reach `orders`. Both groups can reach
`orders`: the second policy adds access; it does not restrict access to `payments`. If a third
policy denies `storefront` on `orders`, only `payments` remains allowed there.

Only policies covering the destination and its selected inbound or listener contribute to
that decision. A deny scoped to an admin port does not deny access on other ports.

{:.warning}
> **Do not write a mesh-wide deny-all and then allow services back in.** That pattern comes
> from {{site.mesh_product_name}} 2.x, where the last matching rule won, and it does not
> work here: a blanket `deny` matches every client and no later `allow` can re-open it.
>
> Protected mTLS connections are already denied unless explicitly allowed. Start with the
> `allow` entries you need, and add `deny` entries for exceptions to broader allows.

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

`allowWithShadowDeny` grants access as well as recording a proposed denial, unless an enforced
`deny` matches. Adding it for a previously blocked group can therefore open access. Here,
`legacy` is already covered by the broader allow.

For HTTP traffic, add this format to the destination's
[MeshAccessLog](/mesh/policies/meshaccesslog/) File backend:

```yaml
format:
  type: Plain
  plain: 'client=%DOWNSTREAM_PEER_URI_SAN% shadow=%DYNAMIC_METADATA(envoy.filters.http.rbac:shadow_engine_result)% policy=%DYNAMIC_METADATA(envoy.filters.http.rbac:shadow_effective_policy_id)%'
```

Send requests from `legacy` and inspect the destination's log. The `shadow` field reports
`denied`, and `policy` identifies the matching `MeshTrafficPermission` by its resource
identifier. These are [Envoy RBAC metadata fields](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rbac_filter).
For TCP listeners, use `envoy.filters.network.rbac` in the two metadata operators.

Inspect the policy identifier as well as the decision. The current shadow matcher also reports
`denied` with policy `default` when no shadow entry matches. A `shadow_denied` counter alone
therefore does not tell you how many callers matched your proposed restriction.

When the identified traffic is safe to block, move its matcher from `allowWithShadowDeny` to
`deny` and keep the existing allow entries.

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
leaving its other ports alone. Read `spec.networking.inbound[]` from the destination's
Kubernetes `Dataplane` resource:

```sh
kubectl get dataplane DESTINATION_DATAPLANE -n DESTINATION_NAMESPACE -o jsonpath='{.spec.networking.inbound}'
```

Copy the intended inbound's `name` into `targetRef.sectionName`. If it has no name, use its
`port` as a quoted string, such as `"8080"`. The example below assumes an inbound named
`backend-admin-api`. It denies `observability` access on that inbound even when another
applicable policy allows that namespace.

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
kubectl get dataplane ZONE_PROXY_DATAPLANE -n kong-mesh-system -o jsonpath='{.spec.networking.listeners}'
```

On zone egress, `sni` matches the destination name sent in the TLS handshake. SNI identifies
the requested destination, not the authenticated caller. It accepts only `type: Exact`, and
the value must be a DNS subdomain.

To find the value, inspect the zone-egress proxy's Envoy `/config_dump`. Find the filter chain
for the external service and read `filter_chain_match.server_names`. Copy the corresponding
server name into `rules[].default.deny[].sni.value`. The value below is an example of that
internal routing name; it is not the external service's public hostname.

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

## Verify and troubleshoot authorization

Test from both an allowed caller and a caller that should be denied, using new connections.

1. Confirm that the destination has an identity and that the test uses mTLS.
1. Confirm that `targetRef` selects the destination proxy and, when set, the intended
   `sectionName`.
1. Inspect the caller's certificate through its Envoy admin `/certs` endpoint. Find the SPIFFE
   URI in the workload certificate's subject alternative names and compare it with the
   policy's `Exact` or `Prefix` value.
1. Send the same request from both callers. The allowed caller should reach the application;
   the denied caller should not. Check the destination proxy's logs to establish why it failed.

For HTTP handled by the proxy's HTTP RBAC filter, authorization denial returns `403`.
Include `%RESPONSE_CODE_DETAILS%` in the destination's access-log format to distinguish a
proxy denial from an application-generated `403`. A value beginning with
`rbac_access_denied_matched_policy` identifies an RBAC denial.
See [Envoy's HTTP RBAC diagnostics](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rbac_filter).

For TCP, denial closes the connection. Include `%CONNECTION_TERMINATION_DETAILS%` in the
access-log format to identify a network RBAC denial. See
[Envoy's network RBAC diagnostics](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rbac_filter).

If TLS fails before authorization, check the certificate, identity, and trust configuration
first. Adding an allow entry cannot repair a failed TLS handshake.

| Unexpected result | Check |
| --- | --- |
| An intended caller is denied | Compare its complete issued identity with the matcher, then check for a deny in another applicable policy. |
| An unintended caller is allowed | Check for broader allows, `allowWithShadowDeny` entries, and prefixes missing a path boundary. Confirm that the connection uses mTLS. |
| A port-specific policy has no effect | Compare `sectionName` with the actual inbound name or, for an unnamed inbound, its port number. |
| Every request appears shadow-denied | Inspect `shadow_effective_policy_id`. The fallback value `default` does not identify a match to your proposed restriction. |

For more detail about destination selectors and inbound policy matching, see
[How policies select traffic](/mesh/policy-targeting/).
