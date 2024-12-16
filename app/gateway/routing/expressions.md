---
title: Expressions router

description: "{{site.base_gateway}} includes a rule-based engine using a domain-specific expressions language."

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

breadcrumbs:
  - /gateway/

faq:
  - q: When should I use the expressions router in place of (or alongside) the traditional compat router?
    a: We recommend using the expressions router if you are running {{site.base_gateway}} 3.0.x or later. 
---

<!--outlines:
Expressions router:
- what is it?
- why should I use this? When should I use this in place of (or alongside) the traditional compat router?
- how do i format it/understand it?
- how are expression router routes routed?
- where do I go to configure it? how do I go about doing that?
-->

{{ page.description }} Expressions can be used to perform tasks such as defining
complex routing logic on a [Route](/gateway/entities/route/).

The expressions language is a strongly typed Domain-Specific Language (DSL)
that allows you to define comparison operations on various input data.
The results of the comparisons can be combined with logical operations, which allows complex routing logic to be written while ensuring good runtime matching performance.

You can enable the expressions router in your [kong.conf]<!--TODO: link to kong.conf--> file by setting `router_flavor = expressions` and restarting your {{site.base_gateway}}.

## Use cases

Expressions router can help you with the following use cases:
  * complex routes with regex
  * something else

## Key concepts

<!--Need some lead in info here that states that this is explaining how things are formatted.-->

* **Field:** The field contains value extracted from the incoming request. For example,
  the request path or the value of a header field. The field value could also be absent
  in some cases. An absent field value will always cause the predicate to yield `false`
  no matter the operator. The field always displays to the left of the predicate.
* **Constant value:** The constant value is what the field is compared to based on the
  provided operator. The constant value always displays to the right of the predicate.
* **Operator:** An operator defines the desired comparison action to be performed on the field
  against the provided constant value. The operator always displays in the middle of the predicate,
  between the field and constant value.
* **Predicate:** A predicate compares a field against a pre-defined value using the provided operator and
  returns `true` if the field passed the comparison or `false` if it didn't.
* **Route:** A route is one or more predicates combined together with logical operators.
* **Router:** A router is a collection of routes that are all evaluated against incoming
  requests until a match can be found.
* **Priority:** The priority is a positive integer that defines the order of evaluation of the router.
  The bigger the priority, the sooner a route will be evaluated. In the case of duplicate
  priority values between two routes in the same router, their order of evaluation is undefined.

![Structure of a predicate](https://docs.konghq.com/assets/images/products/gateway/reference/expressions-language/predicate.png)

A predicate is structured like the following: 

```
http.path ^= "/foo/bar"
```

This predicate example has the following structure:
* `http.path`: Field
* `^=`: Operator
* `"/foo/bar"`: Constant value

## How requests are routed with the expressions router

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem.
Routes are inserted into each router with the appropriate `priority` field set. The router is
updated incrementally as configured routes change.

When a request/connection comes in, {{site.base_gateway}} looks at which field your configured routes require,
and supplies the value of these fields to the router execution context. This is evaluated against
the configured routes in descending order (routes with a higher `priority` number are evaluated first).

As soon as a route yields a match, the router stops matching and the matched route is used to process the current request/connection.

![Router matching flow](https://docs.konghq.com/assets/images/products/gateway/reference/expressions-language/router-matching-flow.png)

> _**Figure 1:**_ Diagram of how {{site.base_gateway}} executes routes. The diagram shows that {{site.base_gateway}} selects the route that both matches the expression and then selects the matching route with the highest priority.

<!--performance optimizations? https://docs.konghq.com/gateway/latest/reference/expressions-language/performance/>