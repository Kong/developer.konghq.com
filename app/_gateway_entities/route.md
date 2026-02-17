---
title: Routes
content_type: reference
entities:
  - route

description: |
  A Route uses specific URL patterns and HTTP verbs to match incoming requests and pass them to a Gateway Service. 
  This determines which upstream services will process a given request.

related_resources:
  - text: Gateway Service entity
    url: /gateway/entities/service/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Traditional router
    url: /gateway/routing/traditional/
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Plugins that can be scoped to Routes
    url: /gateway/entities/plugin/#supported-scopes-by-plugin
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Traffic control and routing
    url: /gateway/traffic-control-and-routing/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway/control-plane-resource-limits/

next_steps:
  - text: Learn about the Expressions router
    url: /gateway/routing/expressions/
  - text: Learn about the Traditional router
    url: /gateway/routing/traditional/

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

schema:
  api: gateway/admin-ee
  path: /schemas/Route

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

works_on:
  - on-prem
  - konnect

tags:
  - routing
---

## What is a Route? 

Routes fulfill two responsibilities in {{ site.base_gateway }}:

1. Match incoming requests and route them to the correct [Gateway Service](/gateway/entities/service/)
2. Use plugins to transform the request/response proxied using this Route

A Route must be attached to a [Gateway Service](/gateway/entities/service/), and _may_ have one or more [plugins](/gateway/entities/plugin/) attached.

## Route and Gateway Service interaction

Routes, in conjunction with [Gateway Services](/gateway/entities/service/), let you expose upstream services to clients with {{site.base_gateway}}. 
Routes also allow the same client to access multiple applications and apply different policies based on the Route used.

For example, say you have two client applications that need to access the `example_service` Gateway Service: an internal client and an external client.
The *external* client should be limited in how often it can query the Gateway Service to avoid a denial of service. 
If you apply a rate limit policy to the Gateway Service and the *internal* client calls it, the internal client is also limited. Routes can solve this problem.

In this example, you can create two Routes with different hosts to handle the two clients, say `internal.example.com` and `external.example.com`, and point both of them to `example_service`. 
You can configure a policy to limit how often the external Route is used. 
When the external client tries to access the Gateway Service via {{site.base_gateway}} using `external.example.com`, it's rate limited. 
But when the internal client accesses the Gateway Service using {{site.base_gateway}} using `internal.example.com`, the internal client isn't limited.

The following diagram illustrates this example:

<!--vale off -->

{% mermaid %}
flowchart LR
  A(External client
  application)
  B("`Route (external.example.com)`")
  B2(Rate Limiting plugin)
  C("`Service (example-service)`")
  D(Upstream service)
  E(Internal client 
  application)
  F("`Route (internal.example.com)`")

  A --request--> B
  E --request--> F

  subgraph id1 ["`
  **KONG GATEWAY**`"]
    B --> B2 --"10 requests per minute"--> C
    F ---> C
  end

  C --> D

  style id1 rx:10,ry:10

{% endmermaid %}

<!--vale on -->

## Route use cases

Common use cases for Routes:

<!--vale off-->
{% table %}
columns:
  - title: Use Case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: "Rate limiting"
    description: |
      Use Routes to set different rate limits for clients accessing the upstream service via specific paths, for example `/internal` or `/external`. 
      <br><br>
      [Enable a rate limiting plugin on Routes attached to the Service](/plugins/rate-limiting-advanced/)
  - usecase: "Perform a simple URL rewrite"
    description: |
      Use the Routes entity to rename an endpoint. For example, you can rename your legacy `/api/old/` upstream endpoint to a publicly accessible API endpoint named `/new/api`.
  - usecase: "Perform a complex URL rewrite"
    description: |
      Use the Routes entity to rewrite a group of paths, such as replacing `/api/<function>/old` with `/new/api/<function>`. 
      <br><br>
      [Request Transformer Advanced plugin](/plugins/request-transformer-advanced/)
{% endtable %}
<!--vale on-->

## Configuration formats

{{site.base_gateway}} provides two methods to define Routes: the traditional JSON format, and a more powerful DSL-based expressions format. 
The router used is configured via the [`router_flavor`](/gateway/configuration/#router-flavor) property in `kong.conf`.

The router you should use depends on your use case and {{site.base_gateway}} version:
* **[Expressions router](/gateway/routing/expressions/):** The recommended method for anyone running {{site.base_gateway}} 3.4.x or later. Handles complex routing logic efficiently.
* **[Traditional router](/gateway/routing/traditional/):** The original {{ site.base_gateway }} routing configuration format. Provide your matching criteria in JSON format.

Setting `router_flavor` to `expressions` allows you to configure both expression based and JSON based routing criteria at the same time. If an `expression` Route matches, the JSON format router won't run, regardless of the JSON priority set.

To disable the DSL-based format, set `router_flavor` to `traditional_compat`. Only JSON routes will be accepted with this configuration.

## Routing criteria

You can match incoming requests against the following routing criteria:

- Protocols: The protocol used to communicate with the upstream service
- Hosts: Lists of domains that match a Route
- Methods: HTTP methods that match a Route
- Headers: Lists of values that are expected in the header of a request
- Port: The request's source/destination port
- SNI: The server name indicated in a TLS request

For detailed examples of each, see the dedicated [expressions](/gateway/routing/expressions/#how-requests-are-routed-with-the-expressions-router) or [traditional](/gateway/routing/traditional/#routing-criteria) sections.

## How routing works

For each incoming request, {{site.base_gateway}} must determine which Gateway Service will handle it based on the Routes that are defined. 

The {{site.base_gateway}} router orders all defined Routes by their [priority](#priority-matching) and uses the highest priority matching Route to [proxy the request](/gateway/traffic-control/proxying/).

### Priority matching

To maximise performance, the {{site.base_gateway}} router orders all defined Routes by their priority and uses the highest priority matching Route to handle a request. How Routes are prioritized depends on the router mode you're using.

For more information, see the detailed [expressions](/gateway/routing/expressions/#priority-matching) or [traditional](/gateway/routing/traditional/#route-priority) sections.


### Route behavior

The Route entity allows you to configure proxy behavior on a per route basis by setting the `strip_path`, `preserve_host`, and `path_handling` values.

In most cases:
* `strip_path` should be `true` (default)
* `preserve_host` should be `false` (default)
* `path_handling` should be set to `v0`

<!--vale off-->

#### strip_path

<!--vale on-->

It may be desirable to specify a path prefix to match a Route, but not
include it in the upstream request. To do so, use the `strip_path` boolean
property by configuring a Route like so:

```json
{
    "paths": ["/service"],
    "strip_path": true,
    "service": {
        "id": "..."
    }
}
```

Enabling this flag instructs {{site.base_gateway}} that when matching this Route, and proceeding
with the proxying to a service, it should **not** include the matched part of
the URL path in the upstream request's URL. For example, the following
client's request to the above Route:

```http
GET /service/path/to/resource HTTP/1.1
Host: ...
```

This causes {{site.base_gateway}} to send the following upstream request:

```http
GET /path/to/resource HTTP/1.1
Host: ...
```

The same way, if a regex path is defined on a Route that has `strip_path`
enabled, the entirety of the request URL matching sequence will be stripped.
For example:

```json
{
    "paths": ["/version/\d+/service"],
    "strip_path": true,
    "service": {
        "id": "..."
    }
}
```

The following HTTP request matching the provided regex path:

```http
GET /version/1/service/path/to/resource HTTP/1.1
Host: ...
```

Is proxied upstream by {{site.base_gateway}} as:

```http
GET /path/to/resource HTTP/1.1
Host: ...
```

<!--vale off-->

#### preserve_host

<!--vale on-->

When proxying, {{site.base_gateway}}'s default behavior is to set the upstream request's Host
header to the hostname specified in the Gateway Service's `host`. The
`preserve_host` field accepts a boolean flag instructing {{site.base_gateway}} not to do so.

For example, when the `preserve_host` property is not changed and a Route is
configured like so:

```json
{
    "hosts": ["service.com"],
    "service": {
        "id": "..."
    }
}
```

A possible request from a client to {{site.base_gateway}} could be:

```http
GET / HTTP/1.1
Host: service.com
```

{{site.base_gateway}} would extract the Host header value from the Service's `host` property,
and would send the following upstream request:

```http
GET / HTTP/1.1
Host: <my-service-host.com>
```

However, by explicitly configuring a Route with `preserve_host=true`:

```json
{
    "hosts": ["service.com"],
    "preserve_host": true,
    "service": {
        "id": "..."
    }
}
```

And assuming the same request from the client:

```http
GET / HTTP/1.1
Host: service.com
```

{{site.base_gateway}} would preserve the Host on the client request and would send the following
upstream request instead:

```http
GET / HTTP/1.1
Host: service.com
```

<!--vale off-->

#### path_handling

<!--vale on-->

The `path_handling` parameter accepts `v0` or `v1`.

* `v0` is the behavior used in Kong 0.x, 2.x, and 3.x. It treats `service.path`, `route.path` and request path as *segments* of a URL. It will always join them via slashes. Given a Service path `/s`, Route path `/r` and request path `/re`, the concatenated path will be `/s/re`. If the resulting path is a single slash, no further transformation is done to it. If it's longer, then the trailing slash is removed.

* `v1` is the behavior used in Kong 1.x. It treats `service.path` as a *prefix*, and ignores the initial slashes of the request and Route paths. Given Service path `/s`, Route path `/r` and request path `/re`, the concatenated path will be `/sre`.

{:.warning}
> `path_handling` v1 is not supported in the `expressions` router and may be removed in a future version of {{ site.base_gateway }}. We **strongly** recommend using `v0`.

Both versions of the algorithm detect "double slashes" when combining paths, replacing them by single
slashes.

{% details %}
summary: |
  **Expand this block to see a table showing detailed `v0` and `v1` examples**
content: |
  <table>
    <thead>
      <tr>
        <th>service.path</th>
        <th>route.path</th>
        <th>request</th>
        <th>route.strip_path</th>
        <th>route.path_handling</th>
        <th>request path</th>
        <th>upstream path</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>/s</td>
        <td>/fv0</td>
        <td>req</td>
        <td>false</td>
        <td>v0</td>
        <td>/fv0/req</td>
        <td>/s/fv0/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv0</td>
        <td>blank</td>
        <td>false</td>
        <td>v0</td>
        <td>/fv0</td>
        <td>/s/fv0</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv1</td>
        <td>req</td>
        <td>false</td>
        <td>v1</td>
        <td>/fv1/req</td>
        <td>/sfv1/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv1</td>
        <td>blank</td>
        <td>false</td>
        <td>v1</td>
        <td>/fv1</td>
        <td>/sfv1</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv0</td>
        <td>req</td>
        <td>true</td>
        <td>v0</td>
        <td>/tv0/req</td>
        <td>/s/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv0</td>
        <td>blank</td>
        <td>true</td>
        <td>v0</td>
        <td>/tv0</td>
        <td>/s</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv1</td>
        <td>req</td>
        <td>true</td>
        <td>v1</td>
        <td>/tv1/req</td>
        <td>/s/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv1</td>
        <td>blank</td>
        <td>true</td>
        <td>v1</td>
        <td>/tv1</td>
        <td>/s</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv0/</td>
        <td>req</td>
        <td>false</td>
        <td>v0</td>
        <td>/fv0/req</td>
        <td>/s/fv0/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv0/</td>
        <td>blank</td>
        <td>false</td>
        <td>v0</td>
        <td>/fv0/</td>
        <td>/s/fv01/</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv1/</td>
        <td>req</td>
        <td>false</td>
        <td>v1</td>
        <td>/fv1/req</td>
        <td>/sfv1/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/fv1/</td>
        <td>blank</td>
        <td>false</td>
        <td>v1</td>
        <td>/fv1/</td>
        <td>/sfv1/</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv0/</td>
        <td>req</td>
        <td>true</td>
        <td>v0</td>
        <td>/tv0/req</td>
        <td>/s/req</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv0/</td>
        <td>blank</td>
        <td>true</td>
        <td>v0</td>
        <td>/tv0/</td>
        <td>/s/</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv1/</td>
        <td>req</td>
        <td>true</td>
        <td>v1</td>
        <td>/tv1/req</td>
        <td>/sreq</td>
      </tr>
      <tr>
        <td>/s</td>
        <td>/tv1/</td>
        <td>blank</td>
        <td>true</td>
        <td>v1</td>
        <td>/tv1/</td>
        <td>/s</td>
      </tr>
    </tbody>
  </table>
{% enddetails %}

### Routing performance recommendations

You can use the following recommendations to increase routing performance:

* In `expressions` mode, we recommend putting more likely matched Routes before (as in, higher priority) those that are less frequently matched.
* Regular expressions in Routes use more resources to evaluate than simple prefixes. In installations with thousands of Routes, replacing a regular expression with simple prefix can improve throughput and latency of {{site.base_gateway}}. If a regex must be used because an exact path match must be performed, using the [expressions router](/gateway/routing/expressions/) will significantly improve {{site.base_gateway}}’s performance in this case.

## TLS Route configuration

The Routes entity can dynamically serve TLS certificates on a per-connection basis. TLS certificates are managed by two resources: 

* [Certificates](/gateway/entities/certificate/)
* [SNIs](/gateway/entities/sni/)

To do this, create a Certificate associated with an SNI, and then create a secure Route that uses the Certificate:

{% entity_example %}
type: route
data:
  name: example-route
  host: "*.tls-example.com"
  protocol: 
    - https
    - tls
  paths:
    - "/mock"
  snis: 
    - "my-sni"
{% endentity_example %}

In this case, the Certificate is already associated with the SNI, so by default it will apply to the Route. Alternatively you can use an [SNI Wildcard](/gateway/entities/sni/#sni-routing) with the Certificate to automatically apply it to the existing Route.

### Proxying TLS passthrough traffic

{{site.base_gateway}} supports TLS passthrough. {{site.base_gateway}} uses the connecting SNI extension to find the matching Route and Service when forwarding a TLS request upstream.
The Route configuration to proxy TLS traffic is unique to every deployment, but the two main configuration variables are: 

* Create a Route with the `tls_passthrough` protocol and assign an SNI. 
* Create a Service, associated with the Route, with the protocol set to `tcp`.

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
