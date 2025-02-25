---
title: Configure blue-green deployments

content_type: how_to
related_resources:
  - text: Load balancing
    url: /gateway/traffic-control/load-balancing/

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

tags:
    - load-balancing

tldr:
    q: How do I set up blue-green deployments with {{site.base_gateway}}?
    a: |
      To set up a blue-green deployment with {{site.base_gateway}}, you need to:

      1. Create a `blue` Upstream pointing to multiple Targets, and point a Gateway Service to the Upstream as its host.
      2. Create a second Upsteam, `green`, along with its Targets.
      3. Toggle the `host` parameter in the Gateway Service to either Upstream as needed, effectively switching from blue to green and back with one command.

tools:
    - deck

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

Blue-green deployments work by having two identical environments, allowing you to completely switch from one environment to another. 
{{site.base_gateway}} makes this simple by letting you point a Gateway Service at any Upstream entity as a host, where the Upstream entity can have any number of Targets that it can load-balance requests over.

Most commonly, this method is used for running environments in staging and production. 
When a release is ready in staging, the roles of the two environments switch.
The staging environment becomes production, and the production environment becomes staging.

## 1. Create the blue Upstream

Create an Upstream with two Targets:

{% entity_examples %}
entities:
  upstreams:
    - name: blue
      targets:
        - target: httpbin.konghq.com:80
          weight: 100
        - target: httpbin.org:80
          weight: 50
{% endentity_examples %}

## 2. Create a Gateway Service and Route

Create a Gateway Service pointing to the `blue` Upstream, along with a Route:

{% entity_examples %}
entities:
  services:
    - name: example-service
      host: blue
  routes:
    - name: example-route
      paths:
      - "/anything"
      service:
        name: example-service
{% endentity_examples %}

This activates the environment. The Service and Route can now proxy requests to the Upstream, and it will load balance those requests over its Targets. 

In this case, we're using the default [round-robin load balancing](/gateway/entities/upstream/#round-robin), so the Targets will be queued up in the order they were originally accessed, with weighting applied.

You can check that requests are being routed to the correct Targets by accessing the `/anything` route:

{% validation request-check %}
url: /anything
status_code: 200
method: GET
{% endvalidation %}

Two thirds of the requests will go to `httpbin.konghq.com:80` (`weight: 100`), and one third will go to `httpbin.org:80` (`weight: 50`).

## 2. Create the green Upstream

Next, set up the `green` environment. This will be the environment that we switch to:

{% entity_examples %}
entities:
  upstreams:
    - name: green
      targets:
        - target: any.httpbun.com:80
          weight: 100
        - target: httpbun.com:80
          weight: 100
{% endentity_examples %}

## 3. Activate blue-green switch

To activate the blue-green switch, you just need to update the `host` property of the existing Gateway Service. 
Switch the Service from the `blue` to the `green` Upstream:

{% entity_examples %}
entities:
  services:
    - name: example-service
      host: green
{% endentity_examples %}

## 4. Validate

{% validation request-check %}
url: /anything
status_code: 200
method: GET
{% endvalidation %}

Incoming requests with host header set to address.mydomain.com are now proxied by Kong to the new targets. Half of the requests will go to `any.httpbun.com:80` (`weight: 100`), and the other half will go to `httpbun.com:80` (`weight: 100`).

You can switch back and forth between the `blue` and the `green` Upstreams at any time, and the switch will be immediate.