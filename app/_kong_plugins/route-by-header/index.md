---
title: 'Route By Header'
name: 'Route By Header'

content_type: plugin

publisher: kong-inc
description: 'Route requests based on specified request headers'
tier: enterprise

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: route-by-header.png

categories:
  - traffic-control

tags:
  - traffic-control

search_aliases:
  - route-by-header
  - route by request header

related_resources:
  - text: Route requests to different Upstreams based on headers
    url: /how-to/route-requests-to-different-upstreams-based-on-headers/

min_version:
  gateway: '1.0'
---

This plugin allows you to route a request to a specific [Upstream](/gateway/entities/upstream/) if it matches one of the
configured rules. 

## How the Route By Header plugin works

Each routing rule consists of a `condition` object and an `upstream_name` object. 
For each request coming into {{site.base_gateway}}, the plugin will try to find a rule in which
all the headers defined in the `condition` field have the same value as in the incoming request.
The first match dictates the Upstream to which the request is forwarded.

If more than one header is provided in a rule, the plugin looks for all of these headers
in the request. A request must contain all of the specified headers with the specified
values for a match to occur.


