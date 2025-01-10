---
title: Routes
content_type: reference
entities:
  - route

description: |
  A Route is a path which defines how (and if) requests are passed to Gateway Services and their respective upstream applications based on a set of configured rules.

related_resources:
  - text: Gateway Service entity
    url: /gateway/entities/service/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Upstream entity
    url: /gateway/entities/upstream/

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

A Route is a path to a resource within an upstream application. In {{site.base_gateway}}, Routes typically map to endpoints exposed through [Gateway Services](/gateway/entities/service/). Routes determine how (and if) requests are sent to their Services after they reach {{site.base_gateway}}. Where a Service represents the backend API, a Route defines what is exposed to clients. 

Routes can also define rules that match requests to associated Services. Because of this, one Route can reference multiple endpoints. Once a Route is matched, {{site.base_gateway}} proxies the request to its associated Service. A basic Route should have a name, path or paths, and reference an existing Service.

{% mermaid %}
flowchart LR
  A(API client)
  B("`Route 
  (/mock)`")
  C("`Gateway Service
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

For example, say you have an external application and an internal application that need to access the `example_service` Service, but the *external* application should be limited in how often it can query the Service to avoid a denial of service. If you apply a rate limit policy to the Service and the *internal* application calls it, the internal application is also limited. Routes can solve this problem.

In this example, you can create two Routes to handle the two applications, say `/external` and `/internal`, and point both of them to `example_service`. 
You can configure a policy to limit how often the `/external` Route is used. 
When the external application tries to access the Service via {{site.base_gateway}} using `/external`, it's rate limited. 
But when the internal application accesses the Service using {{site.base_gateway}} using `/internal`, the internal application isn't limited.

The following diagram illustrates this example:

{% mermaid %}
flowchart LR
  A(External application)
  B("`Route (/external)`")
  C("`Service (example-service)`")
  D(Upstream application)
  E(Internal application)
  F("`Route (/internal)`")
  
  subgraph id1 ["`
  **KONG GATEWAY**`"]
    B <--requests
  responses--> C
    F <--requests
  responses--> C
  end

  A <--requests
  responses--> B
  E <--requests
  responses--> F

  C <--requests
  responses--> D

  B -.->|Rate Limiting plugin| C

  style id1 rx:10,ry:10

{% endmermaid %}

## Route use cases

Common use cases for Routes:

| You want to... | Then use... |
|--------|----------|
| Rate limiting | Use Routes to set different rate limits for clients accessing the upstream application via specific paths, for example `/internal` or `/external`. <br><br>[Enable a rate limiting plugin on Routes attached to the Service](/plugins/rate-limiting-advanced/) |
| Perform a simple URL rewrite | Use the Routes entity to rename an endpoint. For example, you can rename your legacy `/api/old/` upstream endpoint to a publicly accessible API endpoint named `/new/api`. <br><br> [Set up a Gateway Service with the old path and a Route with new path](/how-to/rewrite-simple-request-urls-with-routes/) |
| Perform a complex URL rewrite | Use the Routes entity to rewrite a group of paths, such as replacing `/api/<function>/old` with `/new/api/<function>`. <br><br> [Request Transformer Advanced plugin](/plugins/request-transformer-advanced/) |
| Describe paths as patterns using regular expressions | [Expressions router](/gateway/routing/expressions/) |

## How routing works

For each incoming request, {{site.base_gateway}} must determine which Service gets to handle it based on the Routes that are defined. As soon as a Route yields a match, the router stops matching and {{site.base_gateway}} uses the matched Route to [proxy the current request](/gateway/traffic-control/proxying/).

If multiple Routes match, {{site.base_gateway}} handles routing in the following order:

1. {{site.base_gateway}} finds Routes that match the request by comparing the defined routing attributes with the attributes in the request. 
1. If multiple Routes match, the {{site.base_gateway}} router then orders all defined Routes by their [priority](#priority-matching) and uses the highest priority matching Route to handle a request. 

{{site.base_gateway}} provides two different routers, enabled via the `router_flavor` property in `kong.conf`. The router you should use depends on your use case and {{site.base_gateway}} version:
* **[Expressions router](/gateway/routing/expressions/):** The recommended method for anyone running {{site.base_gateway}} 3.4.x or later. Can be run in both `traditional_compat` and `expressions` modes. Handles complex routing logic and regex in Routes.
* **Traditional compatibility router:** Only recommended for anyone running {{site.base_gateway}} 2.9.x or earlier. The default routing method for {{site.base_gateway}}. Doesn't handle complex routing logic.

### Path matching

Keep the following path matching criteria in mind when configuring paths:

* **Regex in paths:** For a path to be considered a regular expression, it must be prefixed with a `~`. You can avoid creating complex regular expressions using the [Router Expressions language](/gateway/routing/expressions/).
* **Capturing groups:** Capturing groups are also supported, and the matched group will be extracted from the path and available for plugins consumption.
* **Escaping special characters:** When configuring Routes with regex paths via the Admin API, be sure to URL encode your payload if necessary according to [RFC 3986](https://tools.ietf.org/html/rfc3986).
* **Normalization behavior:** To prevent trivial Route match bypass, the incoming request URI from client
is always normalized according to [RFC 3986](https://tools.ietf.org/html/rfc3986)
before router matching occurs.

  Regex Route paths only use methods 1 and 2. In addition, if the decoded character becomes a regex meta character, it will be escaped with backslash.

### Priority matching

If multiple Routes match, the {{site.base_gateway}} router then orders all defined Routes by their priority and uses the highest priority matching Route to handle a request. How Routes are prioritized depends on the router mode you're using.

#### Traditional compatibility mode

In `traditional_compat` mode, the priority of a Route is determined as
follows, by the order of descending significance:

1. **Priority points:** A priority point is added for every `methods`, `host`, `headers`, and `snis` value that a Route has. Routes with higher priority point values will be considered before those with lower values.
2. **Wildcard hosts:** Among Routes with the same priority point value, Routes without a wildcard host specified (or no host at all) are prioritized before those that have any wildcard host specification.
3. **Header count:** The resulting groups are sorted so the Routes with a higher number of specified headers have higher priority than those with a lower number of headers.
4. **Regular expressions and prefix paths:** Routes that have a regular expression path are considered first and are ordered by their `regex_priority` value. Routes that have no regular expression path are ordered by the length of their paths. 

When two Routes have the same path, {{site.base_gateway}} uses a tiebreaker. For example, if the rule count for the given request is the same for both Routes `A` and `B`, then the following tiebreaker rules are applied in the order they are listed. Route `A` will be selected over `B` if:
  * `A` has only plain Host headers and `B` has one or more wildcard
  host headers
  * `A` has more non-Host headers than `B`
  * `A` has at least one regex path and `B` has only plain paths
  * `A`'s longest path is longer than `B`'s longest path
  * `A.created_at < B.created_at`

#### Expressions router mode

In [`expressions` mode](/gateway/routing/expressions/), when a request comes in, {{site.base_gateway}} evaluates Routes with a higher `priority` number first. The priority is a positive integer that defines the order of evaluation of the router. The larger the priority integer, the sooner a Route will be evaluated. In the case of duplicate priority values between two Routes in the same router, their order of evaluation is undefined.

### Routing performance recommendations

You can use the following recommendations to increase routing performance:

* In `expressions` mode, we recommend putting more likely matched Routes before (as in, higher priority) those that are less frequently matched.
* Regular expressions in Routes use more resources to evaluate than simple prefixes. In installations with thousands of Routes, replacing a regular expression with simple prefix can improve throughput and latency of {{site.base_gateway}}. If a regex must be used because an exact path match must be performed, using the [expressions router](/gateway/routing/expressions/) will significantly improve {{site.base_gateway}}’s performance in this case.

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
