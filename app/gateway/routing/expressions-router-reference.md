---
title: Expressions router reference

description: "{{site.base_gateway}} includes a rule-based engine using a domain-specific expressions language."

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
  - text: Expressions router examples
    url: /gateway/routing/expressions-router-examples/
  - text: Expressions repository
    url: https://github.com/Kong/atc-router

breadcrumbs:
  - /gateway/
---

<!--outlines:
Reference:
- what are all the fields/things I can configure and what do they do?
- the pieces are explained, but I need something at the front that explains how the things all work together, what does a completed one look like? and then we get into the bits and pieces.
-->

This reference explains the different configurable entities for the [expressions router](/gateway/routing/expressions/).

## Predicates

A predicate is the basic unit of expressions code which takes the following form:

```
http.path ^= "/foo/bar"
```

Predicates are made up of smaller units that you can configure:

| Object | Description | Example |
|--------|-------------|---------|
| Field | The field contains value extracted from the incoming request. For example, the request path or the value of a header field. The field value could also be absent in some cases. An absent field value will always cause the predicate to yield `false` no matter the operator. The field always displays to the left of the predicate. | `http.path` |
| Constant value | The constant value is what the field is compared to based on the provided operator. The constant value always displays to the right of the predicate. | `"/foo/bar"` |
| Operator | An operator defines the desired comparison action to be performed on the field against the provided constant value. The operator always displays in the middle of the predicate, between the field and constant value. | `^=` |
| Predicate | A predicate compares a field against a pre-defined value using the provided operator and returns `true` if the field passed the comparison or `false` if it didn't. | `http.path ^= "/foo/bar"` |

## Type system

Expressions language is strongly typed. Operations are only performed
if such an operation makes sense in regard to the actual type of field and constant.

Type conversion at runtime is not supported, either explicitly or implicitly. Types
are always known at the time a route is parsed and an error is returned
if the operator cannot be performed on the provided field and constant.

The expressions language currently supports the following types:

| Type     | Description                                                                                          | Field type | Constant type |
|----------|------------------------------------------------------------------------------------------------------|------------|---------------|
| `String` | A string value, always in valid UTF-8.                                                               | ✅          | ✅             |
| `IpCidr` | Range of IP addresses in CIDR format. Can be either IPv4 or IPv6.                                   | ❌          | ✅             |
| `IpAddr` | A single IP address. Can be either IPv4 or IPv6.                                                    | ✅          | ✅             |
| `Int`    | A 64-bit signed integer.                                                                             | ✅          | ✅             |
| `Regex`  | A regex in [syntax](https://docs.rs/regex/latest/regex/#syntax) specified by the Rust `regex` crate. | ❌          | ✅             |

In addition, expressions also supports one composite type, `Array`. Array types are written as `Type[]`.
For example: `String[]`, `Int[]`. Currently, arrays can only be present in field values. They are used in
case one field could contain multiple values. For example, `http.headers.x` or `http.queries.x`.

### String

Strings are valid UTF-8 sequences. They can be defined with string literal that looks like
`"content"`. The following escape sequences are supported:

| Escape sequence | Description               |
|-----------------|---------------------------|
| `\n`            | Newline character         |
| `\r`            | Carriage return character |
| `\t`            | Horizontal tab character  |
| `\\`            | The `\` character         |
| `\"`            | The `"` character         |

In addition, expressions support raw string literals, like `r#"content"#`.
This feature is useful if you want to write a regex and repeated escape becomes
tedious to deal with.

For example, if you want to match `http.path` against `/\d+\-\d+` using the regex `~` operator, the predicate will be written as the following with string literals:

```
http.path ~ "/\\d+\\-\\d+"
```

With raw string literals, you can write:

```
http.path ~ r#"/\d+\-\d+"#
```

### IpCidr

`IpCidr` represents a range of IP addresses in Classless Inter-Domain Routing (CIDR) format.

The following is an IPv4 example:

```
net.src.ip in 192.168.1.0/24
```

The following is an IPv6 example:
```
net.src.ip in fd00::/8
```

Expressions parser rejects any CIDR literal where the host portion contains any non-zero bits. This means that `192.168.0.1/24` won't pass the parser check because the intention of the author is unclear.

### IpAddr

`IpAddr` represents a single IP addresses in IPv4 Dot-decimal notation,
or the standard IPv6 Address Format.

The following is an IPv4 example:

```
net.src.ip == 192.168.1.1
```

The following is an IPv6 example:
```
net.src.ip == fd00::1
```

### Int

There is only one integer type in expressions. All integers are signed 64-bit integers. Integer
literals can be written as `12345`, `-12345`, or in hexadecimal format, such as `0xab12ff`,
or in octet format like `0751`.

### Regex

Regex are written as `String` literals, but they are parsed when the `~` regex operator is present
and checked for validity according to the [Rust `regex` crate syntax](https://docs.rs/regex/latest/regex/#syntax).
For example, in the following predicate, the constant is parsed as a `Regex`:

```
http.path ~ r#"/foo/bar/.+"#
```

## Operators

Expressions language support a rich set of operators that can be performed on various data types.

| Operator       | Name                  | Description                  |
|----------------|-----------------------|--------------------------------------------------------------------------------------|
| `==`           | Equals                | Field value is equal to the constant value                                                                                                                                                                   |
| `!=`           | Not equals            | Field value does not equal the constant value                                                                                                                                                                |
| `~`            | Regex match           | Field value matches regex                                                                                                                                                                                    |
| `^=`           | Prefix match          | Field value starts with the constant value                                                                                                                                                                   |
| `=^`           | Postfix match         | Field value ends with the constant value                                                                                                                                                                     |
| `>=`           | Greater than or equal | Field value is greater than or equal to the constant value                                                                                                                                                   |
| `>`            | Greater than          | Field value is greater than the constant value                                                                                                                                                               |
| `<=`           | Less than or equal    | Field value is less than or equal to the constant value                                                                                                                                                      |
| `<`            | Less than             | Field value is less than the constant value                                                                                                                                                                  |
| `in`           | In                    | Field value is inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. For example, `net.src.ip in 192.168.0.0/24` will only return `true` if the value of `net.src.ip` is within `192.168.0.0/24`.                                                                                                                                                                    |
| `not in`       | Not in                | Field value is not inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. For example, `net.src.ip in 192.168.0.0/24` will only return `true` if the value of `net.src.ip` is within `192.168.0.0/24`.                                                                                                                                                                |
| `contains`     | Contains              | Field value contains the constant value. This operator is used to check the existence of a string inside another string. For example, `http.path contains "foo"` will return `true` if `foo` can be found anywhere inside `http.path`. This will match a `http.path` that looks like `/foo`, `/abc/foo`, or `/xfooy`, for example.                            |
| `&&`           | And                   | Returns `true` if **both** expressions on the left and right side evaluates to `true`                                                                                                                        |
| `||` | Or | Returns `true` if **any** expressions on the left and right side evaluates to `true` |                                                                                                                    |
| `(Expression)` | Parenthesis           | Groups expressions together to be evaluated first                                                                                                                                                            |
{% if_version gte:3.4.x %}
| `!`            | Not                   | Negates the result of a parenthesized expression. **Note:** The `!` operator can only be used with parenthesized expression like `!(foo == 1)`, it **cannot** be used with a bare predicate like `! foo == 1` |
{% endif_version %}

## Allowed type and operator combinations

Here are the allowed combination of field types and constant types with each operator.
In the following table, rows represent field types that display on the left-hand side (LHS) of the predicate, 
whereas columns represent constant value types that display on the right-hand side (RHS) of the predicate.

| Field (LHS)/Constant (RHS) types | `String`                                | `IpCidr`       | `IpAddr` | `Int`                            | `Regex` | `Expression` |
|----------------------------------|-----------------------------------------|----------------|----------|----------------------------------|---------|--------------|
| `String`                         | `==`, `!=`, `~`, `^=`, `=^`, `contains` | ❌              | ❌        | ❌                                | `~`     | ❌            |
| `IpAddr`                         | ❌                                       | `in`, `not in` | `==`     | ❌                                | ❌       | ❌            |
| `Int`                            | ❌                                       | ❌              | ❌        | `==`, `!=`, `>=`, `>`, `<=`, `<` | ❌       | ❌           |
| `Expression`                     | ❌                                       | ❌              | ❌        | ❌                                | ❌       | `&&`, `||`|


{:.note}
> **Notes:** 
  * The `~` operator is described as supporting both `String ~ String` and `String ~ Regex`.
  In reality, `Regex` constant values can only be written as `String` on the right hand side.
  The presence of `~` operators treats the string value as a regex.
  Even with the `~` operator, [`String` escape rules described above](#string) still apply and it
  is almost always easier to use raw string literals for the `~` operator as described in the [`Regex` section](#regex).
  * The `~` operator does not automatically anchor the regex to the beginning of the input.
  Meaning `http.path ~ r#"/foo/\d"#` could match a path like `/foo/1` or `/some/thing/foo/1`.
  If you want to match from the beginning of the string (anchoring the regex), then you must
  manually specify it with the `^` meta-character. For example, `http.path ~ r#"^/foo/\d"#`.
  * When performing IP address-related comparisons with `==`, `in`, or `not in`, different families of
  address types for the field and constant value will always cause the predicate to return `false` at
  runtime.

## Matching fields

The following table describes the available matching fields, as well as their associated type when using an expressions based router.

<!-- There are two separate tables because Liquid's whitespace handling breaks tables when using if tags -->

{% if_version gte:3.4.x %}
| Field                                                | Type       | Available in HTTP Subsystem | Available in Stream Subsystem | Description |
|------------------------------------------------------|------------|-----------------------------|-------------------------------|-------------|
| `net.protocol`                                       | `String`   | ✅  | ✅  | Protocol of the route. Roughly equivalent to the `protocols` field on the `Route` entity.  **Note:** Configured `protocols` on the `Route` entity are always added to the top level of the generated route but additional constraints can be provided by using the `net.prococol` field directly inside the expression. |
| `tls.sni`                                            | `String`   | ✅  | ✅  | If the connection is over TLS, the `server_name` extension from the ClientHello packet. |
| `http.method`                                        | `String`   | ✅  | ❌  | The method of the incoming HTTP request. (for example, `"GET"` or `"POST"`) |
| `http.host`                                          | `String`   | ✅  | ❌  | The `Host` header of the incoming HTTP request. |
| `http.path`                                          | `String`   | ✅  | ❌  | The normalized request path according to rules defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-6). This field value does **not** contain any query parameters that might exist. |
| `http.path.segments.<segment_index>`                 | `String`   | ✅  | ❌  | A path segment extracted from the incoming (normalized) `http.path` with zero-based index. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.1` will return `"b"`. |
| `http.path.segments.<segment_index>_<segment_index>` | `String`   | ✅  | ❌  | Path segments extracted from the incoming (normalized) `http.path` within the given closed interval joined by `"/"`. Indexes are zero-based. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.0_1` will return `"a/b"`. |
| `http.path.segments.len`                             | `Int`      | ✅  | ❌  | Number of segments from the incoming (normalized) `http.path`. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.len` will return `3`. |
| `http.headers.<header_name>`                         | `String[]` | ✅  | ❌  | The value(s) of request header `<header_name>`. **Note:** The header name is always normalized to the underscore and lowercase form, so `Foo-Bar`, `Foo_Bar`, and `fOo-BAr` all become values of the `http.headers.foo_bar` field. |
| `http.queries.<query_parameter_name>`                | `String[]` | ✅  | ❌  | The value(s) of query parameter `<query_parameter_name>`. |
| `net.src.ip`                          | `IpAddr`   | ✅  | ✅  | IP address of the client.                                                          |
| `net.src.port`                        | `Int`      | ✅  | ✅  | The port number used by the client to connect.                                     |
| `net.dst.ip`                          | `IpAddr`   | ✅  | ✅  | Listening IP address where {{site.base_gateway}} accepts the incoming connection.  |
| `net.dst.port`                        | `Int`      | ✅  | ✅  | Listening port number where {{site.base_gateway}} accepts the incoming connection. |
{% endif_version %}

{% if_version lte:3.4.x %}
| Field                                                | Type       | Available in HTTP Subsystem | Available in Stream Subsystem | Description |
|------------------------------------------------------|------------|-----------------------------|-------------------------------|-------------|
| `net.protocol`                                       | `String`   | ✅  | ✅  | Protocol of the route. Roughly equivalent to the `protocols` field on the `Route` entity.  **Note:** Configured `protocols` on the `Route` entity are always added to the top level of the generated route but additional constraints can be provided by using the `net.prococol` field directly inside the expression. |
| `tls.sni`                                            | `String`   | ✅  | ✅  | If the connection is over TLS, the `server_name` extension from the ClientHello packet. |
| `http.method`                                        | `String`   | ✅  | ❌  | The method of the incoming HTTP request. (for example, `"GET"` or `"POST"`) |
| `http.host`                                          | `String`   | ✅  | ❌  | The `Host` header of the incoming HTTP request. |
| `http.path`                                          | `String`   | ✅  | ❌  | The normalized request path according to rules defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-6). This field value does **not** contain any query parameters that might exist. |
| `http.headers.<header_name>`                         | `String[]` | ✅  | ❌  | The value(s) of request header `<header_name>`. **Note:** The header name is always normalized to the underscore and lowercase form, so `Foo-Bar`, `Foo_Bar`, and `fOo-BAr` all become values of the `http.headers.foo_bar` field. |
| `http.queries.<query_parameter_name>`                | `String[]` | ✅  | ❌  | The value(s) of query parameter `<query_parameter_name>`. |
| `net.src.ip`                          | `IpAddr`   | ❌  | ✅  | IP address of the client.                                                          |
| `net.src.port`                        | `Int`      | ❌  | ✅  | The port number used by the client to connect.                                     |
| `net.dst.ip`                          | `IpAddr`   | ❌  | ✅  | Listening IP address where {{site.base_gateway}} accepts the incoming connection.  |
| `net.dst.port`                        | `Int`      | ❌  | ✅  | Listening port number where {{site.base_gateway}} accepts the incoming connection. |
{% endif_version %}

## Expressions router performance considerations

Performance is critical when it comes to proxying API traffic. This guide explains how to optimize the
expressions you write to get the most performance out of the routing engine.

### Number of routes

#### Route matching priority order

Expressions routes are always evaluated in the descending `priority` order they were defined.
Therefore, it is helpful to put more likely matched routes before (as in, higher priority)
less frequently matched routes.

The following examples show how you would prioritize two routes based on if they were likely to be matched or not.

Example route 1:
```
expression: http.path == "/likely/matched/request/path"
priority: 100
```

Example route 2:
```
expression: http.path == "/unlikely/matched/request/path"
priority: 50
```

It's also best to reduce the number of `Route` entities created by leveraging the
logical combination capability of the expressions language.

#### Combining routes

If multiple routes result in the same `Service` and `Plugin` config being used,
they should be combined into a single expression `Route` with the `||` logical or operator. By combining routes into a single expression, this results in fewer `Route` objects created and better performance.

Example route 1:
```
service: example-service
expression: http.path == "/hello"
```

Example route 2:
```
service: example-service
expression: http.path == "/world"
```

These two routes can instead be combined as:

```
service: example-service
expression: http.path == "/hello" || http.path == "/world"
```

### Regular expressions usage

Regular expressions (regexes) are powerful tool that can be used to match strings based on
very complex criteria. Unfortunately, this has also made them more expensive to
evaluate at runtime and hard to optimize. Therefore, there are some common
scenarios where regex usages can be eliminated, resulting in significantly
better matching performance.

When performing exact matches (non-prefix matching) of a request path, use the `==` operator
instead of regex.

**Faster performance example:**
```
http.path == "/foo/bar"
```

**Slower performance example:**
```
http.path ~ r#"^/foo/bar$"#
```

When performing exact matches with the `/` optional slash at the end, it is tempting to write
regexes. However, this is completely unnecessary with the expressions language.

**Faster performance example:**
```
http.path == "/foo/bar" || http.path == "/foo/bar/"
```

**Slower performance example:**
```
http.path ~ r#"^/foo/?$"#
```

