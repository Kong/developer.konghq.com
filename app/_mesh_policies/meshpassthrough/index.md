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
  url: "/mesh/migrate-policies-to-3/#meshpassthrough"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

`MeshPassthrough` controls intercepted outbound traffic that does not match a destination
already known to the mesh. The caller's sidecar either forwards that traffic or rejects
it. Use it to allow selected third-party APIs or database addresses without registering
each destination as a mesh resource.

This is not a blanket rule for all traffic leaving the mesh. A destination represented by
[MeshExternalService](/mesh/meshexternalservice/) has its own routing and policy
configuration; `passthroughMode: None` does not block that known destination. Use
`MeshExternalService` when the destination needs a stable mesh name, a VIP, or other
destination-specific policies.

With no `MeshPassthrough` applying to a proxy, passthrough is enabled for every external
destination. Use `Matched` to create an allowlist or `None` to block all unknown destinations.

The policy needs transparent proxying. On a proxy running without it, or one binding its
outbounds directly, the policy is skipped and the proxy is given the warning
`policy doesn't support proxy running without transparent-proxy`. Without interception the
sidecar never sees traffic to an address it has no outbound for, so there is nothing to allow or
reject.

{:.warning}
> This policy only controls traffic intercepted by the sidecar. Traffic excluded from
> transparent proxying is outside its scope. Do not use it as the sole boundary against a
> workload that can bypass interception; enforce the required network restrictions too.

## Allow two external destinations

This policy applies to every proxy in the mesh and allows two categories of otherwise
unknown traffic: TLS to one API, and TCP to a database port across a subnet. Replace the
example domain and subnet with destinations your workloads need:

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

Read the policy from the proxy to the external destination:

- `targetRef.kind: Mesh` applies the policy to every proxy in the mesh.
- `passthroughMode: Matched` rejects destinations not listed in `appendMatch`.
- The `Domain` entry permits TLS traffic to `api.example.com:443`.
- The `CIDR` entry permits TCP traffic to port `5432` anywhere in `10.42.0.0/16`.

The subnet entry is broader than one database: every address in that range is allowed on
the specified port. Use `type: IP` with one address if only one database should be reachable.
Before applying a mesh-wide allowlist, inventory other unknown destinations used by the
workloads and test with a narrow `Dataplane` selector.

## Choose a mode

`default.passthroughMode` sets the behavior. A matching policy whose effective configuration
omits the mode uses `Matched`. This differs from having no matching policy, which leaves
passthrough enabled. Creating an empty policy can therefore block previously working traffic.

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
    what: "Every otherwise unknown destination intercepted by the proxy. `appendMatch` has no effect."
  - mode: "`None`"
    what: "No otherwise unknown destination. Known mesh destinations are unaffected. `appendMatch` has no effect."
{% endtable %}

`Matched` with an empty `appendMatch` allows nothing, which is the same outcome as `None`.

`spec.targetRef` selects the proxies the mode applies to, and accepts `Mesh` or `Dataplane`
with `labels`. There is no `to` or `rules`: the policy describes what the selected proxies may
reach, so its whole configuration sits under `default`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## When policies overlap

Applicable policies contribute to one configuration for the selected proxy. The
`appendMatch` lists are appended, not replaced. For example, a mesh-wide policy allowing
`api.example.com:443` and a workload-specific policy allowing a database give that workload
both permissions when the effective mode is `Matched`.

Conflicting `passthroughMode` values follow policy precedence. A more specific `None` can
block all unknown traffic for selected workloads; a more specific `All` can open it all.
A policy that only adds matches inherits an explicitly configured mode, so adding an
allowlist does not narrow an inherited `All`: set `passthroughMode: Matched` explicitly.

There are no deny entries and no subtraction from an inherited `appendMatch` list. To
remove one inherited destination while retaining others, change which workloads receive
the broader allowlist. An empty list on a narrower policy does not clear the inherited
entries. Removing the last applicable policy restores unrestricted passthrough rather
than leaving a deny policy behind.

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
    value: "The destination port, 1 to 65535. Required for HTTP-family wildcard domains and for `protocol: mysql`. Where omission is allowed, the match covers all destination ports, subject to more specific port matches. Set it explicitly for a narrow allowlist."
  - field: "`protocol`"
    value: "`tcp`, `tls`, `http`, `http2`, `grpc` or `mysql`. Defaults to `tcp`."
{% endtable %}

Pick the protocol the client actually speaks. `tls` is for traffic the application encrypts
itself, where the sidecar reads the SNI and forwards the connection without terminating it.
`http`, `http2` and `grpc` are for cleartext traffic the sidecar parses, which is what lets it
match on the `Host` header.

Choosing `protocol: tls` does not add encryption or validate the external server's
certificate. The application still performs TLS and must validate the server itself.
A domain match uses the name visible in SNI or HTTP authority, not an authenticated server
identity. A TLS client that sends no matching SNI cannot use a domain-only allowance.

`tcp` and `mysql` cannot be used with `type: Domain`, and are rejected with
`protocol tcp is not supported for a domain`. Neither carries a name the sidecar could match
on, so such a match would capture everything on the port rather than one domain.

## A domain match checks the name, not the resolved address

For both exact and wildcard domains, the sidecar forwards to the original address the
application dialed. An exact `Domain` checks the TLS SNI or HTTP authority against the
configured name; it does not independently resolve that name and pin the connection to
the resulting address.

Duplicate the entry to allow the same domain on more than one port.

{:.warning}
> A client can dial a different address while presenting an allowed SNI or HTTP authority.
> An exact domain narrows the allowed name, but does not prevent this. Use IP or CIDR
> restrictions, a registered external destination, and appropriate network controls when
> the destination address must be constrained. Separate `appendMatch` entries are
> alternatives, not an AND condition: adding an IP entry does not restrict a domain entry.

### Wildcard domains

A wildcard, such as `*.example.com`, allows a set of names instead of one exact name.
Like an exact domain, it only restricts the SNI or HTTP authority, not the address dialed:

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
name to reach it. Prefer exact domains to narrow the allowed names, or IP and CIDR matches
when the allowed addresses are known.

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

A match with a port alongside a match without one is not automatically a conflict.
The all-ports match remains a fallback, and the control plane also expands it onto explicit
ports where compatible so that adding a port-specific entry does not hide unrelated allowed
destinations. If the two configure the same address and filter-chain shape, the explicit
port's configuration takes precedence there. Prefer explicit ports for a narrow allowlist.

An already-applied policy carrying a conflict is not re-validated. The control plane keeps the
first match of the colliding pair in `appendMatch` order, drops the later one, and names it in a
debug log and policy warning for the affected proxy. The next edit of that policy is rejected
until the conflict is resolved. Conflicts can also appear only after separate policies'
`appendMatch` lists are combined, so inspect the effective policy warnings even if each
resource was accepted independently.

## Validate external access

1. Confirm that the selected proxy uses transparent proxying. A policy warning on the proxy
   means the sidecar skipped the policy.
1. Connect to every destination and port named in `appendMatch` and confirm that each connection
   succeeds with the configured protocol.
1. Connect to a destination not in `appendMatch` and confirm that `Matched` rejects it.
   Choose a reachable test server that is not represented by `MeshService`,
   `MeshMultiZoneService`, or `MeshExternalService`; a known destination does not test passthrough.
1. Test an unlisted port as well as an unlisted address. Use fresh connections after policy
   changes so an existing connection does not obscure the result.
1. For a `Domain`, confirm that the application resolves and connects to the intended server
   and sends the expected SNI or HTTP authority.
1. For exact and wildcard domains, verify that allowing any address carrying a matching SNI or `Host`
   value is an acceptable security boundary.

A rejected connection does not always produce an HTTP response. Unmatched TCP or TLS
traffic fails at the connection level. If traffic reaches the HTTP domain-routing filter
but no domain route matches, the sidecar returns `503` with a message identifying the
`MeshPassthrough` policy. Distinguish this from a DNS failure or an external application's
own error before changing the allowlist.

If an unexpected destination remains reachable, check for a known mesh destination,
excluded interception, an inherited `All` mode, or another policy adding an allowance.
If an allowed destination fails, check its actual port, protocol, SNI or HTTP authority,
application DNS resolution, and dropped-match warnings.
