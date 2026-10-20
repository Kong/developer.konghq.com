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
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshtimeout"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

The `MeshTimeout` policy sets how long a proxy waits for a connection to open, for activity on
an idle connection, and for a response.

Every proxy starts with [default values](#default-timeouts), so a policy changes
existing timeouts instead of adding new ones.

A policy configures one side of the connection:

* `to`: waits by the caller proxy.
* `rules`: waits by the destination proxy.

A limit on either side can end the request, so raising the destination's timeout doesn't
extend a shorter deadline at the caller.

## Timeouts for requests a proxy sends

The following example sets the timeouts that proxies labeled `app: web` apply to requests they
send to `backend`:

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

A `web` proxy gives a connection to `backend` 5 seconds to open and an HTTP request 15 seconds
to complete. It closes a connection after one hour idle, and an HTTP stream after 30 minutes
idle. These are the default outbound values, so applying the example unchanged doesn't extend
the response deadline.

What each field does:

* `targetRef` selects the `web` proxies that enforce the limits.
* `to[].targetRef` selects the destination: `Mesh`, `MeshService`, `MeshExternalService`,
  `MeshMultiZoneService`, or `MeshHTTPRoute`.

A policy can't set both `to` and `rules`, so inbound and outbound timeouts need separate
policies. For more information, see
[Timeouts for requests a proxy receives](#timeouts-for-requests-a-proxy-receives).

`sectionName` selects a different side of the connection depending on where you set it:

* `targetRef.sectionName`: an inbound of the selected `Dataplane`. It's only accepted in a policy
  that uses `rules`, so a policy with `to` can't set it.
* `to[].targetRef.sectionName`: a port of the destination `MeshService` or `MeshMultiZoneService`.

## Timeout fields

`default` accepts the following timeouts:

{% table %}
columns:
  - title: Field
    key: field
  - title: Governs
    key: governs
rows:
  - field: "`connectionTimeout`"
    governs: "Time to establish a TCP connection."
  - field: "`idleTimeout`"
    governs: "Time a connection can stay idle. For HTTP, time before a connection with no active streams closes."
  - field: "`http.requestTimeout`"
    governs: "Time to receive a complete response, counted from when the whole request is processed."
  - field: "`http.streamIdleTimeout`"
    governs: "Time an HTTP stream can stay idle."
  - field: "`http.maxStreamDuration`"
    governs: "Maximum lifetime of a stream, regardless of activity. Use it to recycle long-lived streams."
  - field: "`http.maxConnectionDuration`"
    governs: "Time after which a connection to the destination stops accepting new streams and closes once its active streams finish."
  - field: "`http.requestHeadersTimeout`"
    governs: "Time to receive request headers, from their first byte to their last."
{% endtable %}

An `http` block must set at least one field other than `requestHeadersTimeout`. A block with
only `requestHeadersTimeout` is rejected, so pair it with another `http` timeout.

Stream limits also apply to HTTP/1.1. Idle limits measure inactivity, so they don't cap a
stream that keeps sending data.

## Default timeouts

The following defaults apply to every proxy, whether or not a `MeshTimeout` resource exists:

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

The inbound values are double the outbound ones, so a destination doesn't time out a request
before its caller does. For the same reason, `http.requestTimeout` is disabled inbound, and the
caller's 15 seconds sets the limit.

{{site.mesh_product_name}} doesn't create `MeshTimeout` policies for a new mesh, so
`kubectl get meshtimeouts -A` can return nothing even though every proxy uses these values.
Inspect the effective configuration before assuming a request has no deadline.

## Overlapping timeouts

A more specific policy overrides only the fields it sets. For example, setting only
`http.requestTimeout: 30s` for web-to-backend traffic changes its response deadline and keeps
the broader connection and idle limits.

Inbound and outbound policies apply separately. A destination that allows 45 seconds can't keep
a request alive after its caller gives up at 15 seconds. When a request ends too early, check
both sides and any deadline the calling application sets.

## Leave time for retries and streaming

`MeshRetry.http.perTryTimeout` limits one attempt, and `MeshTimeout.http.requestTimeout` limits
the whole request, including retries and backoff. For example, a 5-second request timeout
doesn't leave room for four 2-second attempts, whatever the retry count.

For long-lived responses, use `streamIdleTimeout` to limit inactivity and `maxStreamDuration`
to limit lifetime. A short request timeout can end an otherwise healthy stream.

## Timeouts for requests a proxy receives

`rules` configures the inbound side, and each rule can match the caller's identity. The
following example sets the inbound timeouts for proxies labeled `app: backend`:

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

### Timeouts that can't vary by client

A rule that matches on `spiffeID` can set only `http.requestTimeout` and
`http.streamIdleTimeout`. The other five fields apply to shared connections or listeners, so
they can't vary by caller and are rejected in a rule with an identity match. Set them in a rule
without one.

The following example gives callers from the `kong-mesh-demo` namespace a 45-second request
timeout:

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
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa
      default:
        http:
          requestTimeout: 45s
```
{% endpolicy_yaml %}

Replace `default.default.mesh.local` with the trust domain from a matching caller's
certificate. For example, a trust domain of
`payments.eu.mesh.local` gives the namespace prefix
`spiffe://payments.eu.mesh.local/ns/kong-mesh-demo/sa`.

The value must be a valid SPIFFE ID, so it can't end in `/`. Because `Prefix` is a plain string
comparison, a prefix ending at `/ns/kong-mesh-demo` would also match `kong-mesh-demo-test`. End
it at `/ns/kong-mesh-demo/sa` to match that namespace only.

## Disable a timeout

To disable an idle or HTTP timeout, set it to `0s`. `connectionTimeout` can't be disabled and
must be greater than zero. The following example disables the HTTP request timeout:

```yaml
http:
  requestTimeout: 0s
```

## Validating timeout behavior

1. Use an endpoint that can delay its response by a known amount.
1. From a selected client, send a request that finishes just inside the limit, and confirm that
   it succeeds.
1. Send a request that finishes after the limit, and confirm that the proxy ends it at the
   configured timeout.
1. Repeat from a proxy that the policy doesn't select, and confirm that its behavior is
   unchanged.
1. For inbound rules with a `spiffeID` match, repeat from a matching and a non-matching
   identity. This shows whether a rule didn't match or its value didn't take effect.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "A request ends before the configured deadline"
    check: "The caller, the destination, the application's deadline, and the `MeshRetry` per-try timeout."
  - unexpected: "A streaming response ends despite regular data"
    check: "`requestTimeout` and `maxStreamDuration`. Activity resets only idle timers."
  - unexpected: "A zero value is rejected"
    check: "`connectionTimeout` can't be disabled."
  - unexpected: "An identity-specific limit has no effect"
    check: "Confirm mTLS, and compare the caller's SPIFFE URI with the matcher."
{% endtable %}
