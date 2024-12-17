---
title: Expressions router

description: "{{site.base_gateway}} includes a rule-based engine using a Domain-Specific Expressions Language."

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
  gateway: 3.0

breadcrumbs:
  - /gateway/

faq:
  - q: When should I use the expressions router in place of (or alongside) the traditional compat router?
    a: We recommend using the expressions router if you are running {{site.base_gateway}} 3.0.x or later. After enabling expressions, traditional match fields on the route object (such as `paths` and `methods`) remain configurable. You may specify Expressions in the new `expression` field. However, these cannot be configured simultaneously with traditional match fields. Additionally, a new `priority` field, used in conjunction with the expression field, allows you to specify the order of evaluation for Expression routes.
---

{{ page.description }} Expressions can be used to perform tasks such as defining
complex routing logic on a [Route](/gateway/entities/route/).

The expressions language is a strongly typed [Domain-Specific Language (DSL)](https://developer.mozilla.org/docs/Glossary/DSL/Domain_specific_language)
which allows you to define fields, data, and operators for a Route. This allows for more complex routing logic than the traditional router, while ensuring good runtime matching performance.

* **Route:** A route is one or more predicates combined together with logical operators.
* **Router:** A router is a collection of routes that are all evaluated against incoming
  requests until a match can be found.

You can enable the expressions router in your [kong.conf]<!--TODO: link to kong.conf--> file by setting `router_flavor = expressions` and restarting your {{site.base_gateway}}. Once it's enabled, you can use the expressions language as you create Routes. 

## Use cases

Common use cases for the expressions router:

| Use case | Description |
|---------|------------|
| Complex routes | You can define complex Routes with the expressions router that the regular tradidtional compat router can't handle. |
| Routes with regex | Although you can use some regex with the regular tradidtional compat router, it's capabilities aren't as powerful as the expressions router. Additionally, regex in Routes can become a performance burden for {{site.base_gateway}}, but the expressions router can handle the performance load more gracefully. |

## How expressions are formatted in the expressions router

To understand how the expressions router routes requests, it's important to how an Route is formatted in expressions. 

The expressions router is a collection of Routes that are all evaluated against incoming requests until a match can be found. Each Route contains one or more predicates combined with logical operators, which {{site.base_gateway}} uses to match requests with Routes.

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

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem. When a request/connection comes in, {{site.base_gateway}} looks at which field your configured routes require,
and supplies the value of these fields to the router execution context.
Routes are inserted into each router with the appropriate `priority` field set. The priority is a positive integer that defines the order of evaluation of the router. The bigger the priority, the sooner a route will be evaluated. In the case of duplicate priority values between two routes in the same router, their order of evaluation is undefined. The router is
updated incrementally as configured routes change.

As soon as a route yields a match, the router stops matching and the matched route is used to process the current request/connection.

![Router matching flow](https://docs.konghq.com/assets/images/products/gateway/reference/expressions-language/router-matching-flow.png)

> _**Figure 1:**_ Diagram of how {{site.base_gateway}} executes routes. The diagram shows that {{site.base_gateway}} selects the route that both matches the expression and then selects the matching route with the highest priority.