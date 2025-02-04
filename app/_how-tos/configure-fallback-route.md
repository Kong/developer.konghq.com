---
title: Configure a fallback Route
content_type: how_to

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
    q: How do I make sure that my Gateway Services redirect to a root page instead of failing with a 404 if they hit the wrong Route?
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

## 1. Validate existing routing rules

In the [prerequisites](#prerequisites), you configured a Gateway Service and a Route. 
Let's check that the Route works by accessing httpbin's `/anything` service, which will echo back the request:

{% validation request-check %}
url: /example-route/anything
status_code: 200
{% endvalidation %}

You should get a `200` response back.

Now try to access the same proxy URL, but at the root path (`/`):

{% validation request-check %}
url: /
status_code: 404
body:
  message: "no Route matched with those values"
{% endvalidation %}

The request will fail with the message `no Route matched with those values`.

## 2. Create a fallback Gateway Service and Route

To avoid 404 errors, create a fallback Service and a Route with the path `/`. 
Together, they'll catch any paths that don't match other routing rules and redirect them to the Service URL.

Based on [routing priority rules](/gateway/entities/route/#priority-matching), 
since this Route is the shortest and covers the broadest range of possible paths, 
it has the lowest priority and will be evaluated after all other Routes.

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
if incoming HTTP requests match no other existing Routes, they will match this Route and redirect to the `http://httpbun.com` Service URL.

## 3. Validate the fallback Route

Try accessing the `/` path again:

{% validation request-check %}
url: /
status_code: 302
{% endvalidation %} 

This time, the request passes with a 302, and the request is redirected to the fallback Service URL. 
You should see the header `Location: https://httpbun.com/` in the response.
