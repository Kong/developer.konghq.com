---
title: Expressions router

description: "The expressions router is a collection of Routes that are all evaluated against incoming requests until a match can be found."

content_type: reference
layout: reference

products:
  - gateway

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: Expressions router reference
    url: /gateway/routing/expressions-router-reference/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

min_version:
  gateway: '3.0'

breadcrumbs:
  - /gateway/

faqs:
  - q: When should I use the expressions router in place of (or alongside) the traditional router?
    a: We recommend using the expressions router if you are running {{site.base_gateway}} 3.0.x or later. After enabling expressions, traditional match fields on the Route object (such as `paths` and `methods`) remain configurable. You may specify Expressions in the new `expression` field. However, these cannot be configured simultaneously with traditional match fields. Additionally, a new `priority` field, used in conjunction with the expression field, allows you to specify the order of evaluation for Expression Routes.
  - q: How do I enable the expressions router?
    a: |
      In your [kong.conf] <!--TODO link to kong.conf--> file, set `router_flavor = expressions` and restart your {{site.base_gateway}}. Once the router is enabled, you can use the `expression` parameter when you're creating a Route to specify the Routes. For example:
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
---

The expressions router is a collection of [Routes](/gateway/entities/route/) that are all evaluated against incoming requests until a match can be found. This allows for more complex routing logic than the traditional router and ensures good runtime matching performance. 

You can do the following with the expressions router:
* Prefix-based path matching
* Regex-based path matching that is less of a performance burden than the traditional router
* Case insensitive path matching
* Match by header value
* Regex captures
* Match by source IP and destination port
* Match by SNI (for TLS Routes)

## How expressions are formatted in the expressions router

To understand how the expressions router routes requests, it's important to how an Route is formatted in expressions. Each Route contains one or more predicates combined with logical operators, which {{site.base_gateway}} uses to match requests with Routes.

A predicate is the basic unit of expressions code which takes the following form:

```
http.path ^= "/foo/bar"
```

This predicate example has the following structure:
* `http.path`: Field
* `^=`: Operator
* `"/foo/bar"`: Constant value

For more information about each unit of the predicate, see the [Expressions router reference](/gateway/routing/expressions-router-reference/).


## How requests are routed with the expressions router

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem. When a request/connection comes in, {{site.base_gateway}} looks at which field your configured Routes require,
and supplies the value of these fields to the router execution context.
Routes are inserted into each router with the appropriate `priority` field set. The priority is a positive integer that defines the order of evaluation of the router. The bigger the priority, the sooner a Route will be evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined. The router is
updated incrementally as configured Routes change.

As soon as a Route yields a match, the router stops matching and the matched Route is used to process the current request/connection.

For example, if you have the following three Routes:

* **Route A**
  ```
  expression: http.path ^= "/foo" && http.host == "example.com"
  priority: 100
  ```
* **Route B**
  ```
  expression: http.path ^= "/foo"
  priority: 50
  ```
* **Route C**
  ```
  expression: http.path ^= "/"
  priority: 10
  ```

And you have the following incoming request:
```
http.path:"/foo/bar"
http.post:"konghq.com"
```

The router does the following:

1. The router checks Route A first because it has the highest priority. It doesn't match the incoming request, so the router checks the Route with the next highest priority.
1. Route B has the next highest priority, so the router checks this one second. It matches the request, so the router doesn't check Route C.