---
title: Targets
content_type: reference
description: A Target identifies an instance of an upstream service using an IP address or hostname with a port.

entities:
  - target

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

related_resources:
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Route entity
    url: /gateway/entities/route/
  - text: Load balancing in {{site.base_gateway}}
    url: /gateway/load-balancing/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway-manager/control-plane-resource-limits/

schema:
    api: gateway/admin-ee
    path: /schemas/Target

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

search_aliases:
  - hostname
  - ip address

works_on:
  - on-prem
  - konnect

tags:
  - load-balancing
  - failover
---

## What is a Target?

A Target identifies an instance of an upstream service using an IP address or hostname with a port.
Each [Upstream](/gateway/entities/upstream/) can have many Targets. Targets are used by Upstreams for [load balancing](/gateway/entities/upstream/#load-balancing-algorithms). For example, if you have an `example_upstream` Upstream, you can point it to two different Targets: `httpbin.konghq.com` and `httpbun.com`. This is so that if one of the servers (like `httpbin.konghq.com`) is unavailable, it automatically detects the problem and routes all traffic to the working server (`httpbun.com`).

The following diagram illustrates how Targets are used by Upstreams for load balancing:

{% include entities/upstreams-targets-diagram.md %}

## Using hostnames

A Target can also have a hostname instead of an IP address. 
In that case, the name is resolved and all entries found are individually added to the load balancer.

For example, let's say you add `api.host.com:123` with `weight=100`:

* If the hostname `api.host.com` resolves to an A record with 2 IP addresses, both IP addresses are added as a target, each with `weight=100` and port 123.
* If the hostname resolves to an SRV record, then the `port` and `weight` fields from the DNS record are used, and override the port and weight set in the Target.

The balancer honors the DNS record's `ttl` setting. Upon expiry, it queries the nameserver and updates the balancer. 
When a DNS record has `ttl=0`, the hostname is added as a single target, with the specified weight. The nameserver is queried for every request, adding latency to the request.

## Managing failover Targets {% new_in 3.12 %}

{% include_cached /gateway/failover-targets.md %}

## Schema

{% entity_schema %}

## Set up a Target

{% entity_example %}
type: target
data:
  target: httpbun.com:80
  weight: 100
{% endentity_example %}
