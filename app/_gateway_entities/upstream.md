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

description: An Upstream refers to the service applications sitting behind {{site.base_gateway}}, to which client requests are forwarded.

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

schema:
    api: gateway/admin-ee
    path: /schemas/Upstream
---

## What is an Upstream?

An Upstream refers to the service applications sitting behind {{site.base_gateway}}, to which client requests are forwarded. In {{site.base_gateway}}, an Upstream represents a virtual hostname and can be used to [health check](https://docs.konghq.com/gateway/latest/how-kong-works/health-checks/#active-health-checks), [circuit break](https://docs.konghq.com/gateway/latest/how-kong-works/health-checks/#passive-health-checks-circuit-breakers), and [load balance](#load-balancing-algorithms) incoming requests over multiple [Gateway Services](/gateway/entities/service/). In addition, the Upstream entity has more advanced functionality algorithms like least-connections, consistent-hashing, and lowest-latency.

## Upstream and Gateway Service interaction

You can configure a Service to point to an Upstream instead of a host.
For example, if you have a Service called `example_service` and an Upstream called `example_upstream`, you can point `example_service` to `example_upstream` instead of specifying a host.
The `example_upstream` Upstream can then point to two different [Targets](/gateway/entities/target/): `httpbin.konghq.com` and `httpbun.com`.
In a real environment, the Upstream points to the same Service running on multiple systems.

This setup allows you to load balance between upstream targets.
For example, if an application is deployed across two different servers or upstream targets, {{site.base_gateway}} needs to load balance across both servers.
If one of the servers (like `httpbin.konghq.com` in the previous example) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`).

The following diagram shows how Upstreams interact with other {{site.base_gateway}} entities:

{% include entities/upstreams-targets-diagram.md %}

## Use cases for Upstreams

The following are examples of common use cases for Upstreams:

| Use case      | Description                                                                                                                                                                                                                                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Load balance  | When an Upstream points to multiple upstream targets, you can configure the Upstream entity to load balance traffic between the targets. If you don't need to load balance, we recommend using the `host` header on a [Route](/gateway/entities/route/) as the preferred method for routing a request and proxying traffic. |
| Health check  | Configure Upstreams to dynamically mark a target as healthy or unhealthy. This is an active check where a specific HTTP or HTTPS endpoint in the target is periodically requested and the health of the target is determined based on its response.                                                                         |
| Circuit break | Configure Upstreams to allow {{site.base_gateway}} to passively analyze the ongoing traffic being proxied and determine the health of targets based on their behavior responding to requests. <br><br>**Note:** This feature is not supported in hybrid mode.                                                               |

## Load balancing algorithms

The load balancer supports the following load-balancing algorithms:

- `round-robin`
- `consistent-hashing`
- `least-connections`
- `latency`

### Round-Robin

The round-robin algorithm will be done in a weighted manner. It will be identical
in results to the DNS based load-balancing, but due to it being an `upstream`
the additional features for health-checks and circuit-breakers will be available
in this case.

When choosing this algorithm, consider the following:

- good distribution of requests.
- fairly static, as only DNS updates or `target` updates can influence the
  distribution of traffic.
- does not improve cache-hit ratios.

### Consistent-Hashing

With the consistent-hashing algorithm a configurable client-input will be used to
calculate a hash-value. This hash-value will then be tied to a specific backend
server.

A common example would be to use the `consumer` as a hash-input. Since this ID is
the same for every request from that user, it will ensure that the same user will
consistently be dealt with by the same backend server. This will allow for cache
optimizations on the backend, since each of the servers only serves a fixed subset
of the users, and hence can improve its cache-hit-ratio for user related data.

This algorithm implements the [ketama principle](https://github.com/RJ/ketama) to
maximize hashing stability and minimize consistency loss upon changes to the list
of known backends.

When using the `consistent-hashing` algorithm, the input for the hash can be either
`none`, `consumer`, `ip`, `header`, or `cookie`. When set to `none`, the
`round-robin` scheme will be used, and hashing will be disabled. The `consistent-hashing`
algorithm supports a primary and a fallback hashing attribute; in case the primary
fails (e.g., if the primary is set to `consumer`, but no Consumer is authenticated),
the fallback attribute is used. This maximizes upstream cache hits.

Supported hashing attributes are:

- `none`: Do not use `consistent-hashing`; use `round-robin` instead (default).
- `consumer`: Use the Consumer ID as the hash input. If no Consumer ID is available,
  it will fall back on the Credential ID (for example, in case of an external authentication mechanism like LDAP).
- `ip`: Use the originating IP address as the hash input. Review the configuration
  settings for [determining the real IP][real-ip-config] when using this.
- `header`: Use a specified header as the hash input. The header name is
  specified in either `hash_on_header` or `hash_fallback_header`, depending on whether
  `header` is a primary or fallback attribute, respectively.
- `cookie`: Use a specified cookie with a specified path as the hash input.
  The cookie name is specified in the `hash_on_cookie` field and the path is
  specified in the `hash_on_cookie_path` field. If the specified cookie is not
  present in the request, it will be set by the response. Hence, the `hash_fallback`
  setting is invalid if `cookie` is the primary hashing mechanism.
  The generated cookie will have a random UUID value. So the first assignment will
  be random, but then sticks because it is preserved in the cookie.

The consistent-hashing balancer is designed to work both with a single node as well
as in a cluster.

When choosing this algorithm, consider the following:

- improves backend cache-hit ratios.
- requires enough cardinality in the hash-inputs to distribute evenly (for example, hashing on
  a header that only has 2 possible values does not make sense).
- the cookie based approach will work well for browser based requests, but less so
  for machine-2-machine clients which will often omit the cookie.
- avoid using hostnames in the balancer as the
  balancers might/will slowly diverge because the DNS ttl has only second precision
  and renewal is determined by when a name is actually requested. On top of this is
  the issue with some nameservers not returning all entries, which exacerbates
  this problem. So when using the hashing approach in a Kong cluster, preferably add
  `target` entities by their IP address. This problem can be mitigated by balancer
  rebuilds and higher ttl settings.

### Least-Connections

This algorithm keeps track of the number of in-flight requests for each backend.
The weights are used to calculate "connection-capacity" of a backend. Requests are
routed towards the backend with the highest spare capacity.

When choosing this algorithm, consider the following:

- good distribution of traffic.
- does not improve cache-hit ratio's.
- more dynamic since slower backends will have more connections open, and hence
  new requests will be routed to other backends automatically.

### Latency

The `latency` algorithm is based on peak EWMA (exponentially weighted moving average),
which ensures that the balancer selects the backend by lowest latency
(`upstream_response_time`). The latency metric used is the full request cycle, from
TCP connect to body response time. Since it is a moving average, the metrics will
"decay" over time.

Weights will not be taken into account.

When choosing this algorithm, consider the following:

- good distribution of traffic provided there is enough base-load to keep the
  metrics alive, since they are "decaying".
- not suitable for long-lived connections like websockets or server-sent events (SSE)
- very dynamic since it will constantly optimize.
- ideally, this works best with low variance in latencies. This means mostly similar
  shaped traffic and even workloads for the backends. For example, usage
  with a GraphQL backend serving small-fast queries as well big-slow ones will result
  in high variance in the latency metrics, which will skew the metrics.
- properly set up the backend capacity and ensure proper network latency to prevent
  resource starvation. For example, use 2 servers: one a small capacity close by (low
  network latency), the other high capacity far away (high latency). Most traffic
  will be routed to the small one, until its latency starts going up. The latency
  going up however means the small server is most likely suffering from resource
  starvation. So, in this case, the algorithm will keep the small server in a constant
  state of resource starvation, which is most likely not efficient.

## Schema

{% entity_schema %}

## Set up an Upstream

{% entity_example %}
type: upstream
data:
  name: example-upstream
  algorithm: round-robin
{% endentity_example %}
