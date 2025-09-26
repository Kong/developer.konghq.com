---
title: Upstreams
content_type: reference
entities:
  - upstream

products:
  - gateway

tools:
    - admin-api
    - kic
    - deck
    - terraform
    - konnect-api

description: An Upstream enables load balancing by providing a virtual hostname and collection of Targets (upstream service instances).

related_resources:
  - text: Gateway Service entity
    url: /gateway/entities/service/
  - text: Route entity
    url: /gateway/entities/route/
  - text: Target entity
    url: /gateway/entities/target/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
  - text: Load balancing in {{site.base_gateway}}
    url: /gateway/load-balancing/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway-manager/control-plane-resource-limits/

schema:
    api: gateway/admin-ee
    path: /schemas/Upstream

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

works_on:
  - on-prem
  - konnect
faqs:
  - q: With the `sticky-sessions` algorithm does the cookie expire?
    a: No, they are session cookies and expire with the client session.

  - q: Where is the`sticky-sessions` cookie stored?
    a: |
      On the client. {{site.base_gateway}} does not store cookie values server-side. 
      The browser (or user agent) is responsible for storing and submitting the cookie automatically.

  - q: What happens if the sticky target is removed?
    a: A new Target is selected and a new cookie is generated.

  - q: What happens if two upstreams use the same cookie name and path?
    a: |
      If the upstreams share the same Target, the client will continue routing to it.
      Otherwise, the cookie will be overwritten and routing will begin to a new Target.

  - q: How does `sticky-sessions` differ from consistent hashing?
    a: |
      Sticky sessions use a client-side cookie to maintain affinity with a specific Target,
      ensuring consistent routing even if Targets change. Consistent hashing relies on hash inputs
      (like IP or header values) and can re-balance if Targets are added or removed, without guaranteeing session stickiness.

---

## What is an Upstream?

An Upstream enables load balancing by providing a virtual hostname and collection of [Targets](/gateway/entities/target/), or upstream service instances, to which client requests are forwarded.

You can use Upstreams to [health check](/gateway/traffic-control/health-checks-circuit-breakers/#active-health-checks), [circuit break](/gateway/traffic-control/health-checks-circuit-breakers/#passive-health-checks-circuit-breakers), and [load balance](#load-balancing-algorithms) incoming requests over multiple [Gateway Services](/gateway/entities/service/). In addition, the Upstream entity has more advanced functionality algorithms like least-connections, consistent-hashing, and lowest-latency.

## Upstream and Gateway Service interaction

You can configure a Service to point to an Upstream instead of a host.
For example, if you have a Service called `example_service` and an Upstream called `example_upstream`, you can point `example_service` to `example_upstream` instead of specifying a host.
The `example_upstream` Upstream can then point to two different [Targets](/gateway/entities/target/): `httpbin.konghq.com` and `httpbun.com`.
In a real environment, the Upstream points to the same Service running on multiple systems.

This setup allows you to load balance between upstream targets.
For example, if a upstream service is deployed across two different servers or upstream targets, {{site.base_gateway}} needs to load balance across both servers.
If one of the servers (like `httpbin.konghq.com` in the previous example) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`).

The following diagram shows how Upstreams interact with other {{site.base_gateway}} entities:

{% include entities/upstreams-targets-diagram.md %}

## Use cases for Upstreams

The following are examples of common use cases for Upstreams:
<!--vale off -->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Load balance](#load-balancing-algorithms)"
    description: | 
      When an Upstream points to multiple upstream targets, you can configure the Upstream entity to load balance traffic between the targets. If you don't need to load balance, we recommend using the `host` header on a [Route](/gateway/entities/route/) as the preferred method for routing a request and proxying traffic.
  - use_case: "[Health check](/gateway/traffic-control/health-checks-circuit-breakers/#active-health-checks)"
    description: |
      Configure Upstreams to dynamically mark a target as healthy or unhealthy. This is an active check where a specific HTTP or HTTPS endpoint in the target is periodically requested and the health of the target is determined based on its response.
  - use_case: "[Circuit break](/gateway/traffic-control/health-checks-circuit-breakers/#passive-health-checks-circuit-breakers)"
    description: |
      Configure Upstreams to allow {{site.base_gateway}} to passively analyze the ongoing traffic being proxied and determine the health of targets based on their behavior responding to requests. **This feature is not supported in {{site.konnect_short_name}} or hybrid mode.**
{% endtable %}
<!--vale on -->
## Load balancing algorithms

The load balancer supports the following [load balancing algorithms](/gateway/load-balancing/):

- `round-robin`
- `consistent-hashing`
- `least-connections`
- `latency`
- `sticky-sessions` {% new_in 3.11 %}

{:.info}
> **Note**: If using [health checks](/gateway/traffic-control/health-checks-circuit-breakers/), unhealthy Targets won't be removed from the load balancer, and won't have any impact on the balancer layout when using a hashing algorithm. 
Instead, unhealthy Targets will just be skipped.

### Round-robin

The round-robin algorithm is done in a weighted manner. It provides identical
results to the default DNS based load balancing, but due to it being an `upstream`,
the additional features for health checks and circuit breakers are also available.

When choosing this algorithm, consider the following:

- Provides good distribution of requests.
- Remains fairly static, as only DNS updates or Target updates can influence the distribution of traffic.
- Doesn't improve cache-hit ratios.

### Consistent-hashing

With the consistent-hashing algorithm, a configurable client input is used to
calculate a hash value. This hash value is then tied to a specific backend
server.

A common example would be to use the `consumer` as a hash input. Since this ID is
the same for every request from that user, it ensures that the same user is
handled consistently by the same backend server. This allows for cache
optimizations on the backend, since each of the servers only serves a fixed subset
of the users, and can improve its cache-hit ratio for user-related data.

This algorithm implements the [ketama principle](https://github.com/RJ/ketama) to
maximize hashing stability and minimize consistency loss upon changes to the list
of known backends.

The input for the consistent-hashing algorithm can be one of the following options, 
determined by the value set in the `hash_on` parameter:

<!--vale off-->
{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`none`"
    description: "Doesn't use `consistent-hashing`, uses `round-robin` instead (default). Hashing is disabled."
  - option: "`consumer`"
    description: |
      Uses the Consumer ID as the hash input. If no Consumer ID is available, it will fall back on the Credential ID (for example, in case of an external authentication mechanism like LDAP).
  - option: "`ip`"
    description: |
      Uses the originating IP address as the hash input. Review the configuration settings for [determining the real IP](/gateway/configuration/#real-ip-config) when using this option.
  - option: "`header`"
    description: |
      Uses a specified header as the hash input. The header name is specified in either of the Upstream's `hash_on_header` or `hash_fallback_header` fields, depending on whether `header` is a primary or fallback attribute, respectively.
  - option: "`cookie`"
    description: |
      Use a specified cookie with a specified path as the hash input. The cookie name is specified in the Upstream's `hash_on_cookie` field and the path is specified in the Upstream's `hash_on_cookie_path` field. If the specified cookie is not present in the request, it will be set by the response. The generated cookie will have a random UUID value, which is then preserved in the cookie. 
      <br><br> 
      The `hash_fallback` setting is invalid and can't be used if `cookie` is the primary hashing mechanism.
{% endtable %}
<!--vale on-->

The `consistent-hashing` algorithm supports a primary and a fallback hashing attribute. 
If the primary fails (for example, if the primary is set to `consumer`, but no Consumer is authenticated),
the fallback attribute is used. This maximizes upstream cache hits.

The consistent-hashing balancer is designed to work both with a single node as well
as in a cluster.

When choosing this algorithm, consider the following:

- Improves backend cache-hit ratios.
- Requires enough cardinality in the hash inputs to distribute evenly. For example, hashing on a header that only has 2 possible values doesn't make sense.
- The cookie-based approach works well for browser-based requests, but less so for machine-to-machine (M2M) clients, which will often omit the cookie.
- When using the hashing approach in a {{site.base_gateway}} cluster, add Target entities by their IP address, and avoid using hostnames in the balancer.
  The balancers will slowly diverge, as the DNS TTL only has second precision, and renewal is determined by when a name is actually requested. 
  Additionally, some nameservers don't return all entries, which makes the problem worse.
  This problem can be mitigated by balancer rebuilds and higher TTL settings.

### Least-connections

The `least-connections` algorithm keeps track of the number of in-flight requests for each backend.
The weights are used to calculate the connection capacity of a backend. Requests are
routed towards the backend with the highest spare capacity.

When choosing this algorithm, consider the following:

- Provides good distribution of traffic.
- Doesn't improve cache-hit ratios.
- This option is more dynamic, since slower backends will have more connections open, and
  new requests will be routed to other backends automatically.

### Latency

The `latency` algorithm is based on peak EWMA (Exponentially Weighted Moving Average),
which ensures that the balancer selects the backend by the lowest latency
(`upstream_response_time`). The latency metric used is the full request cycle, from
TCP connect to body response time. Since it's a moving average, the metrics will
decay over time.

Target weights aren't taken into account.

When choosing this algorithm, consider the following:

- Provides good distribution of traffic, provided there is enough base load to keep the metrics alive, since they are always decaying.
- The algorithm is very dynamic, since it will constantly optimize loads.
- Latency-based load balancing works best with low variance in latencies, meaning mostly similar-shaped traffic and even workloads for the backends. 
  For example, using this algorithm with a GraphQL backend serving small-fast queries as well big-slow ones will result in high variance in the latency metrics, which will skew the metrics.
- You must properly set up the backend capacity and ensure proper network latency to prevent resource starvation. 
  For example, you could use 2 servers: a small capacity server close by (low network latency), and a high capacity server far away (high latency). 
  Most traffic will be routed to the small one until its latency starts going up. 
  However, the latency going up means the small server is likely suffering from resource starvation. 
  In this case, the algorithm will keep the small server in a constant state of resource starvation, which is most likely not efficient.
- This option is not suitable for long-lived connections like websockets or server-sent events (SSE).


### Sticky sessions {% new_in 3.11 %}

Sticky sessions allow {{site.base_gateway}} to route repeat requests from the same client to the same backend Target using a browser-managed cookie.

When a request is proxied through an Upstream using the `sticky-sessions` algorithm, {{site.base_gateway}} sets a cookie on the response (via the `Set-Cookie` header). On subsequent requests, if the cookie is still valid and the original Target is available, traffic is routed to that same Target.

This mechanism is useful for session persistence, graceful shutdowns, and applications requiring connection affinity.

When choosing this algorithm, consider the following:

- Provides session persistence via browser-managed cookies.
- Continues routing traffic to pods that are shutting down or in a `NotReady` state until they are removed entirely.
- Ideal for applications requiring sticky behavior even as Targets drain or terminate.
- May cause uneven load if some clients maintain long sessions tied to specific Targets.

The cookie settings can be customized per Upstream:

```json
{
  "name": "sticky",
  "algorithm": "sticky-sessions",
  "hash_on": "none",
  "hash_fallback": "none",
  "sticky_sessions_cookie": "gruber",
  "sticky_sessions_cookie_path": "/"
}
```

#### Sticky sessions vs consistent hashing

The following table describes how sticky sessions differ from consistent hashing:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Sticky sessions
    key: sticky
  - title: Consistent hashing
    key: hashing
rows:
  - feature: "Session Affinity"
    sticky: "Enforced via cookie."
    hashing: "Dependent on hash input (e.g. IP or header). No persistence if Targets change"
  - feature: "Target Removal Handling"
    sticky: "Picks a new Target if the original is removed."
    hashing: "Minimally adjusts based on available Targets."
  - feature: "Load Distribution"
    sticky: "May be uneven with long-lived sessions."
    hashing: "Designed for even distribution."
  - feature: "Pod Draining Support"
    sticky: "Continues routing to NotReady or terminating pods."
    hashing: "Avoids routing to unhealthy or terminating pods."
{% endtable %}

### Managing failover Targets {% new_in 3.12 %}

{% include_cached /gateway/failover-targets.md %}

## Schema

{% entity_schema %}

## Set up an Upstream

{% entity_example %}
type: upstream
data:
  name: example-upstream
  algorithm: round-robin
{% endentity_example %}
