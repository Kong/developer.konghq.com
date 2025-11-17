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
  - text: Expressions repository
    url: https://github.com/Kong/atc-router
  - text: Traditional router
    url: /gateway/routing/traditional/
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/

min_version:
  gateway: '3.0'

breadcrumbs:
  - /gateway/

faqs:
  - q: Is there a performance difference between the traditional router and expressions?
    a: Both traditional and expressions modes use the same routing engine internally. Traditional mode configures routes with JSON, and expressions uses a DSL.
  - q: Why would I choose expressions over the traditional router?
    a: The expressions router provides more routing flexibility, including fast exact matching that is not available in the traditional router.
  - q: When should I keep using the traditional router over expressions?
    a: If you are working with APIOps pipelines that manipulate the route using `deck file patch`, we recommend using the JSON format used by the traditional router.
  - q: Does Workspace route collision detection work with the expressions router?
    a: |
      [Workspace route collision detection](/gateway/entities/workspace/#how-does-kong-gateway-resolve-entity-conflicts-between-workspaces) **does not** work with expression-based routing.

works_on:
  - on-prem
  - konnect

tags:
- routing
---

The expressions router provides a Domain Specific Language (DSL) that allows for complex routing rule definition. The expressions router ensures good runtime matching performance by providing specific routing comparisons such as non-regex equality checks that are not available in the traditional router.

You can do the following with the expressions router:
* Prefix-based path matching
* Regex-based path matching that is less of a performance burden than the traditional router
* Case insensitive path matching
* Match by header value
* Regex captures
* Match by source IP and destination port
* Match by SNI (for TLS Routes)

## Enable the expressions router

In your `kong.conf` file, set `router_flavor = expressions` and restart your {{site.base_gateway}}. Once the router is enabled, you can use the `expression` parameter when you're creating a Route to specify the Routes.

## How requests are routed with the expressions router

At runtime, {{site.base_gateway}} builds two separate routers for the HTTP and Stream (TCP, TLS, UDP) subsystem. When a request/connection comes in, {{site.base_gateway}} looks at which field your configured Routes require, and supplies the value of these fields to the router execution context.

Routes are inserted into each router with the appropriate `priority` field set. The priority is a positive integer that defines the order of evaluation of the router. The bigger the priority, the sooner a Route is evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined. The router is updated incrementally as configured Routes change.

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

## Performance considerations

This section explains how to optimize the expressions you write to get the most performance out of the routing engine.

### Priority matching

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

### Combining routes

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
scenarios where regex usage can be eliminated, resulting in significantly
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

## Expressions router reference

This reference explains the different configurable entities for the expressions router.

### Expressions formatting

Each Route contains one or more predicates combined with logical operators, which {{site.base_gateway}} uses to match requests with Routes.

A predicate is the basic unit of expressions code which takes the following form:

```
http.path ^= "/foo/bar"
```

This predicate example has the following structure:
* `http.path`: Field
* `^=`: Operator
* `"/foo/bar"`: Constant value

Predicates are made up of smaller units that you can configure:

<!--vale off-->
{% table %}
columns:
  - title: Object
    key: object
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - object: Field
    description: |
      The field contains value extracted from the incoming request. For example, the request path or the value of a header field. The field value could also be absent in some cases. An absent field value will always cause the predicate to yield `false` no matter the operator. The field always displays to the left of the predicate.
    example: |
      `http.path`
  - object: Constant value
    description: |
      The constant value is what the field is compared to based on the provided operator. The constant value always displays to the right of the predicate.
    example: |
      `"/foo/bar"`
  - object: Operator
    description: |
      An operator defines the desired comparison action to be performed on the field against the provided constant value. The operator always displays in the middle of the predicate, between the field and constant value.
    example: |
      `^=`
  - object: Predicate
    description: |
      A predicate compares a field against a pre-defined value using the provided operator and returns `true` if the field passed the comparison or `false` if it didn't.
    example: |
      `http.path ^= "/foo/bar"`
{% endtable %}
<!--vale on-->


### Field and constant value types

Types define what you can use for a predicate's field and constant value. Expressions language is strongly typed. Operations are only performed
if such an operation makes sense in regard to the actual type of field and constant.

Type conversion at runtime is not supported, either explicitly or implicitly. Types
are always known at the time a route is parsed. An error is returned
if the operator cannot be performed on the provided field and constant.

The expressions language currently supports the following types:

<!-- vale off -->

{% feature_table %}
item_title: Object
columns:
  - title: Description
    key: description
  - title: Field type
    key: field_type
  - title: Constant type
    key: constant_type
features:
  - title: |
      `String`
    description: |
      A string value, always in valid UTF-8. They can be defined with string literal that looks like `"content"`. You can also use the following escape sequences:
      * `\n`: Newline character
      * `\r`: Carriage return character
      * `\t`: Horizontal tab character
      * `\\`: The `\` character
      * `\"`: The `"` character
    field_type: true
    constant_type: true
  - title: |
      `IpCidr`
    description: |
      Range of IP addresses in CIDR format. Can be either IPv4 (`net.src.ip in 192.168.1.0/24`) or IPv6 (`net.src.ip in fd00::/8`). The expressions parser rejects any CIDR literal where the host portion contains any non-zero bits. This means that `192.168.0.1/24` won't pass the parser check because the intention of the author is unclear.
    field_type: false
    constant_type: true
  - title: |
      `IpAddr`
    description: |
      A single IP address in IPv4 Dot-decimal notation (`net.src.ip == 192.168.1.1`), or the standard IPv6 Address Format (`net.src.ip == fd00::1`). Can be either IPv4 or IPv6.
    field_type: true
    constant_type: true
  - title: |
      `Int`
    description: |
      A 64-bit signed integer. There is only one integer type in expressions. All integers are signed 64-bit integers. Integer literals can be written as `12345`, `-12345`, or in hexadecimal format, such as `0xab12ff`, or in octet format like `0751`.
    field_type: true
    constant_type: true
  - title: |
      `Regex`
    description: |
      Regex are written as `String` literals, but they are parsed when the `~` regex operator is present and checked for validity according to the [Rust `regex` crate syntax](https://docs.rs/regex/latest/regex/#syntax). For example, in the following predicate, the constant is parsed as a regex: `http.path ~ r#"/foo/bar/.+"#`
    field_type: false
    constant_type: true
{% endfeature_table %}

<!--vale on-->


In addition, the expressions router also supports one composite type, `Array`. Array types are written as `Type[]`.
For example: `String[]`, `Int[]`. Currently, arrays can only be present in field values. They are used in
case one field could contain multiple values. For example, `http.headers.x` or `http.queries.x`.

#### Matching fields

The following table describes the available matching fields, as well as their associated type when using an expressions-based router.

<!--vale off-->

{% feature_table %}
item_title: Type
columns:
  - title: Type
    key: type
  - title: Available in HTTP Subsystem
    key: http_subsystem
  - title: Available in Stream Subsystem
    key: stream_subsystem
  - title: Description
    key: description
features:
  - title: |
      `net.protocol`
    type: String
    http_subsystem: true
    stream_subsystem: true
    description: |
      Protocol of the route. Roughly equivalent to the `protocols` field on the `Route` entity. **Note:** Configured `protocols` on the `Route` entity are always added to the top level of the generated route but additional constraints can be provided by using the `net.protocol` field directly inside the expression.
  - title: |
      `tls.sni`
    type: String
    http_subsystem: true
    stream_subsystem: true
    description: |
      If the connection is over TLS, the `server_name` extension from the ClientHello packet.
  - title: |
      `http.method`
    type: String
    http_subsystem: true
    stream_subsystem: false
    description: |
      The method of the incoming HTTP request. (for example, `"GET"` or `"POST"`)
  - title: |
      `http.host`
    type: String
    http_subsystem: true
    stream_subsystem: false
    description: |
      The `Host` header of the incoming HTTP request.
  - title: |
      `http.path`
    type: String
    http_subsystem: true
    stream_subsystem: false
    description: |
      The normalized request path according to rules defined in [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986#section-6). This field value does **not** contain any query parameters that might exist.
  - title: |
      `http.path.segments.<segment_index>`
    type: String
    http_subsystem: true
    stream_subsystem: false
    description: |
      A path segment extracted from the incoming (normalized) `http.path` with zero-based index. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.1` will return `"b"`.
  - title: |
      `http.path.segments.<segment_index>_<segment_index>`
    type: String
    http_subsystem: true
    stream_subsystem: false
    description: |
      Path segments extracted from the incoming (normalized) `http.path` within the given closed interval joined by `/`. Indexes are zero-based. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.0_1` will return `"a/b"`.
  - title: |
      `http.path.segments.len`
    type: Int
    http_subsystem: true
    stream_subsystem: false
    description: |
      Number of segments from the incoming (normalized) `http.path`. For example, for request path `"/a/b/c/"` or `"/a/b/c"`, `http.path.segments.len` will return `3`.
  - title: |
      `http.headers.<header_name>`
    type: String[]
    http_subsystem: true
    stream_subsystem: false
    description: |
      The value(s) of request header `<header_name>`. **Note:** The header name is always normalized to the underscore and lowercase form, so `Foo-Bar`, `Foo_Bar`, and `fOo-BAr` all become values of the `http.headers.foo_bar` field.
  - title: |
      `http.queries.<query_parameter_name>`
    type: String[]
    http_subsystem: true
    stream_subsystem: false
    description: |
      The value(s) of query parameter `<query_parameter_name>`.
  - title: |
      `net.src.ip`
    type: IpAddr
    http_subsystem: true
    stream_subsystem: true
    description: |
      IP address of the client.
  - title: |
      `net.src.port`
    type: Int
    http_subsystem: true
    stream_subsystem: true
    description: |
      The port number used by the client to connect.
  - title: |
      `net.dst.ip`
    type: IpAddr
    http_subsystem: true
    stream_subsystem: true
    description: |
      Listening IP address where {{site.base_gateway}} accepts the incoming connection.
  - title: |
      `net.dst.port`
    type: Int
    http_subsystem: true
    stream_subsystem: true
    description: |
      Listening port number where {{site.base_gateway}} accepts the incoming connection.
{% endfeature_table %}

<!--vale on-->

### Operators

An operator defines the desired comparison action to be performed on the field against the provided constant value. The operator always displays in the middle of the predicate, between the field and constant value.

The expressions language supports a rich set of operators that can be performed on various data types.

<!--vale off-->
{% table %}
columns:
  - title: Operator
    key: operator
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - operator: "`==`"
    name: Equals
    description: "Field value is equal to the constant value."
  - operator: "`!=`"
    name: Not equals
    description: "Field value does not equal the constant value."
  - operator: "`~`"
    name: Regex match
    description: "Field value matches regex."
  - operator: "`^=`"
    name: Prefix match
    description: "Field value starts with the constant value."
  - operator: "`=^`"
    name: Postfix match
    description: "Field value ends with the constant value."
  - operator: "`>=`"
    name: Greater than or equal
    description: "Field value is greater than or equal to the constant value."
  - operator: "`>`"
    name: Greater than
    description: "Field value is greater than the constant value."
  - operator: "`<=`"
    name: Less than or equal
    description: "Field value is less than or equal to the constant value."
  - operator: "`<`"
    name: Less than
    description: "Field value is less than the constant value."
  - operator: "`in`"
    name: In
    description: |
      Field value is inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. 
      <br><br>
      For example, `net.src.ip in 192.168.0.0/24` only returns `true` if the value of `net.src.ip` is within `192.168.0.0/24`.
  - operator: "`not in`"
    name: Not in
    description: |
      Field value is not inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. 
      <br><br>
      For example, `net.src.ip in 192.168.0.0/24` only returns `true` if the value of `net.src.ip` is within `192.168.0.0/24`.
  - operator: "`contains`"
    name: Contains
    description: |
      Field value contains the constant value. This operator is used to check the existence of a string inside another string. 
      <br><br>
      For example, `http.path contains \"foo\"` returns `true` if `foo` can be found anywhere inside `http.path`. This will match an `HTTP.path` that looks like `/foo`, `/abc/foo`, or `/xfooy`, for example.
  - operator: "`&&`"
    name: And
    description: "Returns `true` if **both** expressions on the left and right side evaluates to `true`."
  - operator: "`||`"
    name: Or
    description: "Returns `true` if **any** expressions on the left and right side evaluates to `true`."
  - operator: "`(Expression)`"
    name: Parenthesis
    description: "Groups expressions together to be evaluated first."
  - operator: "`!`"
    name: Not
    description: |
      Negates the result of a parenthesized expression. 
      <br><br>
      The `!` operator can only be used with parenthesized expression like `!(foo == 1)`, it **cannot** be used with a bare predicate like `! foo == 1`."
{% endtable %}
<!--vale on-->

### Allowed type and operator combinations

Depending on the field type, only certain content types and operators are supported. 

<!--vale off-->
{% table %}
columns:
  - title: Field type
    key: field
  - title: Supported content types and their supported operators
    key: operators
rows:
  - field: "`String`"
    operators: |
      * `String`: `==`, `!=`, `~`, `^=`, `=^`, `contains`
      * `Regex`: `~`
  - field: "`IpAddr`"
    operators: |
      * `IpCidr`: `in`, `not in`
      * `IpAddr`: `==`
  - field: "`Int`"
    operators: |
      * `Int`: `==`, `!=`, `>=`, `>`, `<=`, `<`
  - field: "`Expression`"
    operators: |
      * `Regex`: `&&`, `||`
{% endtable %}
<!--vale on-->

{:.info}
> **Notes:** 
* The `~` operator is described as supporting both `String ~ String` and `String ~ Regex`.
In reality, `Regex` constant values can only be written as `String` on the right hand side.
The presence of `~` operators treats the string value as a regex.
Even with the `~` operator, `String` escape rules described previously still apply and it
is almost always easier to use raw string literals for the `~` operator.
* The `~` operator does not automatically anchor the regex to the beginning of the input.
Meaning `http.path ~ r#"/foo/\d"#` could match a path like `/foo/1` or `/some/thing/foo/1`.
If you want to match from the beginning of the string (anchoring the regex), then you must
manually specify it with the `^` meta-character. For example, `http.path ~ r#"^/foo/\d"#`.
* Operator behavior differs when performing IP address-related comparisons.
  Different families of address types for the field and constant value will
  cause the predicate to return the following values:
  * Using `==` or `in`: Returns `false` at runtime.
  * Using `not in`: Returns `true` at runtime.

## Example expressions

The following tables contain examples of different types of expressions.

### HTTP examples 

The following expressions can be used to match HTTP requests.

<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Example expression
    key: expression
  - title: Description
    key: description
rows:
  - name: Prefix-based path matching
    expression: |
      `http.path ^= "/foo/bar"` 
    description: "Matches HTTP requests that have a path starting with `/foo/bar`."
  - name: Regex-based path matching
    expression: |
      `http.path ~ r#"/foo/bar/\d+"#`
    description: "Matches HTTP request paths against a regular expression."
  - name: Case-insensitive path matching
    expression: |
      `lower(http.path) == "/foo/bar"`
    description: Ignores case when performing the path match.
  - name: |
      Match by header value ("all" style matching).
    expression: |
      `http.headers.x_foo ~ r#"bar\d"#`
    description: |
      If there are multiple header values for `X-Foo` and the client sends more than one `X-Foo` header with different values, the above example ensures that **each** instance of the value matches the regex `r#"bar\d"#`.
      This is called "all" style matching.
  - name: |
      Match by header value ("any" style matching)
    expression: |
      `any(http.headers.x_foo) ~ r#"bar\d"#`
    description: |
      Returns `true` for the predicate as soon as any of the values pass the comparison. 
      Can be combined with other transformations, like `lower()`.
  - name: Regex captures
    expression: |
      `http.path ~ r#"/foo/(?P<component>.+)"#`
    description: |
      You can define regex capture groups in any regex operation, which will be made available later for plugins to use. Currently, this is only supported with the `http.path` field. 
      The matched value of `component` will be made available later to plugins such as [Request Transformer Advanced](/plugins/request-transformer-advanced/).
{% endtable %}
<!--vale on-->



### TCP, TLS, and UDP examples

The following expressions can be used to match TCP, TLS, and UDP requests.

<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Example expression
    key: expression
  - title: Description
    key: description
rows:
  - name: Match by source IP and destination port
    expression: |
      `net.src.ip in 192.168.1.0/24 && net.dst.port == 8080`
    description: |
      This matches all clients in the `192.168.1.0/24` subnet and the destination port (which is listened to by {{site.base_gateway}}) is `8080`. IPv6 addresses are also supported.
  - name: "Match by SNI (for TLS routes)"
    expression: |
      `tls.sni =^ ".example.com"` 
    description: |
      This matches all TLS connections with the `.example.com` SNI ending.
{% endtable %}
<!--vale on-->
