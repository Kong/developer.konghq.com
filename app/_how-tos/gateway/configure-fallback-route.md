---
title: Configure a fallback Route
permalink: /how-to/configure-fallback-route/
content_type: how_to
description: Learn how to configure a fallback Route to redirect 404s to a specific upstream service.
related_resources:
  - text: Route
    url: /gateway/entities/route/
  - text: Redirect plugin
    url: /plugins/redirect/

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

tags:
    - routing
    - traffic-control

tldr:
    q: How do I redirect my Gateway Services to a root page instead of failing with a 404 if they hit the wrong Route?
    a: Configure a fallback Route using the `/` wildcard path to catch any potential 404s and redirect to a specific upstream service.

faqs:
    - q: When should I use the Route entity for fallback routing, and when should I set up redirects with the Redirect plugin instead?
      a: |
        The fallback routing method has limited flexibility. It's most useful as a blanket rule.
        
        The [Redirect plugin](/plugins/redirect/) gives you more control over your redirect rules. You can apply the Redirect plugin to any Gateway Service,
        Route, Consumer, or Consumer Group, as well as globally, and you can decide whether the incoming request path remains the same, 
        while still redirecting to a different location.

tools:
    - deck

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

## Validate existing routing rules

In the [prerequisites](#prerequisites), you configured a Gateway Service and a Route. 
Let's check that the Route works by accessing httpbin's `/anything` Service, which will echo back the request:

{% validation request-check %}
url: /anything
status_code: 200
display_headers: true
{% endvalidation %}

You should get a `200` response back.

Now try to access the same proxy URL, but at the root path (`/`):

{% validation request-check %}
url: /
status_code: 404
display_headers: true
{% endvalidation %}

The request will fail with the message `no Route matched with those values`.

## Create a fallback Gateway Service and Route

To avoid 404 errors, create a fallback Gateway Service and a Route with the path `/`. 
Together, they'll catch any paths that don't match other routing rules and redirect them to the Gateway Service URL.

Based on [routing priority rules](/gateway/entities/route/#priority-matching), 
this Route has the lowest priority and is evaluated after all other Routes because it's the shortest and covers the broadest range of possible paths.

{% entity_examples %}
entities:
  services:
    - name: fallback_service
      url: http://httpbun.com
  routes:
    - name: fallback_route
      service:
        name: fallback_service
      paths:
        - /
{% endentity_examples %}

Since all URIs are prefixed by the root character `/`, 
if incoming HTTP requests match no other existing Routes, they will match this Route and redirect to the `http://httpbun.com` Gateway Service URL.

## Validate the fallback Route

Try accessing the `/` path again:

{% validation request-check %}
url: /
status_code: 302
display_headers: true
{% endvalidation %} 

This time, the request passes with a 302, and the request is redirected to the fallback Service URL. 
You should see the header `Location: https://httpbun.com/` in the response.
