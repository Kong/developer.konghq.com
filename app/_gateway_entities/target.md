---
title: Targets
content_type: reference
entities:
  - target

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

description: A Target is an IP address/hostname with a port that identifies an instance of a backend service.

related_resources:
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxy/

schema:
    api: gateway/admin-ee
    path: /schemas/Target

---

## What is a Target?

{{page.description}} Each [Upstream](/gateway/entities/upstream/) can have many Targets. Targets are used by Upstreams for [load balancing](https://docs.konghq.com/gateway/latest/how-kong-works/load-balancing/). For example, if you have an `example_upstream` Upstream, you can point it to two different Targets: `httpbin.konghq.com` and `httpbun.com`. This is so that if one of the servers (like `httpbin.konghq.com`) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`).

The following diagram illustrates how Targets are used by Upstreams for load balancing:

{% include entities/upstreams-targets-diagram.md %}

## Schema

{% entity_schema %}

## Set up a Target

{% entity_example %}
type: target
data:
  target: httpbun.com:80
  weight: 100
{% endentity_example %}