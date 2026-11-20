---
title: Mesh Fault Injection
name: MeshFaultInjections
products:
- mesh
description: Inject failures, delays and bandwidth limits into traffic a proxy receives, to test how callers cope.
content_type: plugin
icon: meshfaultinjection.png
related_resources:
- text: Policy targeting
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshfaultinjection"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
---

The `MeshFaultInjection` policy makes a destination proxy reject HTTP requests, delay them,
or slow down their responses. Use this policy to test how callers handle failures without
changing the destination application. For example, check that:

* A caller's [MeshRetry](/mesh/policies/meshretry/) rules fire on the statuses you expect.
* Its [MeshTimeout](/mesh/policies/meshtimeout/) values are shorter than an injected delay.
* [MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) outlier detection ejects endpoints
  that return repeated errors.

Requests that no fault-injection rule matches get no faults. The policy doesn't simulate a
process crash or a network outage, so the destination proxy must still be running and
receiving the test traffic.

{:.warning}
> Faults affect real requests. Start with a test destination or a specific caller, record
> normal behavior before applying the policy, and remove the experiment when the test ends.
> A rule without a client match affects every caller of the selected destination.

## Fail a proportion of requests

The following example makes proxies labeled `app: backend` return 503 to a tenth of the
requests they receive:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshFaultInjection
mesh: default
name: backend-abort
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        http:
          - abort:
              httpStatus: 503
              percentage: 10
```
{% endpolicy_yaml %}

What each field does:

* `targetRef` selects the destination proxies that inject the fault, not the callers you're
  testing: `Mesh`, or `Dataplane` with `labels`.
* `rules` holds the faults and optional caller matches. This rule has no caller match, so it
  applies to every request the proxies receive.
* `abort` returns `httpStatus: 503` to about one request in ten, without sending it to the
  application.

## Listeners and protocols

To apply the policy to one inbound, set the policy's `spec.targetRef.sectionName` to the
inbound's `name` from the destination `Dataplane`'s `spec.networking.inbound[]`, or to its port as
a string if it doesn't have a name. Without `sectionName`, the policy covers all eligible inbounds. Zone-proxy
listeners can also use `rules` with `sectionName` set to the listener name.

Faults require an HTTP, HTTP/2, or gRPC listener. They have no effect on traffic handled as
plain TCP, even if the application sends HTTP over it. For more information, see
[Universal inbound protocols](/mesh/migrate-policies-to-3/#required-protocol-on-universal-inbounds).

## The three faults

A rule holds a list of faults under `http`, and each entry can set any combination of
`abort`, `delay`, and `responseBandwidth`. Every fault takes a `percentage` from 0.0 to
100.0. You must wrap fractional values in quotes, for example: `"2.5"`.

`http` accepts the following faults:

{% table %}
columns:
  - title: Fault
    key: fault
  - title: Effect
    key: effect
  - title: Fields
    key: fields
rows:
  - fault: "`abort`"
    effect: "The proxy answers with the given status and doesn't deliver the request."
    fields: "`httpStatus` (100 to 599) and `percentage`."
  - fault: "`delay`"
    effect: "The proxy waits before forwarding the request, on top of the application's processing time."
    fields: "`value` (a duration with a unit, such as `500ms`, `5s`, or `1m30s`) and `percentage`."
  - fault: "`responseBandwidth`"
    effect: "The proxy limits the transfer rate of each selected response, not the destination's total bandwidth."
    fields: "`limit` (a whole number in `Gbps`, `Mbps`, or `kbps`, such as `50kbps`) and `percentage`."
{% endtable %}

## Fault order

Entries in one `http` list run in order. An abort stops the request, so later entries only
see requests that weren't aborted. A delay doesn't stop the request, so it can still hit a
later delay or abort.

The following example aborts about 85% of requests, when placed under `rules[].default`:

```yaml
http:
  - abort:
      httpStatus: 500
      percentage: 70
  - abort:
      httpStatus: 503
      percentage: 50
```

About 70% of requests get a 500. Half of the remaining 30% get a 503, which is about 15% of
all requests. The other 15% reach the application. Moving a fault to the front of the list
changes how many requests the later ones see.

## Delay requests from one workload identity

A rule that matches `spiffeID` injects faults only for requests from those clients, so other
callers of a shared destination aren't affected. The following example delays half of the
requests from the `frontend` service account by 5 seconds:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshFaultInjection
mesh: default
name: backend-fault-frontend-only
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - matches:
        - spiffeID:
            type: Exact
            value: spiffe://default.default.mesh.local/ns/kong-mesh-demo/sa/frontend
      default:
        http:
          - delay:
              value: 5s
              percentage: 50
```
{% endpolicy_yaml %}

Copy the full SPIFFE URI from the frontend workload's certificate into
`rules[].matches[].spiffeID.value`. The example uses the default Kubernetes identity path. A
custom [MeshIdentity](/mesh/policies/meshidentity/) template can change the trust domain and
path. Several frontend replicas can share this service-account identity, so the match doesn't
select a single process.

The destination must authenticate the identity through mesh mTLS, because plaintext traffic
has no identity to match. The rule doesn't grant access:
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) must also allow the caller.

## Overlapping policies

Matching rules add their faults together. A narrower rule doesn't replace a broader rule's
faults. For example, if one rule delays all callers and another aborts requests from
`frontend`, frontend requests are eligible for both. A request that's aborted doesn't reach
the faults after it.

Setting a fault's `percentage` to `0` disables only that fault, not faults in other matching
rules or policies. To stop an experiment for a caller, remove or narrow every rule that
includes it. To attribute a result to one fault, don't overlap experiments.

## Validating the injected failure

1. Before applying the policy, confirm that the caller can reach the destination, record the
   normal status and latency, and check for other fault-injection policies on the same traffic.
1. Send enough requests to observe the configured percentage. Count attempts at the destination
   proxy, not only completed calls, because client retries can hide injected failures.
1. For `abort`, confirm that the client gets the configured status and the application doesn't
   receive those requests.
1. For `delay`, confirm that client-observed latency matches `delay.value` and any applicable
   `MeshTimeout`.
1. For `responseBandwidth`, confirm the transfer rate with a response large enough to show the
   limit.
1. If a rule matches `spiffeID`, confirm that a client that doesn't match gets no fault from it.
1. Remove the test policy and confirm that the baseline requests succeed again. If faults
   remain, check for another matching policy.

To tell injected faults from application errors, inspect the destination proxy's Envoy
counters ending in:

* `fault.aborts_injected`
* `fault.delays_injected`
* `fault.response_rl_injected`

For more information, see
[Envoy fault-injection statistics](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/fault_filter#statistics).

{% table %}
columns:
  - title: Unexpected result
    key: unexpected
  - title: Check
    key: check
rows:
  - unexpected: "No delay is visible"
    check: "The inbound protocol, the caller identity, and the effective fault configuration."
  - unexpected: "The caller gets a timeout instead of a slow response"
    check: "The caller's timeout is shorter than the delay."
  - unexpected: "Aborts appear in proxy counters but not in the caller's final status"
    check: "The caller's retry policy and attempt count."
{% endtable %}
