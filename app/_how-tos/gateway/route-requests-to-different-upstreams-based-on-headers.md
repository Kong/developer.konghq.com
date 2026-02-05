---
title: Route requests to different Upstreams based on headers
permalink: /how-to/route-requests-to-different-upstreams-based-on-headers/
content_type: how_to

description: Use the Route by Header plugin to route requests based on a header value.

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - service
  - route
  - upstream
  - target

plugins:
  - route-by-header

tags:
  - traffic-control
search_aliases:
  - Route by Header plugin

tldr:
    q: How do I use header values to route requests to different Upstreams?
    a: Create a Service, a Route, and at least two Upstreams. Enable the Route by Header plugin and configure the rules for routing requests.

tools:
    - deck
related_resources:
  - text: "{{site.base_gateway}} audit logs"
    url: /gateway/audit-logs/
  - text: "Blue-green deployments"
    url: /gateway/traffic-control/blue-green-deployments/

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Create two Upstreams

In this example, we'll route requests based on a `location` header where the value can be either `us-east` or `us-west`. We'll create one [Upstream](/gateway/entities/upstream/) for each location:

{% entity_examples %}
entities:
  upstreams:
    - name: east-upstream
      targets:
        - target: httpbingo.org:80
          weight: 100
    - name: west-upstream
      targets:
        - target: httpbun.com:80
          weight: 100
{% endentity_examples %}

## Enable the Route by Header plugin on the Service

Enable the [Route by Header](/plugins/route-by-header/) plugin on the Gateway Service we created in the [prerequisites](#pre-configured-entities) to route requests with the `us-east` header value to `east-upstream` and requests with the `us-weast` value to `west-upstream`. 
Note that this will override the URL defined in the Service configuration.

{% entity_examples %}
entities:
    plugins:
    - name: route-by-header
      service: example-service
      config:
        rules:
        - upstream_name: east-upstream
          condition:
            location: us-east
        - upstream_name: west-upstream
          condition:
            location: us-west
{% endentity_examples %}

## Validate
To validate, you can try sending requests with both header values and check the host in the response.

This request is routed to `httpbingo.org`:
{% validation request-check %}
url: /anything
headers:
  - 'location:us-east'
status_code: 200
{% endvalidation %}

This request is routed to `httpbun.com`:
{% validation request-check %}
url: /anything
headers:
  - 'location:us-west'
status_code: 200
{% endvalidation %}


If you send a request without the header, or with a header value not specified in the Route by Header plugin, the request will be routed to the URL defined in the Service configuration, `httpbin.konghq.com` in this example:
{% validation request-check %}
url: /anything
headers:
- 'location:eu-west'
status_code: 200
{% endvalidation %}