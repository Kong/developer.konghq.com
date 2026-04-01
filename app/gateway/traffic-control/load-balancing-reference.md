---
title: "Load balancing in {{site.base_gateway}} reference"

description: "Learn how to load balance requests to upstream services with {{site.base_gateway}}"

content_type: reference

layout: reference

products:
  - gateway

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Target entity
    url: /gateway/entities/target/
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/
  - text: Configure blue-green deployments
    url: /gateway/traffic-control/blue-green-deployments/
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/

breadcrumbs:
  - /gateway/


tags:
    - load-balancing
---

{{site.base_gateway}} provides multiple ways of load balancing requests to upstream services:
* The default DNS-based method, which uses [Gateway Service](/gateway/entities/service/) hostname information.
The DNS load balancer is enabled by default and is limited to round-robin load balancing.
* An advanced set of load balancing algorithms using the [Upstream](/gateway/entities/upstream/) entity, which comes with four configurable load balancing algorithms.
The Upstream entity can also dynamically adjust connections to [Targets](/gateway/entities/target/) using [health checks and circuit breakers](/gateway/traffic-control/health-checks-circuit-breakers/).

## DNS-based load balancing

Every [Gateway Service](/gateway/entities/service/) defined with a `host` containing a hostname that resolves to multiple IP addresses automatically uses DNS-based load balancing.
If there are no Upstreams or Targets defined for a Gateway Service, {{site.base_gateway}} also falls back to this method.

By default, and with no Upstreams configured, {{site.base_gateway}} uses round-robin load balancing.
The type of algorithm used depends on the hostname's DNS record type:
* **A records**: unweighted round-robin
* **SRV records**: weighted round-robin

The DNS record `ttl` setting (time to live) determines how often the information is refreshed.
When using a `ttl` of 0, every request is resolved using its own DNS query.
This has a performance penalty, but the latency of updates is very low.

### A records

An A record contains one or more IP addresses.
When a hostname resolves to an A record, each upstream service must have its own IP address.

Because there is no `weight` information, all entries are treated as equally weighted in the load balancer, and the balancer uses a straightforward round-robin to distribute traffic across IP addresses.

### SRV records

An SRV record contains weight and port information for each of its IP addresses.
An upstream service can be identified by a unique combination of IP address and port number, so a single IP address can host multiple instances of the same service on different ports.

SRV records also feature a `priority` property.
{{site.base_gateway}} will only use the entries with the highest priority (lowest priority value), and ignore all others.

Because the `weight` information is available, each entry gets its own weight in the load balancer and the load balancer performs a weighted round-robin.

Similarly, any given port information is overridden by the port information from the DNS server.
For example, if a Gateway Service has the attributes `host=myhost.com` and `port=123`, and `myhost.com` resolves to an SRV record with `127.0.0.1:456`, then the request will be proxied to `http://127.0.0.1:456/somepath`, as port `123` will be overridden by `456`.

### DNS load balancing caveats

* {{site.base_gateway}} trusts the nameserver.
This means that information retrieved via a DNS query has higher precedence than the configured values.
This mostly relates to SRV records which carry `port` and `weight` information.

* Whenever the DNS record is refreshed, a list is generated to handle the weighting properly.
Try to keep the weights as multiples of each other to keep the algorithm performant.
For example, the weights 16 and 32 have the lowest common denominators of 1 and 2, which results in a structure of only 3 entries.
This is especially relevant with a very small (or even 0) `ttl` value.

* DNS is carried over UDP with a default limit of 512 Bytes.
If there are many entries to be returned, a DNS server responds with partial data and sets a truncate flag, indicating there are more entries unsent.
DNS clients, including {{site.base_gateway}}, then make a second request over TCP to retrieve the full list of entries.
  * By default, some nameservers don't respond with the truncate flag, but trim the response
to be under 512 byte UDP size.
  * If a deployed nameserver doesn't provide the truncate flag, the pool of upstream instances might be loaded inconsistently.
  The {{site.base_gateway}} node is effectively unaware of some of the instances, due to the limited information provided by the nameserver.
  To mitigate this, use a different nameserver, use IP addresses instead of names, or make sure you use enough {{site.base_gateway}} nodes to still keep all upstream services in use.

* When the nameserver returns a `3 name error`, then that is a valid response for {{site.base_gateway}}.
If this is unexpected, validate the correct name is being queried for, then check your nameserver configuration.

* The initial pick of an IP address from a DNS record (A or SRV) is based on the order in which they were originally returned by the DNS server.
When using records with a `ttl` of 0, the nameserver is expected to randomize the record entries.

## Load balancing using Upstreams and Targets

You can use a combination of [Upstream](/gateway/entities/upstream/) and [Target](/gateway/entities/target/) entities to configure advanced load balancing algorithms.

* **Upstream**: A virtual hostname, which can be used in a Gateway Service `host` field.
  For example, an Upstream named `weather.v2.service` would get all requests from a Service with the configuration `host=weather.v2.service`.
  The Upstream carries the properties that determine load balancing and health checking behaviour.

* **Target**: An IP address or hostname with a port number where an upstream service resides.
  For example, `192.168.100.12:80`.

  Each Upstream can have many Targets attached to it, and requests proxied to the virtual hostname are load-balanced over the targets.
  Each Target gets an additional `weight` to indicate the relative load that it gets.

When using advanced load balancers, {{site.base_gateway}} handles the adding and removing of upstream services through Targets.
No DNS updates are necessary, as {{site.base_gateway}} acts as the service registry.

Adding and removing Targets is a relatively cheap operation.
Changing the Upstream itself is more expensive, as the balancer needs to be rebuilt when Upstream configuration changes, such as when the number of slots increases.

Targets are automatically cleaned when there are 10x more inactive entries than active ones.
Cleaning involves rebuilding the balancer, and is more expensive than just adding a Target entry.

### Load balancing algorithms

{{site.base_gateway}} supports the following load balancing algorithms:

<!--vale off-->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Description
    key: description
rows:
  - algorithm: "[Round-robin](/gateway/entities/upstream/#round-robin)"
    description: The round-robin algorithm is done in a weighted manner. It provides identical results to the default DNS based load balancing, and also gives you access to active and passive health checks.
  - algorithm: "[Consistent-hashing](/gateway/entities/upstream/#consistent-hashing)"
    description: With the consistent-hashing algorithm, a configurable client input is used to calculate a hash value. This hash value is then tied to a specific upstream service.
  - algorithm: "[Least-connections](/gateway/entities/upstream/#least-connections)"
    description: The least-connections algorithm keeps track of the number of in-flight requests for each upstream service. The weights are used to calculate the connection capacity of an upstream service. Requests are routed to the upstream service with the highest spare capacity.
  - algorithm: "[Latency](/gateway/entities/upstream/#latency)"
    description: The latency algorithm is based on the peak EWMA (Exponentially Weighted Moving Average), which ensures that the balancer selects the upstream service by the lowest latency.
  - algorithm: "[Sticky-sessions](/gateway/entities/upstream/#sticky-sessions)"
    description: {% new_in 3.11 %} Repeated requests are routed from the same client to the same upstream Target using a browser-managed cookie, which ensures session persistence even during Target shutdowns or draining.
{% endtable %}
<!--vale on-->


## Conflicts between load balancers

In orchestrated environments like Kubernetes or docker-compose, Target IP addresses and ports are mostly ephemeral and SRV records must be used to find the appropriate upstream services and to stay up to date.

On a DNS level, many infrastructure tools can also provide load balancing functionality.
These are mostly service-discovery tools that have their own health checks and will randomize DNS records, or only return a small subset of available peers.

The {{site.base_gateway}} load balancers and the external DNS-based tools often fight each other.
The nameserver provides as little information as possible to force clients to follow its scheme, while {{site.base_gateway}} tries to get all upstream services to properly set up its load balancers and health checks.

To avoid conflicts in your environment, ensure that:

* The nameserver sets the truncation flag on the responses when it can't fit all records in the UDP response.
This forces {{site.base_gateway}} to retry using TCP.
* TCP queries are allowed on the nameserver.
