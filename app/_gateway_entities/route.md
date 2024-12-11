---
title: Routes
content_type: reference
entities:
  - route

description: A Route is a path to a resource within an upstream application.

related_resources:
  - text: Gateway Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Expressions router
    url: /gateway/routing/expressions/

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

* **Protocols:** The protocol used to communicate with the upstream application.
* **Hosts:** Lists of domains that match a Route
* **Methods:** HTTP methods that match a Route
* **Headers:** Lists of values that are expected in the header of a request
* **Redirect status codes:** HTTPS status codes
* **Tags:** Optional set of strings to group Routes with

The following diagram shows how Routes work:

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

## Route and Service interaction

Routes, in conjunction with [Services](/gateway/entities/service/), let you expose your Services to applications with {{site.base_gateway}}. {{site.base_gateway}} abstracts the Service from the applications by using Routes. Since the application always uses the Route to make a request, changes to the Services, like versioning, don’t impact how applications make the request. Routes also allow the same Service to be used by multiple applications and apply different policies based on the Route used.

For example, if you have an external application and an internal application that need to access the `example_service` Service, but the external application should be limited in how often it can query the Service to assure no denial of service. If a rate limit policy is configured for the Service when the internal application calls the Service, the internal application is limited as well. Routes can solve this problem.

In the example above, two Routes can be created, say `/external` and `/internal`, and both of them can point to `example_service`. You can configure a policy to limit how often the `/external` Route is used and it can be communicated to the external client for use. When the external client tries to access the Service via {{site.base_gateway}} using `/external`, they're rate limited. But when the internal client accesses the Service using {{site.base_gateway}} using `/internal`, the internal client isn't limited.

## How routing works

For each incoming request, {{site.base_gateway}} must determine which service gets to handle it based on the Routes that are defined. In general, the router orders all defined Routes by their priority and
uses the highest priority matching Route to handle a request. If there
are multiple matching Routes with the same priority, it is not defined
which of the matching Routes will be used and {{site.base_gateway}}
will use either of them according to how its internal data structures
are organized.

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

The routing method you should use depends on your {{site.base_gateway}} version:

| {{site.base_gateway}} version | Routing method | Description |
|-------------------------------|----------------|-------------|
| All | Traditional compatibility | Only recommended for anyone running {{site.base_gateway}} 2.9.x or earlier. The original routing method for {{site.base_gateway}}. |
| 3.0.x or later | [Expressions router](/gateway/routing/expressions/) | The recommended method for anyone running {{site.base_gateway}} 3.0.x or later. Can be run in both `traditional_compat` and `expressions` modes. |

### Traditional compatibility mode

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

### Expressions router mode

In [`expressions` mode](/gateway/routing/expressions/) when a request comes in, {{site.base_gateway}} evaluates Routes with a higher `priority` number first. The priority is a positive integer that defines the order of evaluation of the router. The larger the priority integer, the sooner a Route will be evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined.

As soon as a Route yields a match, the router stops matching and {{site.base_gateway}} uses the matched Route to [proxy the current request](/).

### Routing performance recommendations

You can use the following recommendations to increase routing performance:

* In `expressions` mode, we recommend putting more likely matched Routes before (as in, higher priority) those that are less frequently matched.
* Regular expressions in Routes use more resources to evaluate than simple prefixes. In installations with thousands of Routes, replacing regular expression with simple prefix can improve throughput and latency of {{site.base_gateway}}. If regex must be used because an exact path match must be performed, using the [expressions router](/gateway/routing/expressions/) will significantly improve {{site.base_gateway}}’s performance in this case.

## Dynamically rewrite request URLs with Routes

Routes can be configured dynamically to rewrite the requested URL to a different URL for the Upstream. Depending on your use case, there are several methods you can use:

| You want to... | Then use... |
|--------|----------|
| Perform a simple URL rewrite, such as renaming your legacy `/api/old/` upstream endpoint to a publicly accessible API endpoint that is now named `/new/api`. | [Set up a Gateway Service with the old path and a Route with new path](/how-to/dynamically-rewrite-simple-request-urls-with-routes/) |
| Perform complex URL rewrite, such as replacing `/api/<function>/old` with `/new/api/<function>`. | [Request Transformer Advanced plugin](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/) |
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
