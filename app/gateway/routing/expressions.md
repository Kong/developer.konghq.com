---
title: Expressions router

description: "The {{site.base_gateway}} expressions router is a rule-based engine that uses a Domain-Specific Expressions Language to define complex routing logic on a [Route](/gateway/entities/route/)."

content_type: reference
layout: reference

products:
  - gateway

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: Expressions router reference
    url: /gateway/routing/expressions-router-reference/
  - text: Expressions router examples
    url: /gateway/routing/expressions-router-examples/
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

{{ page.description }}

The expressions language is a strongly typed [Domain-Specific Language (DSL)](https://developer.mozilla.org/docs/Glossary/DSL/Domain_specific_language)
which allows you to define fields, data, and operators for a Route. This allows for more complex routing logic than the traditional router and ensures good runtime matching performance. 

## Use cases

Common use cases for the expressions router:

| Use case | Description |
|---------|------------|
| Complex Routes | You can define complex Routes with the expressions router that the traditional router can't handle. For example, the expressions router allows you to use the following complex routing logic: <br>* Prefix-based path matching<br>* Regex-based path matching<br>* Case insensitive path matching<br>* Match by header value<br>* Regex captures<br>* Match by source IP and destination port<br>* Match by SNI (for TLS Routes) |
| Routes with regex | Although you can use some regex with the traditional router, it's capabilities aren't as powerful as the expressions router. Additionally, regex in Routes can become a performance burden for {{site.base_gateway}}, but the expressions router can handle the performance load more gracefully. |

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

A correctly formatted Route with multiple predicates would look like the following:
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

## How requests are routed with the expressions router

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem. When a request/connection comes in, {{site.base_gateway}} looks at which field your configured Routes require,
and supplies the value of these fields to the router execution context.
Routes are inserted into each router with the appropriate `priority` field set. The priority is a positive integer that defines the order of evaluation of the router. The bigger the priority, the sooner a Route will be evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined. The router is
updated incrementally as configured Routes change.

As soon as a Route yields a match, the router stops matching and the matched Route is used to process the current request/connection.

{% mermaid %}
flowchart LR
    A["Incoming request<br>http.path:#quot;/foo/bar#quot;<br>http.post:#quot;konghq.com#quot;"] -->|Checks first, doesn't match| B1
    A --> |Checks second, does match|B2

    subgraph router[Expressions Router]
        direction TB
        B1["**Route A:** <br>*expression:* http.path ^= #quot;/foo#quot; && http.host == #quot;example.com#quot;<br>*priority:* 100"]
        B2["**Route B:** <br>*expression:* http.path ^= #quot;/foo#quot;<br>*priority:* 50"]
        B3["**Route C:** <br>*expression:* http.path ^= #quot;/#quot;<br>*priority:* 10"]
    end
{% endmermaid %}

> _**Figure 1:**_ Diagram of how {{site.base_gateway}} executes Routes. The diagram shows that {{site.base_gateway}} selects the Route that both matches the expression and then selects the matching Route with the highest priority.