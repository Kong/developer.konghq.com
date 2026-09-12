---
title: Mesh Retry
name: MeshRetries
products:
- mesh
description: Retry failed requests to a destination, for HTTP, gRPC, and TCP traffic.
content_type: plugin
icon: meshretry.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshretry"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

`MeshRetry` makes a client proxy try a failed request again, instead of returning the failure
to the caller. It applies to the client side of a connection, so the policy is written from
the perspective of the proxy making the request.

Use it to absorb transient failures: a destination restarting, a connection reset mid-flight,
or a rate limit that clears in a second or two.

A newly created mesh normally includes a mesh-wide retry policy. Writing a narrower policy
changes that behavior for selected traffic; it does not necessarily introduce retries for the
first time. See [the initial defaults](#defaults-and-disabling-retries) below.

{:.warning}
> Retries multiply load on a struggling destination. Pair a retry policy with
> [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), and set `perTryTimeout` so a slow
> destination cannot hold a retried request open for the whole route timeout.

A failed response does not prove that the destination did no work. Retrying a payment or another
write can repeat its side effects. Use retries for operations that are safe to repeat, or require
an application-level idempotency mechanism that recognizes repeated operations.

## Retry HTTP requests to a destination

This policy applies to proxies labeled `app: frontend`, and governs the requests they make
to the `backend` service:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRetry
mesh: default
name: frontend-to-backend
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        http:
          numRetries: 3
          perTryTimeout: 2s
          retryOn:
            - 5xx
            - Reset
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects **which proxies retry**. These are clients, not the destination.
* `to[].targetRef` selects **which destination** the retries apply to.
* `default` carries the configuration, under `http`, `grpc`, or `tcp`. At least one of the
  three is required.

`numRetries: 3` permits up to four attempts, including the original request.
`perTryTimeout: 2s` limits an attempt, while
[MeshTimeout](/mesh/policies/meshtimeout/) sets the overall HTTP response deadline.
The proxy stops when the request succeeds, retries are exhausted, or the overall deadline
expires. Three retries are a maximum, not a promise that all three will run.

The per-attempt timer applies before the proxy starts sending the response to the caller.
It is not a lifetime limit for a response that has already started streaming. Use
`MeshTimeout` stream limits for that case. See
[Envoy's timeout behavior](https://www.envoyproxy.io/docs/envoy/latest/faq/configuration/timeouts).

## Where this policy applies

`spec.targetRef` selects which proxies retry, and these are the callers: `Mesh`, or
`Dataplane` with `labels`. `spec.to[].targetRef` selects the destination the retries apply
to, and accepts `Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` or
`MeshHTTPRoute`.

There is no `rules` array. A retry is a decision the caller makes, so it is configured
outbound only.

Targeting a `MeshHTTPRoute` retries only the requests that route matches, which scopes a
retry to one path rather than a whole service. For the selectors a policy can carry, see
[How policies select traffic](/mesh/policy-targeting/).

## Defaults and disabling retries

The initial `mesh-retry-all` policy sets HTTP and gRPC `numRetries: 5`,
`perTryTimeout: 16s`, and backoff from 25ms to 250ms. TCP uses
`maxConnectAttempt: 5`. Installations that skip initial MeshRetry creation do not receive
this policy.

The initial HTTP conditions cover gateway errors, connection failures, and refused streams.
If no effective HTTP retry configuration supplies `numRetries`, Envoy's retry count is one.
If `retryOn` is omitted or empty in an effective HTTP configuration, the generated conditions
are `GatewayError`, `ConnectFailure`, and `RefusedStream`; an empty list does not disable retries.

Set `http.numRetries: 0` or `grpc.numRetries: 0` to disable the corresponding policy-generated
retries. TCP counts total connection attempts, so `tcp.maxConnectAttempt: 1` permits only
the initial attempt.

More specific policies override fields they set and inherit other fields from broader policies.
For example, changing only HTTP `numRetries` to 2 retains a broader policy's per-attempt timeout.
A supplied `retryOn` list replaces the broader list. Removing the narrower policy restores the
broader behavior, including retries previously disabled by that override.

## Choose what to retry on

`retryOn` lists failures that can trigger a retry. HTTP method entries are different: they restrict which
requests are eligible to retry.

### HTTP

{% table %}
columns:
  - title: Value
    key: value
  - title: Retries when
    key: when
rows:
  - value: "`5xx`"
    when: "The destination answers with any 5xx, or does not answer at all. Includes `ConnectFailure` and `RefusedStream`."
  - value: "`GatewayError`"
    when: "The destination answers 502, 503, or 504."
  - value: "`Reset`"
    when: "The destination does not answer at all: disconnect, reset, or read timeout."
  - value: "`Retriable4xx`"
    when: "The destination answers 409, which is the only 4xx this condition covers."
  - value: "`ConnectFailure`"
    when: "The connection to the destination failed, including connect timeout."
  - value: "`EnvoyRatelimited`"
    when: "The `x-envoy-ratelimited` header is present."
  - value: "`RefusedStream`"
    when: "The destination reset the stream with `REFUSED_STREAM`."
  - value: "`Http3PostConnectFailure`"
    when: "An HTTP/3 request failed after connecting."
  - value: "`HttpMethodGet` and other methods"
    when: "Restricts retry eligibility to the named method; it is not itself a failure condition. Pair `HttpMethodGet` with a condition such as `5xx` to retry only failed GET requests."
  - value: "A status code"
    when: "Any numeric HTTP status code, such as `500` or `429`."
{% endtable %}

{:.warning}
> `5xx` is lower case. `5XX` is rejected as `unknown item '5XX'`, even though it appears as
> the example value in the CRD and the OpenAPI schema. Every other named condition is
> upper camel case.

### gRPC

`Canceled`, `DeadlineExceeded`, `Internal`, `ResourceExhausted`, and `Unavailable`. These
match the gRPC status in the response headers, and unlike the HTTP list they are a closed
set: no other value is accepted.

### TCP

TCP has no conditions. `maxConnectAttempt` is the whole configuration, and a connection is
retried when it fails to establish:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRetry
mesh: default
name: frontend-to-backend-tcp
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        tcp:
          maxConnectAttempt: 5
```
{% endpolicy_yaml %}

`maxConnectAttempt: 5` permits five TCP connection attempts in total, not five retries
after the first attempt. It does not replay application messages after an established connection
breaks.

## Control the interval between retries

Retries back off exponentially. `baseInterval` defaults to `25ms`, and `maxInterval` defaults
to ten times whichever `baseInterval` is in effect. An interval under 1ms is rounded up.

```yaml
http:
  numRetries: 5
  backOff:
    baseInterval: 100ms
    maxInterval: 5s
```

### Back off by what the destination asks for

When a destination answers a rate limit with a header saying when to come back,
`rateLimitedBackOff` uses that instead of the exponential schedule. Headers are tried in
order and matched case-insensitively; the first one that parses is used, and if none parse
the exponential backoff applies:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshRetry
mesh: default
name: respect-retry-after
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
      default:
        http:
          numRetries: 3
          retryOn:
            - EnvoyRatelimited
          rateLimitedBackOff:
            maxInterval: 30s
            resetHeaders:
              - name: retry-after
                format: Seconds
              - name: x-ratelimit-reset
                format: UnixTimestamp
```
{% endpolicy_yaml %}

`format` is `Seconds` for a number of seconds to wait, or `UnixTimestamp` for a point in
time. `maxInterval` defaults to `300s`. A header asking for a longer wait is discarded;
the proxy tries the next configured header, then falls back to exponential backoff if none
qualifies. It does not shorten the requested wait to the maximum. Envoy also adds jitter,
so the actual delay is not a fixed schedule. See
[Envoy's rate-limit backoff behavior](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#config-route-v3-retrypolicy-ratelimitedretrybackoff).

The header controls the wait only after the response qualifies for a retry. This example
requires `x-envoy-ratelimited`; a plain `429` with only `Retry-After` will not satisfy that
condition. Use the quoted status-code condition `"429"` when that is how your backend signals
rate limiting.

## Retry somewhere else

By default a retry may go back to the host that just failed. `hostSelection` changes which
hosts are eligible:

{% table %}
columns:
  - title: Predicate
    key: predicate
  - title: Effect
    key: effect
rows:
  - predicate: "`OmitPreviousHosts`"
    effect: "Skip hosts already tried for this request."
  - predicate: "`OmitHostsWithTags`"
    effect: "Skip hosts carrying the given tags. `tags` is required with this predicate."
  - predicate: "`OmitPreviousPriorities`"
    effect: "Skip priorities already tried. `updateFrequency` sets how often priority load is recalculated, and defaults to 2."
{% endtable %}

`hostSelectionMaxAttempts` caps how many times host selection is retried before the policy
gives up and uses the last host it selected. It defaults to one reattempt.

Host selection chooses another endpoint of the routed backend. It does not automatically
fail over to a different MeshService. To observe a change of endpoint, the backend needs
multiple eligible endpoints.

## Filter which requests are eligible

`retriableRequestHeaders` restricts retries to requests with matching headers. It does not
trigger a retry by itself: the response or connection failure must also satisfy `retryOn`.

`retriableResponseHeaders` describes response headers that can trigger retries, but Envoy
only uses these matchers when its `retriable-headers` retry condition is enabled. The current
v3 policy implementation supplies the matchers without enabling that condition. Do not rely
on this field alone to retry a response; use a supported `retryOn` condition and verify the
generated configuration before depending on header-triggered retries. See
[Envoy's retry policy reference](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#config-route-v3-retrypolicy).

## Validate retry behavior

Test with a destination that can fail in a controlled way, and observe both the client response
and the number of attempts received by the destination. For the first example, one original
request can produce up to four attempts: the first attempt plus `numRetries: 3`.

Check a slow failure separately. `perTryTimeout: 2s` limits each attempt, but the route's
overall request timeout can end the operation before every retry runs. If attempts exceed the
expected count, check for retries in the application or another proxy as well as in this policy.

For example, an application making three attempts through a proxy that permits three attempts
per application call can produce up to nine backend attempts. Test with application retries
disabled first so the proxy's behavior can be measured separately.

| Unexpected result | Check |
| --- | --- |
| A slow request is never retried | Compare the per-attempt timeout with the overall request deadline. The deadline may expire first. |
| A 429 is not retried | Match `"429"` explicitly or confirm that the configured response-header condition is present. |
| A retry reaches the same endpoint | Check host-selection settings and the number of eligible endpoints. |
| Retries continue after deleting your policy | Check the initial mesh-wide policy and retry logic in the application. |
