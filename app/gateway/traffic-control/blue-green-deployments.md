---
title: Blue-green deployments
layout: reference
content_type: reference

related_resources:
  - text: Load balancing
    url: /gateway/load-balancing/
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Target entity
    url: /gateway/entities/target/
  - text: Gateway Service entity
    url: /gateway/entities/service/
  - text: Route entity
    url: /gateway/entities/route/



description: |
  You can set up blue-green deployments for {{site.base_gateway}} using Upstreams and Targets, and switching the Gateway Service to point to one Upstream or the other.

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

breadcrumbs:
  - /gateway/
  - /gateway/load-balancing/

tags:
    - load-balancing
    - blue-green
---

Blue-green deployments work by having two identical environments, allowing you to completely switch from one environment to another. 
{{site.base_gateway}} makes this simple by letting you point a Gateway Service at any Upstream entity as a host, where the Upstream entity can have any number of Targets that it can load-balance requests over.

Most commonly, this method is used for running environments in staging and production. 
When a release is ready in staging, the roles of the two environments switch.
The staging environment becomes production, and the production environment becomes staging.

## How it works

In {{site.base_gateway}} terms, for a blue-green deployment you need the following:
* A Gateway Service and a Route
* A `blue` Upstream and a `green` Upstream
* Targets configured for each Upstream

You can then toggle the `host` parameter in the Gateway Service to either Upstream as needed, effectively switching from blue to green and back with one command.

For example, given the following basic Gateway Service, Route, and `blue` and `green` Upstreams:

```yaml
services:
  - name: example-service
    host: blue
    path: "/anything"
    routes:
      - name: example-route
        hosts:
          - "example.domain.com"
upstreams:
  - name: blue
    targets:
    - target: 192.168.34.15:80
      weight: 100
    - target: 192.168.34.16:80
      weight: 50
  - name: green
    targets:
    - target: 192.168.34.17:80
      weight: 100
    - target: 192.168.34.18:80
      weight: 100
```

This example starts with the Gateway Service pointing to the `blue` Upstream.

To activate the blue-green switch, you just need to update the `host` property of the existing Gateway Service. 
For example, switch the Service `host` parameter to `green`:

```yaml
services:
  - name: example-service
    host: green
```

In this case, the example uses the default [round-robin load balancing](/gateway/entities/upstream/#round-robin), 
so the `green` Targets will be queued up in the order they were originally accessed, with weighting applied.

You can switch back and forth between the `blue` and the `green` Upstreams at any time, and the switch will be immediate.

