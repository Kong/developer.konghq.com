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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtrafficpermission"
- text: MeshIdentity resource
  url: "/mesh/policies/meshidentity/"
- text: Migrate mesh mTLS to MeshIdentity
  url: "/mesh/migrate-mtls-to-meshidentity/"
---

The `MeshTrafficPermission` policy controls which workloads can connect to a destination
workload. It has two parts:

* `spec.targetRef` selects the destination proxies that enforce the policy.
* `spec.rules[].default` lists the callers to allow or deny.

The destination's proxy identifies each caller by the SPIFFE ID in its mTLS certificate.
Client IP addresses and client data plane tags don't affect access.

## Before you configure permissions

[MeshIdentity](/mesh/policies/meshidentity/) gives workloads their identities and certificates.
Both the caller and the destination need an identity for an mTLS connection. Define the
permissions first, or at the same time as enabling identity on the destination.

Authorization on mTLS connections is default-deny. If no applicable permission allows a
caller, the destination proxy denies it, so you don't need a deny-all policy.

These rules apply only to mTLS connections. A destination without a workload identity has no
mTLS listener to protect. If [MeshTLS](/mesh/policies/meshtls/) permits plaintext, plaintext
connections bypass `MeshTrafficPermission`. Use `Strict` mode when the destination must accept
only authenticated, authorized traffic.

## Allow a namespace to reach one workload

Replace `default.default.mesh.local` in the examples on this page with the trust domain in the
caller's issued certificate. The trust domain is the part between `spiffe://` and the next
`/`. For a Bundled issuer with automatic trust creation, `MeshTrust.spec.trustDomain` publishes
that value. For example, with `payments.eu.mesh.local`, set
`rules[].default.allow[].spiffeID.value` to `spiffe://payments.eu.mesh.local/ns/storefront/sa`.

The following example allows callers in the `storefront` namespace to reach destination
proxies labeled `app: orders`, using the default Kubernetes identity path:

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
              value: spiffe://default.default.mesh.local/ns/storefront/sa
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects the `orders` proxies that enforce the policy.
* `rules[].default.allow` lists the caller identities those proxies accept. Other callers are
  denied unless another applicable policy allows them, and a matching deny still wins.
* `Prefix` matches identities that start with the value. Ending it at `/ns/storefront/sa`
  covers only the service accounts in `storefront`.

`Prefix` is a plain string comparison, not a namespace selector. A prefix ending at
`/ns/storefront` also matches `/ns/storefront-test/sa/client`. The value must be a valid SPIFFE
ID, so it can't end in `/`. To match one namespace only, end the prefix at `/sa`, or name each
caller with `type: Exact`.

The policy has no `to` array, because access control is enforced inbound at the destination.

## Match caller identities

Use `spiffeID.type: Exact` for one complete identity, or `Prefix` for identities with the same
beginning. The following matchers are common:

{% table %}
columns:
  - title: Match
    key: match
  - title: Example value
    key: example
  - title: Callers covered
    key: callers
rows:
  - match: "Exact service account"
    example: "`spiffe://default.default.mesh.local/ns/storefront/sa/frontend`"
    callers: "Every workload using this identity, not one replica."
  - match: "Namespace prefix"
    example: "`spiffe://default.default.mesh.local/ns/storefront/sa`"
    callers: "Every service account in the namespace, with the default Kubernetes path. A prefix ending at `/ns/storefront` would also match `storefront-test`."
  - match: "Trust-domain prefix"
    example: "`spiffe://default.default.mesh.local`"
    callers: "Every identity in the trust domain. A trailing `/` isn't a valid SPIFFE ID."
{% endtable %}

By default, identity paths use the following formats:

* `/ns/<namespace>/sa/<service-account>` on Kubernetes
* `/workload/<workload>` on Universal, for example
  `spiffe://default.default.mesh.local/workload/frontend`

If `MeshIdentity.spec.spiffeID.path` customizes the path, match the path the caller actually
receives. Read the trust domain from the caller's certificate.
[MeshTrust](/mesh/policies/meshtrust/) publishes that domain and its CA certificates so peers
can verify the identity. Trusting an identity doesn't grant access.

With the default `MeshIdentity` template, the trust domain is `<mesh>.<zone>.mesh.local`, so each
zone has its own. To allow callers from several zones, add a `spiffeID` match for each zone's
trust domain. For more information, see
[MeshIdentity in multi-zone meshes](/mesh/policies/meshidentity/#multi-zone-meshes).

To control which external destinations callers reach through zone egress, use the
[SNI matcher](#authorize-zone-proxy-traffic).

## Overlapping permissions

For mTLS traffic, the proxy decides authorization in the following order:

1. A request matching any `deny` is denied.
1. Otherwise, a request matching any `allow` or `allowWithShadowDeny` is allowed.
1. A request matching nothing is denied.

Every `deny` in every applicable policy is evaluated before any `allow`, so a narrower `allow`
can't override a `deny`. YAML list order doesn't matter.

Allows add up across policies. If one policy allows `storefront` and another allows
`payments` to reach `orders`, both can reach it. If a third policy denies `storefront` on
`orders`, only `payments` remains allowed.

Only policies that cover the destination and its selected inbound or listener count. A deny on
an admin port doesn't deny access on other ports.

{:.warning}
> Do not write a mesh-wide deny-all and then allow services back in. A blanket `deny` matches
> every client, and no `allow` can re-open it.
>
> Protected mTLS connections are already denied unless explicitly allowed. Start with the
> `allow` entries you need, and add `deny` entries for exceptions to broader allows.

## Exclude clients from a broader allow

Use a `deny` as an exception to an `allow`. The following example accepts every client in the
trust domain except the `legacy` namespace and one service account:

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
              value: spiffe://default.default.mesh.local/ns/legacy/sa
          - spiffeID:
              type: Exact
              value: spiffe://default.default.mesh.local/ns/storefront/sa/retired-client
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local
```
{% endpolicy_yaml %}

The `deny` entries are evaluated first, and the `allow` admits everyone else. A policy with only
the `deny` entries wouldn't open access to anyone.

## Observe a deny before enforcing it

`allowWithShadowDeny` allows a matching client and records a shadow-deny decision. Unless an
enforced `deny` matches, it grants access, so adding it for a blocked group opens access.

The following example observes the effect of denying `legacy`, which the broader allow already
covers:

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
              value: spiffe://default.default.mesh.local/ns/legacy/sa
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local
```
{% endpolicy_yaml %}

To record the decision for HTTP traffic, add the following format to the destination's
[MeshAccessLog](/mesh/policies/meshaccesslog/) File backend:

```yaml
format:
  type: Plain
  plain: 'client=%DOWNSTREAM_PEER_URI_SAN% shadow=%DYNAMIC_METADATA(envoy.filters.http.rbac:shadow_engine_result)% policy=%DYNAMIC_METADATA(envoy.filters.http.rbac:shadow_effective_policy_id)%'
```

For TCP listeners, use `envoy.filters.network.rbac` in the two metadata operators. For more
information, see [Envoy RBAC metadata fields](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rbac_filter).

Send requests from `legacy` and check the destination's log. The `shadow` field reports
`denied`, and `policy` identifies the matching `MeshTrafficPermission`.

Check `policy` as well as `shadow`. When no shadow entry matches, the log still reports
`denied`, with policy `default`. A `shadow_denied` counter alone doesn't tell you how many
callers matched.

When the traffic is safe to block, move its matcher from `allowWithShadowDeny` to `deny` and
keep the existing allow entries.

## Scope authorization to destinations

`targetRef` controls where the rules are enforced:

{% table %}
columns:
  - title: Target
    key: target
  - title: Effect
    key: effect
rows:
  - target: "`kind: Mesh`, or no `targetRef`"
    effect: "Every identified workload the policy reaches."
  - target: "`kind: Dataplane` with `labels`"
    effect: "Matching destination proxies only."
  - target: "`kind: Dataplane` with `labels` and `sectionName`"
    effect: "One named inbound of those proxies only."
{% endtable %}

{:.warning}
> `MeshTrafficPermission` has no `to` array, so a policy created in an application namespace
> is always `workload-owner` scoped: `kind: Mesh` reaches every proxy in that namespace,
> not the whole mesh. To authorize across namespaces in one zone, create the policy in
> `{{site.mesh_namespace}}` with the label `kuma.io/origin: zone`. To authorize across zones,
> create it on the global control plane. For more information, see
> [Where a policy applies](/mesh/policy-targeting/#where-a-policy-applies).

### Narrow authorization to one port

`targetRef.sectionName` applies the rules to one named inbound and leaves the other ports
alone. To find the inbound names, read `spec.networking.inbound[]` from the destination's
`Dataplane`:

```sh
kubectl get dataplanes.kuma.io DESTINATION_DATAPLANE -n DESTINATION_NAMESPACE -o jsonpath='{.spec.networking.inbound}'
```

Copy the inbound's `name` into `targetRef.sectionName`. If it has no name, use its `port` as a
quoted string, such as `"8080"`.

The following example denies `observability` on the `backend-admin-api` inbound, even when
another policy allows that namespace:

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
              value: spiffe://default.default.mesh.local/ns/observability/sa
```
{% endpolicy_yaml %}

### Authorize zone proxy traffic

`MeshTrafficPermission` applies to the zone egress listeners of a mesh-scoped zone proxy. It has
no effect on zone ingress listeners, which pass TLS through without terminating it. Select the
proxy role and zone with `targetRef.labels`, and the listener with `targetRef.sectionName`.

`sectionName` matches the listener's `name` in `Dataplane.networking.listeners[]`. A listener
without a `name` uses its port number, so a Helm install with default ports uses `10002` for
zone egress. Read the listener names instead of assuming the defaults:

```sh
kubectl get dataplanes.kuma.io ZONE_PROXY_DATAPLANE -n kong-mesh-system -o jsonpath='{.spec.networking.listeners}'
```

Zone egress is default-deny. When the zone proxy has a workload identity and no
`MeshTrafficPermission` selects its egress listener, every connection through zone egress is
denied. Zone egress terminates the caller's mTLS connection, so `spiffeID` matchers identify the
caller there, as they do on an inbound. The following example lets every workload in the trust
domain use zone egress:

{% policy_yaml namespace=kong-mesh-system %}
```yaml
type: MeshTrafficPermission
name: allow-mesh-through-zone-egress
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
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.default.mesh.local
```
{% endpolicy_yaml %}

On zone egress, `sni` matches the destination name in the TLS handshake. It identifies the
requested destination, not the caller. It accepts only `type: Exact`, and the value must be a
DNS subdomain.

To find the value, inspect the zone egress proxy's Envoy `/config_dump`, find the filter chain
for the external service, and copy its `filter_chain_match.server_names` value into
`rules[].default.deny[].sni.value`. This is an internal routing name, not the external
service's public hostname.

The following example denies traffic to one external service through zone egress:

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

This `deny` is an exception to applicable `allow` entries, such as the one in
`allow-mesh-through-zone-egress`. It doesn't allow anything by itself.

## Validating authorization

Test from an allowed caller and a caller that should be denied, using new connections:

1. Confirm that the destination has an identity and that the test uses mTLS.
1. Confirm that `targetRef` selects the destination proxy and, if set, the intended
   `sectionName`.
1. Check the caller's certificate in its Envoy admin `/certs` endpoint. Confirm that the SPIFFE
   URI in its subject alternative names matches the policy's `Exact` or `Prefix` value.
1. Send the same request from both callers. Confirm that the allowed caller reaches the
   application and the denied caller doesn't. If a request fails unexpectedly, check the
   destination proxy's logs.

To tell a proxy denial from an application error, add the following to the destination's
access-log format:

* HTTP: `%RESPONSE_CODE_DETAILS%`. A proxy denial returns `403`, and the value starts with
  `rbac_access_denied_matched_policy`. For more information, see
  [Envoy's HTTP RBAC diagnostics](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rbac_filter).
* TCP: `%CONNECTION_TERMINATION_DETAILS%`. A denial closes the connection. For more
  information, see [Envoy's network RBAC diagnostics](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rbac_filter).

If TLS fails before authorization, check the certificate, identity, and trust configuration
first. An allow entry can't fix a failed TLS handshake.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "An intended caller is denied"
    check: "Compare its full issued identity with the matcher, then look for a deny in another applicable policy."
  - unexpected: "An unintended caller is allowed"
    check: "Look for broader allows, `allowWithShadowDeny` entries, and prefixes without a path boundary. Confirm that the connection uses mTLS."
  - unexpected: "A port-specific policy has no effect"
    check: "Compare `sectionName` with the inbound name, or its port number if it has no name."
  - unexpected: "Every request appears shadow-denied"
    check: "`shadow_effective_policy_id`. The value `default` doesn't mean your restriction matched."
{% endtable %}
