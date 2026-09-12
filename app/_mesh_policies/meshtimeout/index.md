---
title: Mesh Timeout
name: MeshTimeouts
products:
- mesh
description: Set how long a proxy waits when connecting to a destination, and when serving a request.
content_type: plugin
icon: meshtimeout.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshtimeout"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

`MeshTimeout` sets how long a proxy waits before giving up: on establishing a connection, on
an idle connection, and on a response arriving.

A mesh already has timeouts. {{site.mesh_product_name}} creates a default `MeshTimeout` for
every mesh, so a policy of your own changes those values rather than introducing timeouts
where there were none.

Choose the side that owns the limit: `to` controls waits by a caller proxy, while `rules`
controls traffic handled by a destination proxy. A limit on either side can end the request.
Increasing the destination's timeout does not extend a shorter deadline at the caller.

## Timeouts for requests a proxy sends

This policy applies to proxies labeled `app: web`, and governs the requests they make to
`backend`:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
mesh: default
name: web-to-backend
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        connectionTimeout: 5s
        idleTimeout: 1h
        http:
          requestTimeout: 15s
          streamIdleTimeout: 30m
```
{% endpolicy_yaml %}

In this example, the `web` proxy gives a connection to `backend` five seconds to establish and
an HTTP request 15 seconds to complete. An established connection may remain idle for one hour,
while an HTTP stream with no activity is closed after 30 minutes.

`targetRef` selects the web proxies enforcing these outbound limits.
`to[].targetRef` selects the backend MeshService they call. This example uses the initial
outbound values, so applying it unchanged does not increase the default response budget.

## Where this policy applies

`spec.targetRef` selects which proxies the timeouts are configured on: `Mesh`, or `Dataplane`
with `labels`. `spec.to[].targetRef` sets timeouts for traffic those proxies send, and
accepts `Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` or
`MeshHTTPRoute`. `spec.rules[]` sets timeouts for traffic they receive.

**`to` and `rules` are mutually exclusive.** A policy defining both is rejected with
`fields 'to' must be empty when 'rules' is defined`, so inbound and outbound timeouts need
separate policies.

For inbound port scope, `targetRef.sectionName` names an inbound of the selected Dataplane.
For outbound MeshService scope, `to[].targetRef.sectionName` names a port in
`MeshService.spec.ports[]`. These select opposite sides of the connection.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## What each timeout governs

{% table %}
columns:
  - title: Field
    key: field
  - title: Governs
    key: governs
rows:
  - field: "`connectionTimeout`"
    governs: "How long the proxy waits for a TCP connection to be established."
  - field: "`idleTimeout`"
    governs: "How long a connection may exist with no activity. On HTTP, how long before a connection with no active streams is closed."
  - field: "`http.requestTimeout`"
    governs: "How long the proxy waits for a complete response, measured from the point the whole request has been processed."
  - field: "`http.streamIdleTimeout`"
    governs: "How long an HTTP request/response stream may exist with no activity."
  - field: "`http.maxStreamDuration`"
    governs: "The maximum lifetime of a stream, whatever its activity. Used to recycle long-lived streams."
  - field: "`http.maxConnectionDuration`"
    governs: "How long after establishment a connection is drained and closed. With active streams, the drain runs and the connection is force-closed 5 seconds later."
  - field: "`http.requestHeadersTimeout`"
    governs: "How long the proxy waits for request headers, timed from the first byte of the headers to the last."
{% endtable %}

{:.info}
> Stream limits also apply to HTTP/1.1 requests. An idle limit measures inactivity; it does
> not cap the total duration of a stream that keeps sending data.

## The defaults a mesh starts with

{{site.mesh_product_name}} creates two `MeshTimeout` policies for each mesh, one for inbound
and one for outbound, both targeting `kind: Mesh`.

{% table %}
columns:
  - title: Timeout
    key: timeout
  - title: Outbound default
    key: out
  - title: Inbound default
    key: in
rows:
  - timeout: "`connectionTimeout`"
    out: "5s"
    in: "10s"
  - timeout: "`idleTimeout`"
    out: "1h"
    in: "2h"
  - timeout: "`http.requestTimeout`"
    out: "15s"
    in: "0, disabled"
  - timeout: "`http.streamIdleTimeout`"
    out: "30m"
    in: "1h"
  - timeout: "`http.maxStreamDuration`"
    out: "unset"
    in: "0, disabled"
{% endtable %}

The inbound values are twice the outbound ones, so a receiving proxy does not time out a
request before the caller does. `http.requestTimeout` is disabled inbound for the same
reason: the caller's 15 seconds governs how long a request may take.

A mesh created with `skipCreatingInitialPolicies` covering `MeshTimeout` has neither of
these initial resources. That does not disable timeouts: generated proxy configuration and
Envoy still supply fallback values. Inspect the effective configuration before assuming a
request has no deadline.

## How overlapping timeouts combine

A more specific policy overrides fields it sets and keeps fields supplied by broader policies.
For example, setting only `http.requestTimeout: 30s` for web-to-backend traffic changes its
response deadline while retaining the broader connection and idle limits.

Inbound and outbound policies are applied separately. A destination allowing 45 seconds cannot
keep a request alive after its caller gives up at 15 seconds. Check both sides and any deadline
set by the calling application when a request ends earlier than expected.

## Leave time for retries and streaming

`MeshRetry.http.perTryTimeout` bounds an individual attempt.
`MeshTimeout.http.requestTimeout` bounds the overall request, including retries and backoff.
For example, a 5-second overall deadline and a 2-second per-attempt timeout do not leave room
for four complete 2-second attempts, regardless of the configured retry count.

For a long-lived response, decide separately how long silence is acceptable and whether the
stream needs a maximum lifetime. Use `streamIdleTimeout` for inactivity and
`maxStreamDuration` for lifetime. A short request timeout can end an otherwise healthy stream.

## Timeouts for requests a proxy receives

`rules` configures the inbound side, and each rule may match on the calling identity:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
mesh: default
name: backend-inbound
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        connectionTimeout: 10s
        idleTimeout: 2h
        http:
          requestTimeout: 30s
```
{% endpolicy_yaml %}

### Timeouts that cannot vary by client

A rule matching on `spiffeID` may set only `http.requestTimeout` and
`http.streamIdleTimeout`. The other five fields are rejected with
`can't be specified when matches contain spiffeID because this field cannot be conditioned on
source identity`.

The implementation can select `requestTimeout` and `streamIdleTimeout` per matched request.
The remaining fields are configured on shared connection or listener settings and cannot vary
by the calling SPIFFE ID in this policy. Configure those in a rule without an identity match.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshTimeout
mesh: default
name: backend-from-frontend
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Prefix
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/
      default:
        http:
          requestTimeout: 45s
```
{% endpolicy_yaml %}

Read the SPIFFE URI in a matching caller's certificate. Replace `default.default.mesh.local`
with its trust domain: the text between `spiffe://` and the next `/`. That value goes after
`spiffe://` in `rules[].matches[].spiffeID.value`. For example, a trust domain of
`payments.eu.mesh.local` produces the namespace prefix
`spiffe://payments.eu.mesh.local/ns/kong-mesh-demo/`. Keep the trailing slash so the prefix
does not also match a namespace whose name merely starts with `kong-mesh-demo`.

## Disable a timeout

For the idle and HTTP timeout fields, set the duration to `0s` to disable that limit.
`connectionTimeout` is the exception: it must be greater than zero.
For example, this disables the HTTP request timeout:

```yaml
http:
  requestTimeout: 0s
```

## Validate timeout behavior

Use an endpoint that can delay its response by a known amount. From a selected client, send one
request that finishes just inside the configured limit and another that finishes after it. The
first should succeed; the second should be ended by the proxy at the configured timeout.

Test from a proxy that the policy does not select as well. Its behavior should remain unchanged.
For inbound policies with a `spiffeID` match, repeat the request from one matching and one
non-matching identity so you can distinguish a timeout rule that did not match from a timeout
value that did not take effect.

| Unexpected result | Check |
| --- | --- |
| A request ends before the configured deadline | Check the caller, destination, application deadline, and per-attempt retry timeout. |
| A streaming response ends despite regular data | Check request timeout and maximum stream duration; activity only resets idle timers. |
| A zero value is rejected | `connectionTimeout` cannot be disabled. |
| An identity-specific limit has no effect | Confirm mTLS and compare the caller's issued SPIFFE URI with the matcher. |
