---
title: Mesh Rate Limit
name: MeshRateLimits
products:
- mesh
description: Cap how many requests or connections a proxy accepts in a given interval, and choose what a rejected request receives.
content_type: plugin
icon: meshratelimit.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
- text: MeshFaultInjection policy
  url: "/mesh/policies/meshfaultinjection/"
---

`MeshRateLimit` caps the rate at which a proxy accepts work: HTTP requests per interval, or TCP
connections per interval. Requests over the cap are rejected by the proxy without reaching the
application.

The limit is enforced by each proxy against its own traffic, using Envoy's
[token bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/type/v3/token_bucket.proto).
A destination running four replicas with a limit of 100 requests per second therefore accepts
up to 400 across the four, since each counts separately. Sizing the limit means sizing it per
instance.

## Limit requests to a destination

This policy applies to proxies labelled `app: backend` and caps what each of them accepts at
five requests per ten seconds:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-rate-limit
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
```
{% endpolicy_yaml %}

## Where this policy applies

A rate limit belongs to the proxy doing the accepting, so this is an inbound policy, configured
on the proxy being protected rather than on its clients.

Which field carries the configuration depends on what `spec.targetRef` selects, and the two
combinations do not overlap:

{% table %}
columns:
  - title: "`spec.targetRef.kind`"
    key: kind
  - title: Configuration goes in
    key: field
  - title: What it limits
    key: limits
rows:
  - kind: "`Dataplane`, with `labels`"
    field: "`rules`. Defining `to` is rejected with `spec.to (): must not be defined`."
    limits: "Traffic arriving at the selected proxies. Omit `labels` to select every proxy in the mesh."
  - kind: "`Mesh`"
    field: "`to`, whose `targetRef` accepts `kind: Mesh` and nothing else. Defining `rules` is rejected with `spec.rules (): must not be defined`."
    limits: "Traffic passing through gateways. A gateway has no inbound side of its own to configure, which is the case this form covers."
{% endtable %}

Setting both `to` and `rules` is rejected with
`field 'to' must be empty when 'rules' is defined`, and setting neither with
`at least one of 'to' or 'rules' has to be defined`.

A mesh-wide inbound limit is therefore written as `kind: Dataplane` with no `labels`, not as
`kind: Mesh`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## HTTP limits

`local.http.requestRate` sets the cap: `num` requests per `interval`. `num` must be greater
than 0 and `interval` greater than 50ms.

`local.http.onRateLimit` decides what a rejected request receives. Without it the proxy answers
`429 Too Many Requests`.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-rate-limit-response
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
            onRateLimit:
              status: 503
              headers:
                set:
                  - name: x-kuma-rate-limited
                    value: "true"
```
{% endpolicy_yaml %}

`status` is any status greater than 0. `headers.set` replaces a header already on the response
and `headers.add` appends to it, each taking up to 16 entries. Header names are lower case only.

## TCP limits

`local.tcp.connectionRate` caps new connections rather than requests, with the same `num` and
`interval` fields. It applies to any inbound, including one carrying HTTP traffic, where it
limits how often clients may connect rather than what they may send over an established
connection.

An inbound served as plain TCP has no HTTP filters, so `local.http` has no effect there. See
[Universal inbounds must declare their protocol](/mesh/migrate-policies-to-3/#universal-inbounds-must-declare-their-protocol)
for the case where an inbound is served as TCP unintentionally.

## Limit one client

`rules[].matches` narrows a rule to requests from particular clients, matched on `spiffeID`
(`Exact` or `Prefix`) or `sni` (`Exact` only). A rule with no `matches` applies to every client.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-limit-batch-client
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/batch
      default:
        local:
          http:
            requestRate:
              num: 10
              interval: 1s
    - default:
        local:
          http:
            requestRate:
              num: 1000
              interval: 1s
```
{% endpolicy_yaml %}

Each `matches` entry needs at least one of `spiffeID` or `sni`, and a `spiffeID` must set
`type`.

A rule that matches on `spiffeID` cannot carry `local.tcp`, and doing so is rejected with
`can't be specified when matches contain spiffeID because this field cannot be conditioned on
source identity`. The client's identity comes out of the TLS handshake, which a connection-level
limit is counting rather than inspecting. Limit connections with a rule that has no `spiffeID`
match, and limit an individual client's requests with `local.http`.

## Turn a limit off for part of the traffic

`disabled: true` on `local.http` or `local.tcp` removes the limit that a broader policy set,
which is how one client or one inbound is exempted without narrowing the original policy.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRateLimit
mesh: default
name: backend-exempt-monitoring
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.default.mesh.local/ns/observability
      default:
        local:
          http:
            disabled: true
```
{% endpolicy_yaml %}

`local.http` needs at least one of `disabled`, `requestRate` or `onRateLimit`, and `local.tcp`
at least one of `disabled` or `connectionRate`.
