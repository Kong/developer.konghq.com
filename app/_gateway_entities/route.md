---
title: Routes
content_type: reference
entities:
  - route

description: A Route is a path to a resource within an upstream application.

related_resources:
  - text: Gateway Services
    url: /gateway/entities/service/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Upstreams entity
    url: /gateway/entities/upstream/
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxy/

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

schema:
  api: gateway/admin-ee
  path: /schemas/Route

---

## What is a Route? 

{{page.description}} [Gateway Services](/gateway/entities/service/) can store collections of objects like plugin configurations, and policies, and they can be associated with Routes. In {{site.base_gateway}}, Routes typically map to endpoints that are exposed through the {{site.base_gateway}} application. Routes determine how (and if) requests are sent to their Services after they reach {{site.base_gateway}}. Where a Service represents the backend API, a Route defines what is exposed to clients. 

Routes can also define rules that match requests to associated Services. Because of this, one Route can reference multiple endpoints. Once a Route is matched, {{site.base_gateway}} proxies the request to its associated Service. A basic Route should have a name, path or paths, and reference an existing Service.

When you configure Routes, you can also specify the following:

* **Protocols:** The protocol used to communicate with the [Upstream](/gateway/entities/upstream/) application.
* **Hosts:** Lists of domains that match a Route
* **Methods:** HTTP methods that match a Route
* **Headers:** Lists of values that are expected in the header of a request
* **Redirect status codes:** HTTPS status codes
* **Tags:** Optional set of strings to group Routes with

Use Routes if you don't need to load balance traffic to hosts. If you need to do load balancing between hostnames, configure your hosts in an [Upstream](/gateway/entities/upstream/) instead.

## Route and Service interaction

Routes, in conjunction with [Services](/gateway/entities/service/), let you expose your Services to applications with {{site.base_gateway}}. {{site.base_gateway}} abstracts the Service from the applications by using Routes. Since the application always uses the Route to make a request, changes to the Services, like versioning, don’t impact how applications make the request.

The following diagram shows how Routes interact with other {{site.base_gateway}} entities:

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Service
  (example-service)`")
  D(Upstream 
  application)
  
  A <--requests
  responses--> B
  subgraph id1 ["`
  **KONG GATEWAY**`"]
    B <--requests
    responses--> C
  end
  C <--requests
  responses--> D

  style id1 rx:10,ry:10
  
{% endmermaid %}

Routes also allow the same Service to be used by multiple applications and apply different policies based on the Route used.

For example, say you have an external application and an internal application that need to access the `example_service` Service, but the *external* application should be limited in how often it can query the Service to avoid a denial of service. If you apply a rate limit policy to the Service and the *internal* application calls it, the internal application is also limited. Routes can solve this problem.


In this example, you can create two Routes to handle the two applications, say `/external` and `/internal`, and point both of them to `example_service`. 
You can configure a policy to limit how often the `/external` Route is used. 
When the external application tries to access the Service via {{site.base_gateway}} using `/external`, they're rate limited. 
But when the internal application accesses the Service using {{site.base_gateway}} using `/internal`, the internal application isn't limited.

## How routing works

{% include_cached /content/how-routing-works.md %}

### Matching routing attributes

When you configure a Route, you must define certain attributes that {{site.base_gateway}} will use to match incoming requests.

{{site.base_gateway}} supports native proxying of HTTP/HTTPS, TCP/TLS, and GRPC/GRPCS protocols. Each of these protocols accept a different set of routing attributes:
- `http`: `methods`, `hosts`, `headers`, `paths` (and `snis`, if `https`)
- `tcp`: `sources`, `destinations` (and `snis`, if `tls`)
- `grpc`: `hosts`, `headers`, `paths` (and `snis`, if `grpcs`)

Note that all of these fields are **optional**, but at least **one of them**
must be specified.

For a request to match a Route:

- The request **must** include **all** of the configured fields
- The values of the fields in the request **must** match at least one of the
  configured values (While the field configurations accepts one or more values,
  a request needs only one of the values to be considered a match)

The following sections describe specifics about the headers, paths, and SNI attributes you can configure. For information about additional attributes you can configure for Route matching, see the [Routes schema](/gateway/entities/route/#schema).

#### Request header

**Supported protocols:** `http`and `grpc`

Routing a request based on its Host header is the most straightforward way to proxy traffic through Kong Gateway, especially since this is the intended usage of the HTTP Host header. `hosts` accepts multiple values, which must be comma-separated when specifying them via the Admin API, and is represented in a JSON payload. You can also use wildcards in hostnames. Wildcard hostnames must contain only one asterisk at the leftmost or rightmost label of the domain.

When proxying, Kong Gateway’s default behavior is to set the Upstream request’s Host header to the hostname specified in the Service’s `host`. The `preserve_host` field accepts a boolean flag instructing Kong Gateway not to do so.

| Example config | Example routing request matches |
|---------------|--------------------------------|
| `{"hosts":["example.com", "foo-service.com"]}` | `Host: example.com` and `Host: foo-service.com` | 
| `headers.region=north` | `Region: North` |
| `"hosts": ["*.example.com", "example.*"]` | `Host: an.example.com` and `Host: example.org` |
| `"hosts": ["service.com"], "preserve_host": true,` | `Host: service.com` |
| `"headers": { "version": ["v1", "v2"] }` | `version: v1` |

#### Request path

**Supported protocols:** `http` and `grpc`

Another way for a Route to be matched is via request paths. To satisfy this routing condition, a client request’s normalized path must be prefixed with one of the values of the `paths` attribute.

Kong Gateway detects that the request's normalized URL path is prefixed with one of the Routes’ `paths` values. By default, Kong Gateway would then proxy the request Upstream without changing the URL path.

When proxying with path prefixes, the longest paths get evaluated first. This allow you to define two Routes with two paths: `/service` and `/service/resource`, and ensure that the former does not “shadow” the latter.

* **Regex in paths:** For a path to be considered a regular expression, it must be prefixed with a `~`. For example: `paths: ["~/foo/bar$"]`. 
* **Evaluation order:** The router evaluates Routes using the `regex_priority` field of the Route where a Route is configured. Higher `regex_priority` values mean higher priority. If you have the following paths configured:
  ```sh
  [
    {
        "paths": ["~/status/\d+"],
        "regex_priority": 0
    },
    {
        "paths": ["~/version/\d+/status/\d+"],
        "regex_priority": 6
    },
    {
        "paths": /version,
    },
    {
        "paths": ["~/version/any/"],
    }
  ]
  ```
  They are evaluated in the following order:
  1. `/version/\d+/status/\d+`
  1. `/status/\d+`
  1. `/version/any/`
  1. `/version`
* **Capturing groups:** Capturing groups are also supported, and the matched group will be extracted from the path and available for plugins consumption.
* **Escaping special characters:** When configuring Routes with regex paths via the Admin API, be sure to URL encode your payload if necessary according to [RFC 3986](https://tools.ietf.org/html/rfc3986).
* **`strip_path` property:** If you want to specify a path prefix to match a Route, but not include it in the Upstream request, you can set the `strip_path` boolean property to `true`.
* **Normalization behavior:** To prevent trivial Route match bypass, the incoming request URI from client
is always normalized according to [RFC 3986](https://tools.ietf.org/html/rfc3986)
before router matching occurs. Specifically, the following normalization techniques are
used for incoming request URIs, which are selected because they generally do not change
semantics of the request URI:
  1. Percent-encoded triplets are converted to uppercase.  For example: `/foo%3a` becomes `/foo%3A`.
  2. Percent-encoded triplets of unreserved characters are decoded. For example: `/fo%6F` becomes `/foo`.
  3. Dot segments are removed as necessary.  For example: `/foo/./bar/../baz` becomes `/foo/baz`.
  4. Duplicate slashes are merged. For example: `/foo//bar` becomes `/foo/bar`.

  Regex Route paths only use methods 1 and 2. In addition, if the decoded character becomes a regex meta character, it will be escaped with backslash.

Routers with a large number of regexes can consume traffic intended for other rules. Regular expressions are much more expensive to build and execute and can’t be optimized easily. You can avoid creating complex regular expressions using the [Router Expressions language](/gateway/routing/expressions/).

| Example config | Example routing request matches |
|---------------|--------------------------------|
| `"paths": ["/service", "/hello/world"]` | `GET /service HTTP/1.1 Host: example.com`, `GET /service/resource?param=value HTTP/1.1 Host: example.com`, and `GET /hello/world/resource HTTP/1.1 Host: anything.com` |
| `paths: ["~/foo/bar$"]` | `GET /foo/bar HTTP/1.1 Host: example.com` |
| `/version/(?<version>\d+)/users/(?<user>\S+)` | `/version/1/users/john` |

#### Request SNI

**Supported protocols:** `https`, `grpcs`, or `tls`

You can use a [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) as a routing attribute. 

Incoming requests with a matching hostname set in the TLS connection’s SNI extension would be Routed to this Route. As mentioned, SNI routing applies not only to TLS, but also to other protocols carried over TLS, such as HTTPS. If multiple SNIs are specified in the Route, any of them can match with the incoming request’s SNI (or relationship between the names).

The SNI is indicated at TLS handshake time and can't be modified after the TLS connection has been established. This means keepalive connections that send multiple requests will have the same SNI hostnames while performing router match (regardless of the `host` header).

Creating a Route with a mismatched SNI and `host` header matcher is possible, but generally discouraged.


### Routing priority 

If multiple Routes match an incoming request, the {{site.base_gateway}} router then orders all defined Routes by their priority and uses the highest priority matching Route to handle a request.

If the rule count for the given request is the same in two Routes `A` and
`B`, then the following tiebreaker rules will be applied in the order they
are listed. Route `A` will be selected over `B` if:

* `A` has only "plain" Host headers and `B` has one or more "wildcard"
  host headers
* `A` has more non-Host headers than `B`.
* `A` has at least one "regex" paths and `B` has only "plain" paths.
* `A`'s longest path is longer than `B`'s longest path.
* `A.created_at < B.created_at`

The routing method you should use depends on your {{site.base_gateway}} version:

| Recommended {{site.base_gateway}} version | Routing method | Description |
|-------------------------------|----------------|-------------|
| 2.9.x or earlier | Traditional compatibility | Only recommended for anyone running {{site.base_gateway}} 2.9.x or earlier. The original routing method for {{site.base_gateway}}. |
| 3.0.x or later | [Expressions router](/gateway/routing/expressions/) | The recommended method for anyone running {{site.base_gateway}} 3.0.x or later. Can be run in both `traditional_compat` and `expressions` modes. |

#### Traditional compatibility mode

In `traditional_compat` mode, the priority of a Route is determined as
follows, by the order of descending significance:

1. **Priority points:** For the presence of each of a Route's `methods`, `host`, `headers`, and `snis`, a "priority point" is added. The number of "priority points" determines the overall order in which the Routes will be considered. Routes with a higher "priority point" values will be considered before those with lower values. This means that if one Route has `methods` defined, and second one has `methods` and `headers` defined, the second one will be considered before the first one.
2. **Wildcard hosts:** Among Routes with the same "priority point" value, those that have any wildcard host specification will be considered after those that don't have any wildcard host (or no host) specified.
3. **Header count:** The resulting groups are sorted so the Routes with a higher number of specified headers have higher priority than those with a lower number of headers.
4. **Regular expressions and prefix paths:** Within the resulting groups of Routes with equal priority, the router sorts them as follows:
  - Routes that have a regular expression path are considered first and are ordered by their `regex_priority` value. Routes with a higher `regex_priority` are considered before those with lower `regex_priority` values.
  - Routes that have no regular expression path are ordered by the length of their paths. Routes with longer paths are considered before those with shorter paths.
  
  For a Route with multiple paths, each path will be considered separately for priority determination. Effectively, this means that separate Routes exist for each of the paths.

As soon as a Route yields a match, the router stops matching and {{site.base_gateway}} uses the matched Route to [proxy the current request](/).

#### Expressions router mode

In [`expressions` mode](/gateway/routing/expressions/) when a request comes in, {{site.base_gateway}} evaluates Routes with a higher `priority` number first. The priority is a positive integer that defines the order of evaluation of the router. The larger the priority integer, the sooner a Route will be evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined.

As soon as a Route yields a match, the router stops matching and {{site.base_gateway}} uses the matched Route to [proxy the current request](/gateway/traffic-control/proxy/).

### Routing performance recommendations

You can use the following recommendations to increase routing performance:

* In `expressions` mode, we recommend putting more likely matched Routes before (as in, higher priority) those that are less frequently matched.
* Regular expressions in Routes use more resources to evaluate than simple prefixes. In installations with thousands of Routes, replacing regular expression with simple prefix can improve throughput and latency of {{site.base_gateway}}. If regex must be used because an exact path match must be performed, using the [expressions router](/gateway/routing/expressions/) will significantly improve {{site.base_gateway}}’s performance in this case.

## Route use cases

Use the following table to help you understand how Routes can be configured for different use cases:

| You want to... | Then use... |
|--------|----------|
| Rate limit internal and external traffic to a Service | [Enable a rate limiting plugin on Routes attached to the Service](/plugins/rate-limiting-advanced/) |
| Perform a simple URL rewrite, such as renaming your legacy `/api/old/` Upstream endpoint to a publicly accessible API endpoint that is now named `/new/api`. | [Set up a Gateway Service with the old path and a Route with new path](/how-to/rewrite-simple-request-urls-with-routes/) |
| Perform a complex URL rewrite, such as replacing `/api/<function>/old` with `/new/api/<function>`. | [Request Transformer Advanced plugin](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/) |
| Describe Routes or paths as patterns using regular expressions. | [Expressions router](/gateway/routing/expressions/) |

## Schema

{% entity_schema %}

## Set up a Route

{% entity_example %}
type: route
data:
  name: example-route
  paths:
    - "/mock"
{% endentity_example %}
