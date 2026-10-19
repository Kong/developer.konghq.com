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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshpassthrough"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

The `MeshPassthrough` policy controls intercepted outbound traffic to destinations the mesh
doesn't know. The caller's sidecar either forwards that traffic or rejects it. Use this policy
to allow selected third-party APIs or database addresses without registering each one as a
mesh resource.

This policy doesn't cover all traffic leaving the mesh. A destination represented by a
[MeshExternalService](/mesh/meshexternalservice/) has its own routing and policies, and
`passthroughMode: None` doesn't block it. Use `MeshExternalService` when a destination needs a
stable mesh name, a VIP, or its own policies.

Proxies that no `MeshPassthrough` selects allow passthrough to every external destination.

The policy needs transparent proxying. A proxy without it, or one that binds its outbounds
directly, skips the policy and gets a policy warning.

{:.warning}
> This policy only controls traffic intercepted by the sidecar. Traffic excluded from
> transparent proxying is outside its scope. Do not use it as the only boundary for a
> workload that can bypass interception. Enforce network restrictions too.

## Allow two external destinations

The following example allows TLS traffic to one API and TCP traffic to a database port across
a subnet. Replace the domain and subnet with the destinations your workloads need:

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

What each field does:

- `targetRef` selects the proxies the policy applies to: `Mesh`, or `Dataplane` with `labels`.
  `kind: Mesh` means every proxy in the policy's own namespace. If the policy is created in
  `{{site.mesh_namespace}}`, it applies to the whole zone. To cover every zone, create the
  policy on the global control plane. For more information, see
  [Where a policy applies](/mesh/policy-targeting/#where-a-policy-applies).
- `passthroughMode: Matched` rejects destinations not listed in `appendMatch`.
- The `Domain` entry allows TLS traffic to `api.example.com:443`.
- The `CIDR` entry allows TCP traffic to port `5432` anywhere in `10.42.0.0/16`.

The policy has no `to` or `rules`, its whole configuration sits under `default`.

The `CIDR` entry allows every address in the range on that port. To allow only one database,
use `type: IP` with one address. Before applying a mesh-wide allowlist, list the other unknown
destinations your workloads use, and test with a narrow `Dataplane` selector.

## Modes

`default.passthroughMode` accepts the following modes:

{% table %}
columns:
  - title: "`passthroughMode`"
    key: mode
  - title: What passes
    key: what
rows:
  - mode: "`Matched`"
    what: "Only the destinations in `appendMatch`. With an empty `appendMatch`, nothing passes. This is the default."
  - mode: "`All`"
    what: "Every unknown destination the proxy intercepts. `appendMatch` has no effect."
  - mode: "`None`"
    what: "No unknown destination. Known mesh destinations are unaffected. `appendMatch` has no effect."
{% endtable %}

A policy that leaves out the mode uses `Matched`, but having no policy at all leaves
passthrough open. Creating an empty policy can therefore block traffic that used to work.

## Describe a destination

Each entry in `appendMatch` names one destination with the following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "`type`"
    value: "`Domain`, `IP`, or `CIDR`."
  - field: "`value`"
    value: "The domain name, IP address, or CIDR range. A CIDR is normalized before comparison, so `10.0.0.1/24` and `10.0.0.0/24` are the same range."
  - field: "`port`"
    value: "The destination port, from 1 to 65535. Required for HTTP-family wildcard domains and for `protocol: mysql`. When left out, the match covers all ports not matched more specifically. Set it for a narrow allowlist."
  - field: "`protocol`"
    value: "`tcp` (default), `tls`, `http`, `http2`, `grpc`, or `mysql`. `tcp` and `mysql` can't be used with `type: Domain`, because they carry no name to match on."
{% endtable %}

Pick the protocol the client actually speaks:

- `tls`: traffic the application encrypts itself. The sidecar reads the SNI and forwards the
  connection without terminating it.
- `http`, `http2`, `grpc`: cleartext traffic the sidecar parses, so it can match on the `Host`
  header.

`protocol: tls` doesn't add encryption or validate the server's certificate. The application
still performs TLS and must validate the server itself. A TLS client that sends no matching SNI
can't use a domain allowance.

## Domain matches

An exact or wildcard `Domain` checks the TLS SNI or HTTP authority against the configured name.
The sidecar then forwards to the address the application dialed. It doesn't resolve the name
itself or pin the connection to that address.

To allow the same domain on more than one port, add one entry per port.

{:.warning}
> A client can dial a different address while presenting an allowed SNI or HTTP authority.
> An exact domain narrows the allowed name, but does not prevent this. When the destination
> address must be constrained, use IP or CIDR restrictions, a registered external destination,
> and network controls. Separate `appendMatch` entries are alternatives, not an AND condition:
> adding an IP entry does not restrict a domain entry.

### Wildcard domains

A wildcard such as `*.example.com` allows a set of names instead of one. Like an exact domain,
it restricts only the SNI or HTTP authority, so a workload can dial any address and present a
matching name. Prefer exact domains, or IP and CIDR matches when you know the addresses.

Partial wildcards like `*w.example.com` aren't supported. A wildcard needs a `port` when the
protocol is `http`, `http2`, or `grpc`, because those share one filter chain per port.

The following example allows TLS traffic on port 9093 to any host in a Kafka cluster's domain:

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

## Conflicting matches

Each match becomes a filter chain on the passthrough listener. Two matches that produce the same
chain are rejected. That happens when they use the same port, or both use no port, with:

- two of `grpc`, `http`, and `http2`, which share one chain per port
- the same address written differently: an IP and a CIDR covering only that IP, a CIDR with
  host bits set, or another form of the same IPv6 address
- `tcp` and `mysql` on the same address, which produce the same TCP proxy chain

Matches that produce distinct chains are fine, such as `tls` and `http` on one port, or `http`
on an IP and `grpc` on a domain. Several `http` domains on the same port are also fine, because
they become separate routes in one chain.

A match with a port and a match without one aren't automatically a conflict. The all-ports
match stays a
fallback, and the control plane also applies it to explicit ports where compatible, so a
port-specific entry doesn't hide other allowed destinations. If both use the same address and
chain shape, the explicit port's configuration wins on that port.

A policy that's already applied isn't re-validated for conflicts. The control plane keeps
the first of the two matches in `appendMatch` order, drops the second, and reports it in a debug
log and a policy warning on the affected proxy. The next edit of that policy is rejected until
the conflict is fixed. Conflicts can also appear only when separate policies' `appendMatch`
lists combine, so check the proxy's policy warnings even if each policy was accepted.

## Overlapping policies

All policies that apply to a proxy combine into one configuration:

- `appendMatch` lists are appended, not replaced. For example, a mesh-wide policy allowing
  `api.example.com:443` and a workload policy allowing a database give that workload both,
  when the effective mode is `Matched`.
- Conflicting `passthroughMode` values follow policy precedence. A more specific `None` blocks
  all unknown traffic for the selected workloads, and a more specific `All` opens it.
- A policy that only adds matches inherits an explicit mode, so it doesn't narrow an inherited
  `All`. Set `passthroughMode: Matched` explicitly.

You can't deny or remove an inherited `appendMatch` entry, and an empty list on a narrower
policy doesn't clear it. To drop one inherited destination, change which workloads get the
broader allowlist. Removing the last applicable policy restores unrestricted passthrough.

## Validating external access

1. Confirm that the selected proxy uses transparent proxying. A policy warning on the proxy
   means the sidecar skipped the policy.
1. Connect to every destination and port in `appendMatch`, and confirm that each connection
   succeeds with the configured protocol.
1. Connect to a destination not in `appendMatch`, and confirm that `Matched` rejects it. Use a
   reachable server that isn't a `MeshService`, `MeshMultiZoneService`, or
   `MeshExternalService`, because known destinations don't test passthrough.
1. Repeat with an unlisted port on a listed address. Use new connections after each policy
   change, so an existing connection doesn't hide the result.
1. For a `Domain`, confirm that the application connects to the intended server and sends the
   expected SNI or HTTP authority.
1. For exact and wildcard domains, confirm that allowing any address with a matching SNI or
   `Host` value is an acceptable security boundary.

A rejected connection doesn't always return an HTTP response:

- Unmatched TCP or TLS traffic fails at the connection level.
- HTTP traffic that matches no domain route gets a `503` that names the `MeshPassthrough`
  policy. Rule out DNS failures and errors from the external application before changing the
  allowlist.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "An unlisted destination is reachable"
    check: "A known mesh destination, excluded interception, an inherited `All` mode, or another policy adding an entry."
  - unexpected: "An allowed destination fails"
    check: "Its port, protocol, SNI or HTTP authority, the application's DNS resolution, and dropped-match warnings."
{% endtable %}
