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

schema:
    api: gateway/admin-ee
    path: /schemas/Upstream
---

## What is an Upstream?

{{page.description}} In {{site.base_gateway}}, an Upstream represents a virtual hostname and can be used to health check, circuit break, and load balance incoming requests over multiple [Gateway Services](/gateway/entities/service/).

## Upstream and Service interaction

You can configure a Service to point to an Upstream instead of a host. 
For example, if you have a Service called `example_service` and an Upstream called `example_upstream`, you can point `example_service` to `example_upstream` instead of specifying a host. 
The `example_upstream` Upstream can then point to two different targets: `httpbin.konghq.com` and `httpbun.com`. 
In a real environment, the Upstream points to the same Service running on multiple systems.

This setup allows you to [load balance](/gateway/{{ page.release }}/how-kong-works/load-balancing) between upstream targets. 
For example, if an application is deployed across two different servers or upstream targets, {{site.base_gateway}} needs to load balance across both servers. 
This is so that if one of the servers (like `httpbin.konghq.com` in the previous example) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`). 

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

| You want to... | Then use... |
|----------------|-------------|
| health check |  |
| circuit break |  |
| load balance |  |

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
