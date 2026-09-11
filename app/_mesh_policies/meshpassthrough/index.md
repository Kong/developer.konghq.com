---
title: Mesh Passthrough
name: MeshPassthroughs
products:
- mesh
description: Control which destinations outside the mesh a proxy may reach, by domain, IP or CIDR range.
content_type: plugin
icon: policy.svg
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

`MeshPassthrough` decides what a proxy may reach outside the mesh. Traffic to a destination the
mesh knows nothing about — a third-party API, a managed database, a service never added to the
mesh — either passes through the sidecar or is rejected by it, and this policy sets which.

The policy needs transparent proxying. On a proxy running without it, or one binding its
outbounds directly, the policy is skipped and the proxy is given the warning
`policy doesn't support proxy running without transparent-proxy`. Without interception the
sidecar never sees traffic to an address it has no outbound for, so there is nothing to allow or
reject.

## Allow two external destinations

This policy applies to every proxy in the mesh and permits exactly two destinations:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshPassthrough
mesh: default
name: allow-external-apis
spec:
  targetRef:
    kind: Mesh
  default:
    passthroughMode: Matched
    appendMatch:
      - type: Domain
        value: api.example.com
        port: 443
        protocol: tls
      - type: CIDR
        value: 10.42.0.0/16
        port: 5432
        protocol: tcp
```
{% endpolicy_yaml %}

## Choose a mode

`default.passthroughMode` sets the behaviour, and defaults to `Matched` when it is not
specified.

{% table %}
columns:
  - title: "`passthroughMode`"
    key: mode
  - title: What passes
    key: what
rows:
  - mode: "`Matched`"
    what: "Only the destinations in `appendMatch`. The default."
  - mode: "`All`"
    what: "Every external destination. `appendMatch` has no effect."
  - mode: "`None`"
    what: "Nothing. `appendMatch` has no effect."
{% endtable %}

`Matched` with an empty `appendMatch` allows nothing, which is the same outcome as `None`.

`spec.targetRef` selects the proxies the mode applies to, and accepts `Mesh` or `Dataplane`
with `labels`. There is no `to` or `rules`: the policy describes what the selected proxies may
reach, so its whole configuration sits under `default`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## Describe a destination

Each entry in `appendMatch` names one destination.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`type`"
    value: "`Domain`, `IP` or `CIDR`."
  - field: "`value`"
    value: "The domain name, IP address or CIDR range. A CIDR is normalized before it is compared, so `10.0.0.1/24` and `10.0.0.0/24` are the same range."
  - field: "`port`"
    value: "The destination port, 1 to 65535. Required for a `Domain` that is not a wildcard, and for `protocol: mysql`. Left out, the match covers every port used elsewhere in the policy."
  - field: "`protocol`"
    value: "`tcp`, `tls`, `http`, `http2`, `grpc` or `mysql`. Defaults to `tcp`."
{% endtable %}

Pick the protocol the client actually speaks. `tls` is for traffic the application encrypts
itself, where the sidecar reads the SNI and forwards the connection without terminating it.
`http`, `http2` and `grpc` are for cleartext traffic the sidecar parses, which is what lets it
match on the `Host` header.

`tcp` and `mysql` cannot be used with `type: Domain`, and are rejected with
`protocol tcp is not supported for a domain`. Neither carries a name the sidecar could match
on, so such a match would capture everything on the port rather than one domain.

## A domain match resolves the domain

For a `Domain` that is not a wildcard, the sidecar resolves the name itself and connects to the
resolved address on `port`. The destination therefore does not depend on the address the client
dialed, and `port` is required — a `Domain` without one is rejected with
`port must be defined for a domain, the sidecar resolves the domain to pin the destination`.

Duplicate the entry to allow the same domain on more than one port.

Make sure the sidecar can resolve those names. A domain it cannot resolve has no endpoint, so
its traffic fails rather than falling back to the address the client dialed.

### Wildcard domains

A wildcard, such as `*.example.com`, has no single address to resolve. Its traffic goes to the
address the client dialed, and the match only restricts the SNI or `Host` header:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshPassthrough
mesh: default
name: allow-kafka-cluster
spec:
  targetRef:
    kind: Mesh
  default:
    appendMatch:
      - type: Domain
        value: "*.cluster-1.kafka.aws.us-east-2.com"
        port: 9093
        protocol: tls
```
{% endpolicy_yaml %}

A workload covered by a wildcard entry can therefore dial any address and present a matching
name to reach it. In an allowlist, prefer exact domains, IPs or CIDR ranges where the set of
destinations is known.

A partial wildcard is not supported: `*.example.com` is accepted, `*w.example.com` is rejected
with `partial wildcard is currently not supported`. A wildcard also needs a `port` when the
protocol is `http`, `http2` or `grpc`, since those share one filter chain per port.

## Two matches cannot describe the same filter chain

Each match becomes a filter chain on the generated passthrough listener, and two matches that
resolve to the same chain are rejected on apply. These collide when they configure the same
port, or both configure no port, with:

- two of `grpc`, `http` and `http2`, which share one chain per port
- the same address written differently — an IP and a CIDR covering only that IP, a CIDR with
  host bits set, or another textual form of the same IPv6 address
- `tcp` and `mysql` on the same address, which generate an identical TCP proxy chain

Combinations that generate distinct chains are fine: `tls` alongside `http` on one port, or
`http` on an IP alongside `grpc` on a domain. Several `http` domains on the same port are also
fine, since they share a chain and merge as separate routes within it.

A match with a port alongside a match without one is not a conflict. The port-specific match
owns its port, and the match without a port covers the remaining ports used in the policy.

An already-applied policy carrying a conflict is not re-validated. The control plane keeps the
first match of the colliding pair in `appendMatch` order, drops the later one, and names it in a
debug log of the `MeshPassthrough` component. The next edit of that policy is rejected until the
conflict is resolved.
