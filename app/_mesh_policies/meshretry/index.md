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
- text: MeshHTTPRoute policy
  url: "/mesh/policies/meshhttproute/"
---

`MeshRetry` makes a client proxy try a failed request again, instead of returning the failure
to the caller. It applies to the client side of a connection, so the policy is written from
the perspective of the proxy making the request.

Use it to absorb transient failures: a destination restarting, a connection reset mid-flight,
or a rate limit that clears in a second or two.

{:.warning}
> Retries multiply load on a struggling destination. Pair a retry policy with
> [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/), and set `perTryTimeout` so a slow
> destination cannot hold a retried request open for the whole route timeout.

## Retry HTTP requests to a destination

This policy applies to proxies labelled `app: frontend`, and governs the requests they make
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

## Choose what to retry on

`retryOn` is a list, and a request is retried if any entry matches.

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
    when: "The request used that method. One value per method: `HttpMethodConnect`, `HttpMethodDelete`, `HttpMethodGet`, `HttpMethodHead`, `HttpMethodOptions`, `HttpMethodPatch`, `HttpMethodPost`, `HttpMethodPut`, `HttpMethodTrace`."
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
time. `maxInterval` defaults to `300s` and caps whatever the header asks for.

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

## Filter which requests are eligible

`retriableRequestHeaders` requires a header to be present on the request before any retry is
attempted, which is how a client opts a request in. `retriableResponseHeaders` retries when
the response carries a matching header, alongside whatever `retryOn` matched.
