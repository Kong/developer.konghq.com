---
title: Expressions router examples

description: "The [expressions router](/gateway/routing/expressions/) can be used to perform tasks such as defining complex routing logic on a [Route](/gateway/entities/route/)."

content_type: reference
layout: reference

min_version:
  gateway: 3.0

products:
  - gateway

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: About the expressions router
    url: /gateway/routing/expressions/
  - text: Expressions router reference
    url: /gateway/routing/expressions-router-reference/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

breadcrumbs:
  - /gateway/
---

{{ page.description }} This page shows some example Routes in the expression language that you can use when you're configuring your own Routes.

## HTTP examples 
### Prefix based path matching

Prefix based path matching is one of the most commonly used methods for routing. For example, if you want to match HTTP requests that have a path starting with `/foo/bar`, you can write the following route:

```
http.path ^= "/foo/bar"
```

### Regex based path matching

If you prefer to match an HTTP request's path against a regex, you can write the following route:

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
one `X-Foo` header with different values, the above example will ensure **each** instance of the
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

## TCP, TLS, and UDP examples

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
