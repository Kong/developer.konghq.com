---
title: 'Circuit Breaker'
name: 'Circuit Breaker'

content_type: plugin

publisher: kong-inc
description: 'Protect upstream services by automatically stopping requests at the Service or Route level when failures or upstream latency exceed configured thresholds, allowing unhealthy backends time to recover.'

tier: enterprise

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.17'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - traffic-control

search_aliases:
  - circuit-breaker
  - kong-circuit-breaker
  - circuit breaker
  - fail fast
  - resiliency

icon: kong-circuit-breaker.png

categories:
   - traffic-control

related_resources:
  - text: Protect an unreliable upstream with the Circuit Breaker plugin
    url: /how-to/protect-an-upstream-with-circuit-breaker/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
  - text: OpenTelemetry plugin
    url: /plugins/opentelemetry/
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
---

The Circuit Breaker plugin stops requests to an unhealthy upstream and lets it recover.
It counts failures and slow responses on a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/), and rejects new requests when the count crosses a threshold.              

The Circuit Breaker plugin lets you:
* Fail fast on a Service or Route that points at a single, fixed backend.
* Open the circuit on slow responses as well as on failures.
* Re-enable the backend automatically through probe requests.

By default, an open circuit returns a `503` response.
You can change the status code and the response body.

The plugin complements [Upstream health checks](/gateway/traffic-control/health-checks-circuit-breakers/), which route around unhealthy [Targets](/gateway/entities/target/) of an [Upstream](/gateway/entities/upstream/).
Use health checks to manage the Targets behind a load balancer, and the Circuit Breaker plugin to protect the Service or Route as a whole.
See [Circuit Breaker plugin and Upstream health checks](#circuit-breaker-plugin-and-upstream-health-checks) for a comparison.

## Use cases

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Protect an unreliable upstream](/how-to/protect-an-upstream-with-circuit-breaker/)"
    description: "Open a circuit after repeated failures, then let the upstream recover and close the circuit automatically."
  - use_case: "[Open the circuit on upstream failures](/plugins/kong-circuit-breaker/examples/open-on-upstream-failures/)"
    description: "Count `5xx` responses, timeouts, and connection failures, and fail fast with a `503` response once a threshold is crossed."
  - use_case: "[Open the circuit on slow responses](/plugins/kong-circuit-breaker/examples/open-on-slow-responses/)"
    description: "Open the circuit when the share of slow upstream responses crosses a percentage, with a minimum sample size for low-traffic Routes."
  - use_case: "[Return a custom response when the circuit is open](/plugins/kong-circuit-breaker/examples/custom-open-response/)"
    description: "Enable both circuits and return a custom status code and JSON body while a circuit is open."
{% endtable %}
<!--vale on-->

## How it works

The Circuit Breaker plugin runs in the `access` and `log` [phases](/gateway/entities/plugin/#plugin-contexts) of the request:

* In the `access` phase, the plugin checks the state of its circuits before the request reaches the upstream.
  If a circuit is open, the plugin rejects the request.
* In the `log` phase, after the response, the plugin classifies the outcome and updates the counters.

Each circuit is always in one of the following states:

<!--vale off-->
{% table %}
columns:
  - title: State
    key: state
  - title: Behavior
    key: behavior
rows:
  - state: Closed
    behavior: |
      {{site.base_gateway}} proxies requests normally.
      The plugin counts failures and slow responses.
  - state: Open
    behavior: |
      The plugin rejects requests before they reach the upstream.
      The circuit stays open for [`config.policy_circuit.recovery_period_ms`](/plugins/kong-circuit-breaker/reference/#schema--config-policy-circuit-recovery-period-ms) or [`config.latency_circuit.recovery_period_ms`](/plugins/kong-circuit-breaker/reference/#schema--config-latency-circuit-recovery-period-ms), depending on which circuit opened.
  - state: Half-open
    behavior: |
      The plugin admits a limited number of probe requests to test whether the upstream recovered.
      Further requests are rejected until the probe sample finishes.
{% endtable %}
<!--vale on-->

When the count crosses a threshold, {{site.base_gateway}} rejects new requests before they reach the upstream. 
After a recovery period, the plugin lets a few test requests through.                                      
If they succeed, the circuit closes and traffic flows normally again.

<!--vale off-->
{% mermaid %}
stateDiagram-v2
    direction LR
    [*] --> Closed
    Closed --> Open: Threshold crossed
    Open --> HalfOpen: Recovery period elapsed,<br>next request arrives
    HalfOpen --> Closed: Probe sample passes
    HalfOpen --> Open: Probe sample fails
{% endmermaid %}
<!--vale on-->

The Circuit Breaker plugin runs after [authentication](/plugins/?category=authentication) and [rate limiting](/plugins/?terms=rate%2520limiting) plugins, so only the requests that those plugins allow count toward a circuit.

{:.warning}
> Do not use [dynamic plugin ordering](/gateway/entities/plugin/#dynamic-plugin-ordering) to run this plugin before authentication or rate limiting.
Dynamic ordering only changes the `access` phase, so an open circuit rejects requests before those plugins run.

## Circuits

The plugin has two independent circuits: a [policy failure circuit](#policy-failure-circuit) and a [latency circuit](#latency-circuit).

Use `open_when` to choose which threshold opens each the circuit.
If either circuit is open, the plugin rejects the request.
Otherwise, the plugin measures the request separately for each circuit, so a single slow request that also fails counts toward both.

### Policy failure circuit

The policy failure circuit opens when requests fail.
Configure it with [`config.policy_circuit`](/plugins/kong-circuit-breaker/reference/#schema--config-policy-circuit).
Use [`config.policy_circuit.failure_types`](/plugins/kong-circuit-breaker/reference/#schema--config-policy-circuit-failure-types) to choose which outcomes count as a failure:

<!--vale off-->
{% table %}
columns:
  - title: Failure type
    key: type
  - title: What it matches
    key: matches
rows:
  - type: "`http_5xx`"
    matches: "A `5xx` response that the upstream sends."
  - type: "`backend_timeout`"
    matches: "A `504` response."
  - type: "`backend_connection_failure`"
    matches: |
      A `502` response from {{site.base_gateway}}, which means {{site.base_gateway}} couldn't connect to the upstream or couldn't read a valid response from it.
      A `502` that the upstream sends itself matches `http_5xx` instead.
  - type: "`gateway_processing_failure`"
    matches: "A `5xx` response from {{site.base_gateway}}'s error handler other than `502` and `504`."
  - type: "`policy_execution_error`"
    matches: |
      An error raised by another plugin on the request.
      Plugin errors count only under this type.
      If you remove it from `failure_types`, the circuit ignores plugin errors.
{% endtable %}
<!--vale on-->

A failed client request only counts once, even if its outcome matches several failure types.

### Latency circuit

The latency circuit opens when the upstream responds slowly.
Configure it with [`config.latency_circuit`](/plugins/kong-circuit-breaker/reference/#schema--config-latency-circuit).
A response is considered slow when the time to first byte from the upstream exceeds [`config.latency_circuit.max_upstream_ttfb_ms`](/plugins/kong-circuit-breaker/reference/#schema--config-latency-circuit-max-upstream-ttfb-ms).

The plugin measures time to first byte instead of the full response time, so that long streaming responses (for example, AI responses) don't open the circuit.

### When a circuit opens

Circuits count failures in a sampling window.
Use `open_when` to open the circuit on a failure count (`max_failures`), a failure percentage (`failure_percentage`), either threshold, or both.

The percentage is the share of requests in the sampling window that failed.
The first request of the next window triggers the percentage check, and only one worker judges each window.

Choose a threshold based on the traffic that the circuit covers:
* On a busy Service or Route, a fixed count can open the circuit during a normal traffic spike, or on one slow Target out of many.
  A percentage tracks the health of all the traffic through the circuit.
* On a low-traffic Service or Route, a percentage can read high after only a few early failures.
  Set `min_samples`, or use the count threshold.
* To react quickly to a total outage and also catch partial degradation, use `either`.
* To require both a minimum volume of failures and a high failure rate, use `both`.

### Recovery and half-open

When a circuit opens, it stays open for the time period defined in `recovery_period_ms`.
When that period has elapsed, the next request moves the circuit to half-open.

Half-open is the testing state between open and closed.
The plugin admits up to `half_open_calls` requests to the upstream as probes, and rejects other requests until the probes finish.
If the percentage of failed probes is less than `half_open_failure_threshold_percent`, the circuit closes and its counters reset.
Otherwise, the circuit reopens and the recovery period restarts.

The following rules also apply:
* A probe result comes only from a request that reached the upstream.
  The plugin ignores a request that a later plugin ended, or whose client disconnected, and returns its probe slot to the pool.
* Only probes move a half-open circuit.
  A request that started before the circuit opened and finishes during half-open leaves the circuit unchanged.

## Ignored requests

The plugin ignores the following requests:
* A request that {{site.base_gateway}} rejected because a circuit was open or the probe sample was full.
  Ignoring these lets the circuit close.
* A request that a later plugin ended before the upstream call, for example a cache hit, a mocked response, or a [Request Termination](/plugins/request-termination/) response.
* A request where the client closed the connection first (status `499`).
* A client error that {{site.base_gateway}} answers after the plugin runs, for example `400`, `408`, or `413`.

Ignored requests don't count towards any circuits.

## Observability

### Metrics

The plugin records metrics through {{site.base_gateway}}'s metrics registry.
Use the [OpenTelemetry plugin](/plugins/opentelemetry/) to export them.
For a walkthrough that exports these metrics, see [Protect an unreliable upstream with the Circuit Breaker plugin](/how-to/protect-an-upstream-with-circuit-breaker/#export-circuit-breaker-metrics-with-opentelemetry).

<!--vale off-->
{% table %}
columns:
  - title: Metric
    key: metric
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - metric: "`kong.circuit_breaker.state`"
    type: Gauge
    description: |
      The state of a circuit.
      One series exists for each state (`closed`, `open`, `half_open`).
      The series for the current state is `1`, and the other two are `0`.
  - metric: "`kong.circuit_breaker.policy.failure`"
    type: Counter
    description: "Requests that counted as a policy failure."
  - metric: "`kong.circuit_breaker.latency.violation`"
    type: Counter
    description: "Requests that exceeded the latency threshold."
  - metric: "`kong.circuit_breaker.open`"
    type: Counter
    description: "The number of times a circuit opened."
  - metric: "`kong.circuit_breaker.recovery`"
    type: Counter
    description: "The number of times a circuit returned to closed."
  - metric: "`kong.circuit_breaker.request.rejected`"
    type: Counter
    description: "Requests rejected while a circuit was open or the probe sample was full."
{% endtable %}
<!--vale on-->

Each metric has the attributes `kong.circuit_breaker.circuit` (`policy` or `latency`) and `kong.plugin.id`.
Metrics also carry `kong.service.name`, or `kong.route.name` when `config.identifier` is `route`.

### Logs

The Circuit Breaker plugin writes a notice-level log entry on every state transition.
The entry has the `[kong-circuit-breaker]` prefix.
Each entry is a list of `key=value` pairs.

It includes the following:
* The circuit (`policy` or `latency`) and the transition, for example `closed->open`.
* The Service and Route IDs, the request ID, and `recovery_period_ms`.
* The `reason` for the transition, for example `max_failures`, `failure_percentage`, `recovery_period`, or `probes_passed`.
* The values behind the decision, such as `failures`, `max_failures`, and `window_seconds` when the circuit opens, or `samples` and `failure_rate` when probes finish.
* `max_upstream_ttfb_ms`, for the latency circuit.

For example, the following entry shows the policy circuit opening after three failures:

```
[notice] [kong] handler.lua:175 [kong-circuit-breaker] policy closed->open service=<service-id> route=<route-id> reason=max_failures failures=3 open_when=max_failures max_failures=3 window_seconds=60 recovery_period_ms=15000 request_id=<request-id>
```
{:.no-copy-code.wrap}

The plugin also adds a `circuit_breaker` field to the log serializer, which every logging plugin receives.
The field marks a rejected request with `rejected`, and holds the `policy` or `latency` reason when a request counted toward a circuit.

## Circuit Breaker plugin and Upstream health checks

{{site.base_gateway}} Upstreams support [active and passive health checks](/gateway/traffic-control/health-checks-circuit-breakers/).
Passive health checks are also known as circuit breakers, but they work differently from this plugin.
Health checks act in the load balancer and mark individual Targets healthy or unhealthy.
The Circuit Breaker plugin acts on a Service or Route, and rejects requests in the `access` phase, before the load balancer.

<!--vale off-->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Circuit Breaker plugin
    key: plugin
  - title: Upstream health checks
    key: health_checks
rows:
  - capability: Where it applies
    plugin: "A Service or Route, including one with a single, fixed backend"
    health_checks: "The Targets of an Upstream"
  - capability: Opens on
    plugin: "Failures and slow responses"
    health_checks: "Failures, including timeouts"
  - capability: Re-enables the backend automatically
    plugin: "Yes, through half-open probes"
    health_checks: "Active checks"
{% endtable %}
<!--vale on-->

The two mechanisms are complementary.
Each has its own configuration, and you can use both.
If you load balance across multiple Targets, use health checks to route around an unhealthy Target.
Use the plugin to protect the Service as a whole.

The Circuit Breaker plugin reacts to failures and latency.
To limit request volume, use a rate limiting plugin like [Rate Limiting Advanced](/plugins/rate-limiting-advanced/).

## Limitations

* The plugin counts on each node separately.
  Each node keeps its own counters and circuit state, so one node can open its circuit while another stays closed.
* Redis and cluster strategies for sharing counters between nodes aren't available.
* `backend_connection_failure` and `backend_timeout` are aliases of `502` and `504` responses from {{site.base_gateway}}.
* The plugin fails open.
  On an internal error, it lets the request through and logs the error, so the Service keeps serving traffic.
