---
title: Traditional router

description: "The traditional router is a collection of Routes that are all evaluated against incoming requests until a match can be found."

content_type: reference
layout: reference

products:
  - gateway

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: SNI entity
    url: /gateway/entities/sni/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/

min_version:
  gateway: "3.0"

breadcrumbs:
  - /gateway/

faqs:
  - q: When should I use the traditional router?
    a: | 
      If you are working with APIOps pipelines that manipulate the route using `deck file patch`, we recommend using the JSON format used by the traditional router. 


works_on:
  - on-prem
  - konnect

tags:
- routing
---

The traditional router is {{ site.base_gateway }}'s original routing configuration format. It uses JSON to provide a list of routing criteria, including `host`, `path`, and `headers`.

Routing based on JSON configuration is available when [`router_flavor`](/gateway/configuration/#router-flavor) is set to `traditional_compat` _or_ `expressions` in `kong.conf`.

## Routing criteria

{{site.base_gateway}} supports native proxying of HTTP/HTTPS, TCP/TLS, and GRPC/GRPCS protocols.
Each of these protocols accept a different set of routing attributes:

- `http`: `methods`, `hosts`, `headers`, `paths` (and `snis`, if `https`)
- `tcp`: `sources`, `destinations` (and `snis`, if `tls`)
- `grpc`: `hosts`, `headers`, `paths` (and `snis`, if `grpcs`)

Note that all of these fields are **optional**, but at least **one of them**
must be specified.

For a request to match a route:

- The request **must** include **all** of the configured fields
- The values of the fields in the request **must** match at least one of the
  configured values. While the field configurations accept one or more values,
  a request needs only one of the values to be considered a match.

Let's go through a few examples. Consider a route configured like the following:

```json
{
  "hosts": ["example.com", "foo-service.com"],
  "paths": ["/foo", "/bar"],
  "methods": ["GET"]
}
```

Some of the possible requests matching this route would look like the following:

```http
GET /foo HTTP/1.1
Host: example.com
```

```http
GET /bar HTTP/1.1
Host: foo-service.com
```

```http
GET /foo/hello/world HTTP/1.1
Host: example.com
```

All three of these requests satisfy all the conditions set in the route
definition.

However, the following requests would **not** match the configured conditions:

```http
GET / HTTP/1.1
Host: example.com
```

```http
POST /foo HTTP/1.1
Host: example.com
```

```http
GET /foo HTTP/1.1
Host: foo.com
```

All three of these requests satisfy only two of configured conditions. The
first request's path is not a match for any of the configured `paths`, same for
the second request's HTTP method, and the third request's Host header.

Now that we understand how the routing properties work together, let's explore
each property individually.

### Host header

{{site.base_gateway}} supports routing by arbitrary HTTP headers. A special case of this
feature is routing by the Host header.

Routing a request based on its Host header is the most straightforward way to
proxy traffic through {{site.base_gateway}}, especially since this is the intended usage of the
HTTP Host header. {{site.base_gateway}} makes it easy to do via the `hosts` field of the route
entity.

`hosts` accepts multiple values, which must be comma-separated when specifying
them via the Admin API:

```bash
curl -i -X POST http://localhost:8001/routes/ \
  --header 'Content-Type: application/json' \
  --data '{"hosts":["example.com", "foo-service.com"]}'
```

To satisfy the `hosts` condition of this route, any incoming request from a
client must now have its Host header set to one of:

```
Host: example.com
```

or:

```
Host: foo-service.com
```

Similarly, any other header can be used for routing:

```sh
curl -i -X POST http://localhost:8001/routes/ \
  --data 'headers.region=north'
```

Incoming requests containing a `Region` header set to `North` are routed to
said route.

#### Using wildcard hostnames

To provide flexibility, {{site.base_gateway}} allows you to specify hostnames with wildcards in
the `hosts` field. Wildcard hostnames allow any matching Host header to satisfy
the condition, and thus match a given Route.

Wildcard hostnames **must** contain **only one** asterisk at the leftmost
**or** rightmost label of the domain. For example:

- `*.example.com` would allow Host values such as `a.example.com` and
  `x.y.example.com` to match.
- `example.*` would allow Host values such as `example.com` and `example.org`
  to match.

A complete example would look like this:

```json
{
  "hosts": ["*.example.com", "service.com"]
}
```

Which would allow the following requests to match this route:

```http
GET / HTTP/1.1
Host: an.example.com
```

```http
GET / HTTP/1.1
Host: service.com
```

### Headers

It's possible to route requests by other headers besides `Host`.

To do this, use the `headers` property in your route:

```json
{
  "headers": { "version": ["v1", "v2"] },
  "service": {
    "id": "..."
  }
}
```

Given a request with a header such as:

```http
GET / HTTP/1.1
version: v1
```

This request will be routed through to the Service. The same happens with this one:

```http
GET / HTTP/1.1
version: v2
```

This request isn't routed to the Service:

```http
GET / HTTP/1.1
version: v3
```

{:.info}
> **Note**: The `headers` keys are a logical `AND` and their values a logical `OR`.

### Path

Another way for a route to be matched is via request paths. To satisfy this
routing condition, a client request's normalized path **must** be prefixed with one of the
values of the `paths` attribute.

For example, with a route configured like so:

```json
{
  "paths": ["/service", "/hello/world"]
}
```

The following requests would be matched:

```http
GET /service HTTP/1.1
Host: example.com
```

```http
GET /service/resource?param=value HTTP/1.1
Host: example.com
```

```http
GET /hello/world/resource HTTP/1.1
Host: anything.com
```

For each of these requests, {{site.base_gateway}} detects that their normalized URL path is prefixed with
one of the routes' `paths` values. By default, {{site.base_gateway}} would then proxy the
request upstream without changing the URL path.

When proxying with path prefixes, **the longest paths get evaluated first**.
This allows you to define two routes with two paths, such as `/service` and
`/service/resource`, and ensure that the former doesn't overshadow the latter.

#### Using regex in paths

For a path to be considered a regular expression, it must be prefixed with a `~`:

```
paths: ["~/foo/bar$"]
```

Any path that isn't prefixed with a `~` is considered plain text:

```
"paths": ["/users/\d+/profile", "/following"]
```

For more information about how the router processes regular expressions, see the [routing performance considerations](/gateway/entities/route/#routing-performance-recommendations).

##### Regex evaluation order

The router evaluates routes using the `regex_priority` field of the
`Route` where a route is configured. Higher `regex_priority` values
mean higher priority.

```json
[
  {
    "paths": ["~/status/d+"],
    "regex_priority": 0
  },
  {
    "paths": ["~/version/d+/status/d+"],
    "regex_priority": 6
  },
  {
    "paths": ["/version"]
  },
  {
    "paths": ["~/version/any/"]
  }
]
```

In this scenario, {{site.base_gateway}} evaluates incoming requests against the following
defined URIs, in this order:

1. `/version/\d+/status/\d+`
2. `/status/\d+`
3. `/version/any/`
4. `/version`

Routers with a large number of regexes can consume traffic intended for other rules. 
Regular expressions are much more expensive to build and execute and can't be optimized easily.
You can avoid creating complex regular expressions using the [Router Expressions language](/gateway/routing/expressions/).

If you see unexpected behavior, use the Kong debug header to help track down the source:

1. In `kong.conf`, set [`allow_debug_header=on`](/gateway/configuration/#allow-debug-header).
1. Send `Kong-Debug: 1` in your request headers to indicate the matched route ID in the response headers for
   troubleshooting purposes.

As usual, a request must still match a Route's `hosts` and `methods` properties
as well, and {{site.base_gateway}} traverses your Routes until it finds one that [matches
the most rules](#route-priority).

##### Capture groups

Capture groups are also supported, and the matched group will be extracted
from the path and available for plugins consumption. Consider the
following regex:

```
/version/(?<version>\d+)/users/(?<user>\S+)
```

And the following request path:

```
/version/1/users/john
```

{{site.base_gateway}} considers the request path a match, and if the overall Route is
matched (considering other routing attributes), the extracted capture groups
will be available from the plugins in the `ngx.ctx` variable:

```lua
local router_matches = ngx.ctx.router_matches

-- router_matches.uri_captures is:
-- { "1", "john", version = "1", user = "john" }
```

#### Path matching

Keep the following path matching criteria in mind when configuring paths:

1. **Regex in paths:** For a path to be considered a regular expression, it must be prefixed with a `~`. 
You can avoid creating complex regular expressions using the [Router Expressions language](/gateway/routing/expressions/).
1. **Capture groups:** [Regex capture groups](/gateway/routing/expressions/#example-expressions) are also supported, and the matched group is extracted from the path and available for plugin consumption.
1. **Escaping special characters:** When configuring Routes with regex paths via the Admin API, be sure to URL encode your payload if necessary according to [RFC 3986](https://tools.ietf.org/html/rfc3986).
1. **Normalization behavior:** To prevent Route match bypasses, the incoming request URI from the client is always normalized according to [RFC 3986](https://tools.ietf.org/html/rfc3986) before router matching occurs.

#### Path normalization

To prevent trivial route match bypass, the incoming request URI from the client
is always normalized according to [RFC 3986](https://tools.ietf.org/html/rfc3986)
before router matching occurs. Specifically, the following normalization techniques are
used for incoming request URIs, which are selected because they generally don't change
semantics of the request URI:

1. Percent-encoded triplets are converted to uppercase. For example: `/foo%3a` becomes `/foo%3A`.
2. Percent-encoded triplets of unreserved characters are decoded. For example: `/fo%6F` becomes `/foo`.
3. Dot segments are removed as necessary. For example: `/foo/./bar/../baz` becomes `/foo/baz`.
4. Duplicate slashes are merged. For example: `/foo//bar` becomes `/foo/bar`.

The values in the `paths` attribute of the Route object are also normalized. This is achieved by first determining
if the path is a plain text or regex path. Based on the result, different normalization techniques
are used:
* Plain text route path: Uses the same normalization technique as above, that is, methods 1 through 4.
* Regex route path: Only uses methods 1 and 2. In addition, if the decoded character becomes a regex
meta character, it will be escaped with a backslash.

{{site.base_gateway}} normalizes any incoming request URI before performing router
matches. As a result, any request URI sent over to the upstream services will also
be in normalized form, which preserves the original URI semantics.

### HTTP method

The `methods` field allows matching the requests depending on their HTTP
method. It accepts multiple values. Its default value is empty, where the HTTP
method is not used for routing.

The following route allows routing via `GET` and `HEAD`:

```json
{
  "methods": ["GET", "HEAD"],
  "service": {
    "id": "..."
  }
}
```

This route would be matched with the following requests:

```http
GET / HTTP/1.1
Host: ...
```

```http
HEAD /resource HTTP/1.1
Host: ...
```

This route wouldn't match a `POST` or `DELETE` request. This allows for much more
granularity when configuring plugins on Routes. For example, you might have two routes pointing to the same service: 
one with unlimited unauthenticated `GET` requests, and a second one allowing only authenticated and rate-limited
`POST` requests (by applying the authentication and rate limiting plugins to
those requests).

### Source

{:.info}
> **Note:** This section only applies to TCP and TLS routes.

The `sources` routing attribute allows
matching a route by a list of incoming connection IP and/or port sources.

The following route allows routing via a list of source IP/ports:

```json
{
  "protocols": ["tcp", "tls"],
  "sources": [
    { "ip": "10.1.0.0/16", "port": 1234 },
    { "ip": "10.2.2.2" },
    { "port": 9123 }
  ],
  "id": "..."
}
```

TCP or TLS connections originating from IPs in CIDR range "10.1.0.0/16" or IP
address "10.2.2.2" or Port "9123" would match such route.

### Destination

{:.info}
> **Note:** This section only applies to TCP and TLS routes.

The `destinations` attribute, similarly to `sources`,
allows matching a route by a list of incoming connection IP and/or port, but
uses the destination of the TCP/TLS connection as routing attribute.

### SNI

When using secure protocols (`https`, `grpcs`, or `tls`), a 
[Server Name Indication](/gateway/entities/sni/) can be used as a routing attribute. 
The following route allows routing via SNIs:

```json
{
  "snis": ["foo.test", "example.com"],
  "id": "..."
}
```

Incoming requests with a matching hostname set in the TLS connection's SNI
extension would be routed to this route. 
SNI routing also applies to other protocols carried over TLS, such as HTTPS.
If multiple SNIs are specified in the route, any of them can match the incoming request's SNI.

The SNI is indicated at TLS handshake time and can't be modified after the TLS connection has
been established. This means, for example, that multiple requests reusing the same keepalive connection
will have the same SNI hostname while performing router matches, regardless of the value in the `Host` header.

## Route priority

In `traditional_compat` mode, the priority of a Route is determined as follows, by the order of descending significance:

1. **Priority points:** A priority point is added for every `methods`, `host`, `headers`, and `snis` value that a Route has. 
Routes with higher priority point values are considered before those with lower values.
2. **Wildcard hosts:** Among Routes with the same priority point value, Routes without a wildcard host specified (or no host at all) are prioritized before those that have any wildcard host specification.
3. **Header count:** The resulting groups are sorted so the Routes with a higher number of specified headers have higher priority than those with a lower number of headers.
4. **Regular expressions and prefix paths:** Routes that have a regular expression path are considered first and are ordered by their `regex_priority` value. 
Routes that have no regular expression path are ordered by the length of their paths.
5. **Creation date:** If all of the above are equal, the router chooses the Route that was created first using the Route's `created_at` value.

For example, if two Routes are configured like so:

```json
{
    "hosts": ["example.com"],
    "service": {
        "id": "..."
    }
},
{
    "hosts": ["example.com"],
    "methods": ["POST"],
    "service": {
        "id": "..."
    }
}
```

The second route has a `hosts` field **and** a `methods` field, so it is
evaluated first by {{site.base_gateway}}. By doing so, we avoid the first route "shadowing"
calls intended for the second one.

Thus, this request matches the first route:

```http
GET / HTTP/1.1
Host: example.com
```

And this request matches the second one:

```http
POST / HTTP/1.1
Host: example.com
```

Following this logic, if a third route was to be configured with a `hosts`
field, a `methods` field, and a `paths` field, it would be evaluated first by
{{site.base_gateway}}.

If the rule count for the given request is the same in two routes `A` and
`B`, then the following tiebreaker rules will be applied in the order they
are listed. Route `A` will be selected over `B` if:

- `A` has only plain Host headers and `B` has one or more wildcard
  host headers
- `A` has more non-Host headers than `B`
- `A` has at least one regex path and `B` has only plain paths
- `A`'s longest path is longer than `B`'s longest path
- `A.created_at < B.created_at`
