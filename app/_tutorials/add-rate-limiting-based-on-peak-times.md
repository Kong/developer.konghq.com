---
title: How to enable dynamic rate limiting based on time
related_resources:
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/
  - text: Kong Functions Plugin
    url: /plugins/pre-function/


products:
    - gateway

platforms:
    - on-prem
    - konnect

min_version:
  gateway: 3.4.x

plugins: 
  - rate-limiting-advanced
  - pre-function

entites:
  - service
  - route

tiers:
  - enterprise

tags:
  - rate-limiting
  - pre-function

content_type: tutorial

tldr: 
  q: How do I set different rate limits for peak and off-peak times in Kong Gateway?
  a: Use the Rate Limiting Advanced plugin to set different rate limits for separate routes handling peak and off-peak traffic, and the Pre-function plugin to direct traffic based on the time of day.

faqs:
  - q: How does the Pre-function plugin determine whether to route traffic to peak or off-peak routes?
    a: The Pre-function plugin runs a Lua script that checks the current hour and sets request headers accordingly to route traffic to peak or off-peak routes.

tools:
    - deck
    - admin-api
---

You can configure rate-limiting based on peak or non-peak times by using the Pre-function and the Rate Limiting Advanced plugins together. This tutorial creates two Kong Gateway routes, one to handle peak traffic, and one to handle off-peak traffic. Each route has a different rate limiting configuration. The Pre-function plugin runs a Lua function to ship traffic to either of the routes based on the time. 

## Steps

1. Create a service named `httpbin`:
{% capture step %}
  {% entity_example %}
    type: service
    data:
      name: httbin
      url: http://httpbin.org/anything
  
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Create a route to handle peak traffic. Name the route peak, attach it to the service `httpbin`, and set a header with the name `X-Peak` and the value true:
{% capture step %}
   {% entity_example %}
    type: route
    data:
      name: peak
      paths: /httbin
      headers: "headers.X-Peak=true"
   {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Apply rate limiting to the `peak` route. This example sets the limit to 10 requests per 30 second window:
{% capture step %}
  {% entity_example %}
    type: plugin
    data:
      name: rate-limiting-advanced
      config:
        limit: 10
        window_size: 30
        window_type: sliding
        retry_after_jitter_max: 0
 
    targets:
        - route

    variables:
      'routeName|Id': peak
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Create another route to handle off-peak traffic. Name the route `off-peak`, attach it to the service `httpbin`, and set a header with the name `X-Off-Peak` and the value `true`
{% capture step %}
   {% entity_example %}
    type: route
    data:
      name: off-peak
      paths: /httbin
      headers: "headers.X-Off-Peak=true"
   {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Apply rate limiting to the `off-peak` route. This example sets the limit to 5 requests per 30 second window:
{% capture step %}
  {% entity_example %}
    type: plugin
    data:
      name: rate-limiting-advanced
      config:
        limit: 5
        window_size: 30
        window_type: sliding
        retry_after_jitter_max: 0
 
    targets:
        - route

    variables:
      'routeName|Id': off-peak
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

## Apply the Pre-function plugin to route peak and off-peak traffic

1. Create a file named `ratelimit.lua` 

    ```bash
    touch ratelimit.lua
    ```
2. Add the following Lua code to the file: 

    ```lua
      
    local hour = os.date("*t").hour 
    if hour >= 8 and hour <= 17 
    then
        kong.service.request.set_header("X-Peak","true") 
    else
        kong.service.request.set_header("X-Off-Peak","true") 
    end
    
    ```

3. Apply the Pre-function plugin globally and run it in the rewrite phase:
{% capture step %}
  {% entity_example %}
    type: plugin
    data:
      name: rate-limiting-advanced
      config:
        limit: 5
        window_size: 30
        window_type: sliding
        retry_after_jitter_max: 0
 
    targets:
        - route

    variables:
      'routeName|Id': off-peak
  {% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}
