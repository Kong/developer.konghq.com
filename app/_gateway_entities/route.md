---
title: Routes
content_type: reference
entities:
  - route

description: A route is a path to a resource within an upstream application.

related_resources:
  - text: Services
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

## What is a route? 

{{page.description}} [Services](/gateway/entities/service/) can store collections of objects like plugin configurations, and policies, and they can be associated with routes. In {{site.base_gateway}}, routes typically map to endpoints that are exposed through the {{site.base_gateway}} application. Routes determine how (and if) requests are sent to their services after they reach {{site.base_gateway}}. Where a service represents the backend API, a route defines what is exposed to clients. 

Routes can also define rules that match requests to associated services. Because of this, one route can reference multiple endpoints. Once a route is matched, {{site.base_gateway}} proxies the request to its associated service. A basic route should have a name, path or paths, and reference an existing service.

When you configure routes, you can also specify the following:

* **Protocols:** The protocol used to communicate with the upstream application.
* **Hosts:** Lists of domains that match a route
* **Methods:** HTTP methods that match a route
* **Headers:** Lists of values that are expected in the header of a request
* **Redirect status codes:** HTTPS status codes
* **Tags:** Optional set of strings to group routes with

The following diagram shows how routes work:

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

## Route and service interaction

Routes, in conjunction with [services](/gateway/entities/service/), let you expose your services to applications with {{site.base_gateway}}. {{site.base_gateway}} abstracts the service from the applications by using routes. Since the application always uses the route to make a request, changes to the services, like versioning, don’t impact how applications make the request. Routes also allow the same service to be used by multiple applications and apply different policies based on the route used.

For example, if you have an external application and an internal application that need to access the `example_service` service, but the external application should be limited in how often it can query the service to assure no denial of service. If a rate limit policy is configured for the service when the internal application calls the service, the internal application is limited as well. Routes can solve this problem.

In the example above, two routes can be created, say `/external` and `/internal`, and both routes can point to `example_service`. A policy can be configured to limit how often the `/external` route is used and the route can be communicated to the external client for use. When the external client tries to access the service via {{site.base_gateway}} using `/external`, they are rate limited. But when the internal client accesses the service using {{site.base_gateway}} using `/internal`, the internal client will not be limited.

## How routing works

For each incoming request, {{site.base_gateway}} must determine which service gets to handle it based on the routes that are defined. In general, the router orders all defined routes by their priority and
uses the highest priority matching route to handle a request. If there
are multiple matching routes with the same priority, it is not defined
which of the matching routes will be used and {{site.base_gateway}}
will use either of them according to how its internal data structures
are organized.

{{site.base_gateway}} supports native proxying of HTTP/HTTPS, TCP/TLS, and GRPC/GRPCS protocols. Each of these protocols accept a different set of routing attributes:
- `http`: `methods`, `hosts`, `headers`, `paths` (and `snis`, if `https`)
- `tcp`: `sources`, `destinations` (and `snis`, if `tls`)
- `grpc`: `hosts`, `headers`, `paths` (and `snis`, if `grpcs`)

Note that all of these fields are **optional**, but at least **one of them**
must be specified.

For a request to match a route:

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

In `traditional_compat` mode, the priority of a route is determined as
follows, by the order of descending significance:

1. **Priority points:** For the presence of each of a route's `methods`, `host`, `headers`, and `snis`, a "priority point" will be added to the route. The number of "priority points" determines the overall order in which the routes will be considered. Routes with a higher "priority point" values will be considered before those with lower values. This means that if one route has `methods` defined, and second one has `methods` and `headers` defined, the second one will be considered before the first one.
2. **Wildcard hosts:** Among the routes with the same "priority point" value, those that have any wildcard host specification will be considered after routes that don't have any wildcard host (or no host) specified.
3. **Header count:** The resulting groups are sorted so the routes with a higher number of specified headers have higher priority than those with a lower number of headers.
4. **Regular expressions and prefix paths:** Within the resulting groups of routes with equal priority, the router sorts the routes as follows:
  - Routes that have a regular expression path are considered first and are ordered by their `regex_priority` value. Routes with a higher `regex_priority` are considered before routes with lower `regex_priority` values.
  - Routes that have no regular expression path are ordered by the length of their paths. Routes with longer paths are considered before routes with shorter paths.
  
  For a route with multiple paths, each path will be considered separately for priority determination. Effectively, this means that separate routes exists for each of the paths.

As soon as a route yields a match, the router stops matching and {{site.base_gateway}} uses the matched route to [proxy the current request](/).

### Expressions router mode

In [`expressions` mode](/gateway/routing/expressions/) when a request comes in, {{site.base_gateway}} evaluates routes with a higher `priority` number first. The priority is a positive integer that defines the order of evaluation of the router. The larger the priority integer, the sooner a route will be evaluated. In the case of duplicate priority values between two routes in the same router, their order of evaluation is undefined.

As soon as a route yields a match, the router stops matching and {{site.base_gateway}} uses the matched route to [proxy the current request](/).

### Routing performance recommendations

You can use the following recommendations to increase routing performance:

* In `expressions` mode, we recommend putting more likely matched routes before (as in, higher priority) less frequently matched routes.
* Regular expressions used in routes use more resources to evaluate than simple prefix routes. In installations with thousands of routes, replacing regular expression routes with simple prefix routes can improve throughput and latency of {{site.base_gateway}}. If regex must be used because an exact path match must be performed, using the [expressions router](/gateway/routing/expressions/) will significantly improve {{site.base_gateway}}’s performance in this case.

## Dynamically rewrite request URLs with routes

Routes can be configured dynamically to rewrite the requested URL to a different URL for the upstream. Depending on your use case, there are several methods you can use:

| You want to... | Then use... |
|--------|----------|
| Perform a simple URL rewrite, such as renaming your legacy `/api/old/` upstream endpoint to a publicly accessible API endpoint that is now named `/new/api`. | [Set up a service with the old path and a route with new path](/how-to/dynamically-rewrite-simple-request-urls-with-routes/) |
| Perform complex URL rewrite, such as replacing `/api/<function>/old` with `/new/api/<function>`. | [Request Transformer Advanced plugin](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/) |
| Describe routes or paths as patterns using regular expressions. | [Expressions router](/gateway/routing/expressions/) |

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
