---
title: Mesh Retry
name: MeshRetries
products:
- mesh
description: Retry failed requests to a destination, for HTTP, gRPC, and TCP traffic.
content_type: plugin
icon: meshretry.png
related_resources:
- text: Policy targeting
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshretry"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
- text: MeshCircuitBreaker policy
  url: "/mesh/policies/meshcircuitbreaker/"
---

The `MeshRetry` policy makes a client proxy try a failed request again, instead of returning
the failure to the caller. You configure it on the side of the proxy making the request.

Use this policy to absorb short failures, such as a destination restarting, a connection reset,
or a rate limit that clears in a second or two.

A new mesh doesn't retry requests until you apply a `MeshRetry`. For more information, see
[Defaults and disabling retries](#defaults-and-disabling-retries).

{:.warning}
> Retries multiply load on a struggling destination. Pair a retry policy with
> [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), and set `perTryTimeout` so a slow
> destination cannot hold a retried request open for the whole route timeout.

A failed response doesn't prove that the destination didn't do anything. Retrying a payment or another
write can repeat its side effects. Only retry operations that are safe to repeat, or use an
application-level idempotency mechanism.

## Retry HTTP requests to a destination

The following example makes proxies labeled `app: frontend` retry failed requests to `backend`
up to three times:

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

* `targetRef` selects the client proxies that retry: `Mesh`, or `Dataplane` with `labels`.
* `to[].targetRef` selects the destination the retries apply to: `Mesh`, `MeshService`,
  `MeshExternalService`, `MeshMultiZoneService`, or `MeshHTTPRoute`. A `MeshHTTPRoute` limits
  retries to the requests that route matches.
* `default` holds the configuration under `http`, `grpc`, `tcp`, or a combination of them. At
  least one is required.

The policy has no `rules`, because the caller decides whether to retry.

`numRetries: 3` allows up to four attempts, including the original request. `perTryTimeout: 2s`
limits each attempt, and [MeshTimeout](/mesh/policies/meshtimeout/) sets the overall HTTP
response deadline. The proxy stops when the request succeeds, the retries run out, or the
overall deadline expires, so all three retries might not run.

The per-attempt timer only runs until the proxy starts sending the response to the caller. It
doesn't limit a response that's already streaming, so use `MeshTimeout` stream limits for that.
For more information, see
[Envoy's timeout behavior](https://www.envoyproxy.io/docs/envoy/latest/faq/configuration/timeouts).

## Defaults and disabling retries

A new mesh has no `MeshRetry`, so a proxy attempts each request once. Unlike
[MeshTimeout](/mesh/policies/meshtimeout/), retries have no built-in defaults, so your first
`MeshRetry` introduces retries.

When an effective HTTP configuration leaves out a field, the following values apply:

* No `numRetries`: Envoy retries once.
* No `retryOn`, or an empty list: the conditions are `GatewayError`, `ConnectFailure`, and
  `RefusedStream`. An empty list doesn't disable retries.

To disable retries, set the following:

* HTTP: `http.numRetries: 0`.
* gRPC: `grpc.numRetries: 0`.
* TCP: `tcp.maxConnectAttempt: 1`. TCP counts total connection attempts, so this allows only
  the first one.

## Retry conditions

`retryOn` lists the failures that can trigger a retry. HTTP method entries are the exception:
they restrict which requests can be retried.

### HTTP

HTTP `retryOn` accepts the following values:

{% table %}
columns:
  - title: Value
    key: value
  - title: Retries when
    key: when
rows:
  - value: "`5xx`"
    when: "The destination returns any 5xx, or doesn't answer. Includes `ConnectFailure` and `RefusedStream`."
  - value: "`GatewayError`"
    when: "The destination returns 502, 503, or 504."
  - value: "`Reset`"
    when: "The destination doesn't answer: disconnect, reset, or read timeout."
  - value: "`Retriable4xx`"
    when: "The destination returns 409. No other 4xx is covered."
  - value: "`ConnectFailure`"
    when: "The connection to the destination fails, including a connect timeout."
  - value: "`EnvoyRatelimited`"
    when: "The response has the `x-envoy-ratelimited` header."
  - value: "`RefusedStream`"
    when: "The destination resets the stream with `REFUSED_STREAM`."
  - value: "`Http3PostConnectFailure`"
    when: "An HTTP/3 request fails after connecting."
  - value: "`HttpMethodGet` and other methods"
    when: "Limits retries to that method. Without a named condition in the list, the default conditions (`GatewayError`, `ConnectFailure`, `RefusedStream`) apply. For example, `HttpMethodGet` with `5xx` retries only failed GET requests."
  - value: "A status code"
    when: "The destination returns that HTTP status code, such as `500` or `429`. If the list has no named condition, the default conditions also apply."
{% endtable %}

{:.warning}
> `5xx` is lowercase. `5XX` is rejected, even though it appears as
> the example value in the CRD and the OpenAPI schema. Every other named condition is
> upper camel case.

### gRPC

gRPC `retryOn` accepts only the following values, which match the gRPC status in the response
headers:

* `Canceled`
* `DeadlineExceeded`
* `Internal`
* `ResourceExhausted`
* `Unavailable`

### TCP

TCP has no conditions. A connection is retried when it fails to open, and `maxConnectAttempt`
is the only setting. It counts total attempts, not retries after the first one. It doesn't
replay application messages after an open connection breaks.

The following example allows up to five connection attempts from `frontend` to `backend`:

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

## Control the interval between retries

Retries back off exponentially. `backOff` accepts the following fields:

* `baseInterval`: defaults to `25ms`.
* `maxInterval`: defaults to ten times the effective `baseInterval`.

An interval under 1ms is rounded up.

The following example starts the backoff at 100ms and caps it at 5s:

```yaml
http:
  numRetries: 5
  backOff:
    baseInterval: 100ms
    maxInterval: 5s
```

### Rate-limited backoff

When a destination answers a rate limit with a header that says when to try again,
`rateLimitedBackOff` uses that instead of the exponential backoff. It accepts the following
fields:

* `resetHeaders` (required): headers to read, tried in order and matched case-insensitively. The first one
  that parses is used. Each header's `format` is either `Seconds` for a number of seconds to
  wait, or `UnixTimestamp` for a point in time.
* `maxInterval`: the longest wait to accept, `300s` by default. A header asking for a longer
  wait is skipped instead of shortened, and the next header is tried.

If no header qualifies, the exponential backoff applies. Envoy also adds jitter, so the actual
delay varies. For more information, see
[Envoy's rate-limit backoff behavior](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#config-route-v3-retrypolicy-ratelimitedretrybackoff).

The header only sets the wait after the response qualifies for a retry. The following example
retries only responses with `x-envoy-ratelimited`, so a plain `429` with only `Retry-After`
isn't retried. If your backend signals rate limiting with `429`, add the quoted status-code
condition `"429"`:

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

## Retry somewhere else

By default, a retry can go back to the host that just failed. `hostSelection` accepts the
following predicates to change which hosts are eligible:

{% table %}
columns:
  - title: Predicate
    key: predicate
  - title: Effect
    key: effect
rows:
  - predicate: "`OmitPreviousHosts`"
    effect: "Skips hosts already tried for this request."
  - predicate: "`OmitHostsWithTags`"
    effect: "Skips hosts with the given `tags`, which are required."
  - predicate: "`OmitPreviousPriorities`"
    effect: "Skips priorities already tried. `updateFrequency` sets how often priority load is recalculated, and defaults to 2."
{% endtable %}

`hostSelectionMaxAttempts` caps how many times host selection is retried before the proxy uses
the last host it selected. It defaults to one reattempt. An `http` block that sets only
`hostSelectionMaxAttempts` is rejected, so set it alongside another `http` field.

Host selection picks another endpoint of the same backend. It doesn't fail over to a different
`MeshService`, and it needs several eligible endpoints to make a difference.

## Filter which requests are eligible

`retriableRequestHeaders` limits retries to requests with matching headers. It doesn't trigger a
retry by itself: the failure must also match `retryOn`.

## Overlapping policies

A more specific policy overrides the fields it sets and inherits the rest from broader
policies. For example, changing only HTTP `numRetries` to 2 keeps a broader policy's
per-attempt timeout. A `retryOn` list replaces the broader list instead of adding to it.
Removing the narrower policy restores the broader behavior, including retries the narrower
policy disabled.

## Validating retry behavior

1. Disable retries in the application, so you measure only the proxy. For example, three
   application attempts through a proxy that allows three attempts per call can produce up to
   nine backend attempts.
1. Make the destination fail in a controlled way, and count the attempts it receives. For the
   first example, one request produces up to four attempts.
1. Confirm the response the client gets after the retries run out.
1. Test a slow failure separately, and confirm whether the overall request timeout ends the
   request before every retry runs.

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "More attempts than expected"
    check: "Retries in the application or in another proxy."
  - unexpected: "A slow request is never retried"
    check: "Compare the per-attempt timeout with the overall request deadline, which may expire first."
  - unexpected: "A 429 isn't retried"
    check: "Match `\"429\"` explicitly, or confirm that the response has the header your condition requires."
  - unexpected: "A retry reaches the same endpoint"
    check: "`hostSelection` and the number of eligible endpoints."
  - unexpected: "Retries continue after deleting your policy"
    check: "Other `MeshRetry` policies that select the same traffic, and the application's retry logic."
{% endtable %}
