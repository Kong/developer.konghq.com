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
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

breadcrumbs:
  - /gateway/
---

{{ page.description }} Expressions can be used to perform tasks such as defining
complex routing logic.
This guide is a reference for the expressions language and explains how it can be used.

## About the expressions language

The expressions language is a strongly typed Domain-Specific Language (DSL)
that allows you to define comparison operations on various input data.
The results of the comparisons can be combined with logical operations, which allows complex routing logic to be written while ensuring good runtime matching performance.

### Key concepts

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

## How routes are executed

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem.
Routes are inserted into each router with the appropriate `priority` field set. The router is
updated incrementally as configured routes change.

When a request/connection comes in, {{site.base_gateway}} looks at which field your configured routes require,
and supplies the value of these fields to the router execution context. This is evaluated against
the configured routes in descending order (routes with a higher `priority` number are evaluated first).

As soon as a route yields a match, the router stops matching and the matched route is used to process the current request/connection.

![Router matching flow](https://docs.konghq.com/assets/images/products/gateway/reference/expressions-language/router-matching-flow.png)

> _**Figure 1:**_ Diagram of how {{site.base_gateway}} executes routes. The diagram shows that {{site.base_gateway}} selects the route that both matches the expression and then selects the matching route with the highest priority.

## Expression router examples (HTTP)
### Prefix based path matching

Prefix based path matching is one of the most commonly used methods for routing. For example, if you want to match HTTP requests that have a path starting with `/foo/bar`, you can write the following route:

```
http.path ^= "/foo/bar"
```

### Regex based path matching

If you prefer to match a HTTP requests path against a regex, you can write the following route:

```
http.path ~ r#"/foo/bar/\d+"#
```

### Case insensitive path matching

If you want to ignore case when performing the path match, use the `lower()` modifier on the field
to ensure it always returns a lowercase value:

```
lower(http.path) == "/foo/bar"
```

This will match requests with a path of `/foo/bar` and `/FOO/bAr`, for example.

### Match by header value

If you want to match incoming requests by the value of header `X-Foo`, do the following:

```
http.headers.x_foo ~ r#"bar\d"#
```

If there are multiple header values for `X-Foo` and the client sends more than
one `X-Foo` header with different value, the above example will ensure **each** instance of the
value will match the regex `r#"bar\d"#`. This is called "all" style matching, meaning each instance
of the field value must pass the comparison for the predicate to return `true`. This is the default behavior.

If you do not want this behavior, you can turn on "any" style of matching which returns
`true` for the predicate as soon as any of the values pass the comparison:

```
any(http.headers.x_foo) ~ r#"bar\d"#
```

This will return `true` as soon as any value of `http.headers.x_foo` matches regex `r#"bar\d"#`.

Different transformations can be chained together. The following is also a valid use case
that performs case-insensitive matching:

```
any(lower(http.headers.x_foo)) ~ r#"bar\d"#
```

### Regex captures

You can define regex capture groups in any regex operation which will be made available
later for plugins to use. Currently, this is only supported with the `http.path` field:

```
http.path ~ r#"/foo/(?P<component>.+)"#
```

The matched value of `component` will be made available later to plugins such as
[Request Transformer Advanced](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/how-to/templates/).

## Expression router examples (TCP, TLS, UDP)

### Match by source IP and destination port

```
net.src.ip in 192.168.1.0/24 && net.dst.port == 8080
```

This matches all clients in the `192.168.1.0/24` subnet and the destination port (which is listened to by Kong)
is `8080`. IPv6 addresses are also supported.

### Match by SNI (for TLS routes)

```
tls.sni =^ ".example.com"
```

This matches all TLS connections with the `.example.com` SNI ending.
