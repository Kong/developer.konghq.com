---
title: Mesh Fault Injection
name: MeshFaultInjections
products:
- mesh
description: Inject failures, delays and bandwidth limits into traffic a proxy receives, to test how callers cope.
content_type: plugin
icon: meshfaultinjection.png
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshfaultinjection"
- text: MeshRetry policy
  url: "/mesh/policies/meshretry/"
- text: MeshTimeout policy
  url: "/mesh/policies/meshtimeout/"
---

`MeshFaultInjection` makes a destination proxy reject HTTP requests, delay forwarding them,
or slow down their responses. Use it to test how callers handle failures without changing
the destination application.

Use it to check that a caller's [MeshRetry](/mesh/policies/meshretry/) rules fire on the
statuses you expect, that its [MeshTimeout](/mesh/policies/meshtimeout/) values are shorter
than an injected delay, and that
[MeshCircuitBreaker](/mesh/policies/meshcircuitbreaker/) outlier detection ejects endpoints
that return repeated errors when configured to do so.

Without a matching fault-injection rule, this policy introduces no faults. It does not
simulate a process crash or a network outage: the destination proxy must still be running
and receiving the test traffic.

{:.warning}
> Faults affect real requests. Start with a test destination or a specific caller, record
> normal behavior before applying the policy, and remove the experiment when the test ends.
> A rule without a client match affects every caller of the selected destination.

## Fail a proportion of requests

This policy applies to proxies labeled `app: backend`, and returns 503 to a tenth of the
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

`targetRef` selects the `backend` proxies that manufacture the fault. The rule has no client
matcher, so it considers every request those proxies receive. `percentage: 10` selects roughly
one request in ten, and `httpStatus: 503` is returned without sending that request to the
application.

## Where this policy applies

`spec.targetRef` selects the proxies that receive traffic and inject faults. It accepts
`Mesh` or `Dataplane`; use `Dataplane` with `labels` to select a specific destination.
`spec.rules[]` contains the faults and optional caller matches. The policy belongs on the
destination, not on the caller whose resilience you are testing.

To affect one inbound, set `targetRef.sectionName` to its `name` in the destination
Dataplane's `spec.networking.inbound[]`. For an unnamed inbound, use its port as a string,
such as `"8080"`. Without `sectionName`, the policy covers the selected proxy's eligible
inbounds. Zone-proxy listeners can also use `rules`; select their listener name with
`sectionName`.

Faults require an HTTP, HTTP/2, or gRPC listener. They have no effect on traffic handled as
plain TCP, even if the application sends HTTP over that connection. Check the destination's
declared inbound protocol before testing. See
[Universal inbound protocols](/mesh/migrate-policies-to-3/#universal-inbounds-must-declare-their-protocol).

**`spec.to[]` is accepted only when `spec.targetRef.kind` is `Mesh`.** With
`kind: Dataplane`, defining `to` at all is rejected with `spec.to (): must not be defined`.
Where it is allowed, `to[].targetRef` accepts `kind: Mesh` and nothing else.

The v3 proxy implementation applies faults from `rules`, not `to`. When migrating an
existing `to` policy, select the receiving Dataplane and move the fault configuration into
`rules[].default`. Verify the intended listener before starting the experiment.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## The three faults

A rule holds a list of faults under `http`, and each entry may set any combination of
`abort`, `delay` and `responseBandwidth`. Every fault takes a `percentage`, in the range 0.0
to 100.0. A fractional value has to be quoted, as `"2.5"`.

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
    effect: "The request is not delivered, and the proxy answers with the status given."
    fields: "`httpStatus`, in the range 100 to 599, and `percentage`."
  - fault: "`delay`"
    effect: "The proxy waits before forwarding the request. Application processing takes additional time."
    fields: "`value`, a duration, and `percentage`."
  - fault: "`responseBandwidth`"
    effect: "The proxy limits the transfer rate of each selected response, not the destination's total bandwidth."
    fields: "`limit`, measured in `Gbps`, `Mbps`, `kbps` or `bps`, and `percentage`."
{% endtable %}

## Percentages compound down the list

Entries in one `http` list execute in the order written. An abort stops the request, so later
entries only see requests that earlier entries did not abort. For example, place this list
under `rules[].default`:

```yaml
http:
  - abort:
      httpStatus: 500
      percentage: 70
  - abort:
      httpStatus: 503
      percentage: 50
```

Approximately 70% of requests get a 500. Of the remaining 30%, half get a 503: about 15% of
all requests. The other 15% reach the application, assuming no other faults or failures.

Ordering matters for the same reason: moving a low-percentage fault to the front changes how
many requests the later ones see. A delay does not by itself remove a request from the list:
after waiting, the request can encounter another delay or an abort.

## When fault-injection rules overlap

Matching rules contribute faults; a narrower rule does not replace a broader rule's fault
list. For example, if one rule delays all callers and another aborts requests from
`frontend`, frontend requests are eligible for both. Requests aborted before reaching a
later fault do not experience that later fault.

Setting a fault's percentage to `0` disables that fault only. It does not exempt the caller
from faults in another matching rule or policy. To stop an experiment for a caller, remove
or narrow every fault rule that includes that caller. Avoid overlapping experiments when
you need to attribute a result to one fault.

## Delay requests from one workload identity

A rule matching on `spiffeID` injects faults only for requests from those clients, which
keeps a test from affecting every caller of a shared destination:

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

Copy the complete SPIFFE URI from the frontend workload's certificate into
`rules[].matches[].spiffeID.value`. The example assumes the default Kubernetes identity path;
a custom [MeshIdentity](/mesh/policies/meshidentity/) template can change both the trust
domain and path. This service-account identity can be shared by several frontend replicas,
so the match does not select a single process.

The destination must authenticate that identity through mesh mTLS. Plaintext traffic has no
certificate identity to match. This rule does not grant access: the caller must also be
allowed by [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/).

## Validate the injected failure

1. Confirm that the caller can reach the destination before applying the policy. Record the
   normal status and latency, and check for other fault-injection policies selecting the same traffic.
1. Send enough requests to observe the configured percentage; a small sample does not prove
   the distribution. Count attempts received by the destination proxy, not only completed
   application calls: client retries are new attempts and can hide injected failures.
1. For `abort`, confirm that the client receives the configured status and that the application
   did not receive those requests.
1. For `delay`, measure client-observed latency and compare it with `delay.value` and any
   applicable `MeshTimeout`.
1. For `responseBandwidth`, measure the response transfer rate with a response large enough for
   the limit to be visible.
1. When a rule matches `spiffeID`, repeat the request from a client that does not match and
   confirm that this rule does not inject a fault.
1. Remove the test policy and repeat the baseline requests. If faults remain, check for
   another matching policy before concluding that the application is failing.

For evidence from the destination proxy, inspect the Envoy counters ending in
`fault.aborts_injected`, `fault.delays_injected`, and `fault.response_rl_injected`.
These distinguish faults selected by the proxy from application errors. See
[Envoy fault-injection statistics](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/fault_filter#statistics).

If a delay is not visible, check the inbound protocol, caller identity, and effective fault
configuration. A caller timeout shorter than the delay produces a timeout instead of a
successful response with extra latency. If aborts appear in proxy counters but not in the
caller's final status, inspect its retry policy and attempt count.
