---
title: Create complex routes with regex in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: About the expressions router
    url: /gateway/routing/expressions/
  - text: Expressions router reference
    url: /gateway/routing/expressions-router-reference/
  - text: Expressions router examples
    url: /gateway/routing/expressions-router-examples/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service

min_version:
  gateway: 3.0

entities:
  - route

tier: enterprise

tags:
  - routing
  - traffic-control

tldr:
  q: lkjblk
  a: aksjlkj

faqs:
  - q: asfa
    a: asdfa

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

<!--outlines:

Configuring routes using expressions allows for more flexibility and better performance when dealing with complex or large configurations. This how-to guide explains how to switch to the expressions router and how to configure routes with the new expressive domain specific language. 

How to:
- how do I configure it alongside the other entities it relies on? 
- since regex is a common use case, I'd like to see that.
-->

## 1. Edit the kong.conf to contain the line router_flavor = expressions and restart Kong Gateway.

## 2. Create complex routes with expressions

```sh
curl --request POST \
 --url http://localhost:8001/services/example-service/routes \
 --header 'Content-Type: multipart/form-data' \
 --form-string name=complex_object \
 --form-string 'expression=(net.protocol == "http" || net.protocol == "https") &&
               (http.method == "GET" || http.method == "POST") &&
               (http.host == "example.com" || http.host == "example.test") &&
               (http.path ^= "/mock" || http.path ^= "/mocking") &&
               http.headers.x_another_header == "example_header" && (http.headers.x_my_header == "example" || http.headers.x_my_header == "example2")'
```

## 3. Validate this against a matching regex path