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

description: An upstream refers to the service applications sitting behind {{site.base_gateway}}, to which client requests are forwarded.

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
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxy/

schema:
    api: gateway/admin-ee
    path: /schemas/Upstream
---

## What is an Upstream?

{{page.description}} In {{site.base_gateway}}, an Upstream represents a virtual hostname and can be used to [health check, circuit break]<!--TODO link concept-->, and [load balance]<!--TODO link concept--> incoming requests over multiple [Gateway Services](/gateway/entities/service/). In addition, the Upstream entity has more advanced functionality algorithms like least-connections, consistent-hashing, and lowest-latency.

If you don't need to load balance, we recommend using the `host` header on a [Route](/gateway/entities/route/) as the preferred method for routing a request and proxying traffic.

## Upstream and Service interaction

You can configure a Service to point to an Upstream instead of a host. 
For example, if you have a Service called `example_service` and an Upstream called `example_upstream`, you can point `example_service` to `example_upstream` instead of specifying a host. 
The `example_upstream` Upstream can then point to two different [Targets](/gateway/entities/target/): `httpbin.konghq.com` and `httpbun.com`. 
In a real environment, the Upstream points to the same Service running on multiple systems.

This setup allows you to load balance between upstream targets. 
For example, if an application is deployed across two different servers or upstream targets, {{site.base_gateway}} needs to load balance across both servers. 
If one of the servers (like `httpbin.konghq.com` in the previous example) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`). 

The following diagram shows how Upstreams interact with other {{site.base_gateway}} entities:

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Service
  (example-service)`")
  D(Upstream 
  application)
  
  A <--requests
  responses--> B
  subgraph id1 ["`
  **KONG GATEWAY**`"]
    B <--requests
    responses--> C
  end
  C <--requests
  responses--> D

  style id1 rx:10,ry:10
  
{% endmermaid %}

## Use cases for Upstreams

The following are examples of common use cases for Upstreams:

* **Load balance:<!--TODO link how-to-->** When an Upstream points to multiple upstream targets, you can configure the Upstream entity to load balance traffic between the targets.
* **Health check:<!--TODO link how-to-->** Configure Upstreams to dynamically mark a target as healthy or unhealthy. This is an active check where a specific HTTP or HTTPS endpoint in the target is periodically requested and the health of the target is determined based on its response. 
* **Circuit break:<!--TODO link how-to-->** Configure Upstreams to allow {{site.base_gateway}} to passively analyze the ongoing traffic being proxied and determine the health of targets based on their behavior responding to requests.
  **Note:** This feature is not supported in hybrid mode.

## Schema

{% entity_schema %}

## Set up an Upstream

{% entity_example %}
type: upstream
data:
    name: api.example.internal
    tags:
      - user-level
      - low-priority
    algorithm: round-robin
{% endentity_example %}
