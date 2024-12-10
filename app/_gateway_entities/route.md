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

### Proxying?



## Dynamically rewrite request URLs with routes

Routes can be configured dynamically to rewrite the requested URL to a different URL for the upstream. Depending on your use case, there are several methods you can use:

| You want to... | Then use... |
|--------|----------|
| Perform a simple URL rewrite, such as renaming your legacy `/api/old/` upstream endpoint to a publicly accessible API endpoint that is now named `/new/api`. | [Set up a service with the old path and a route with new path](/) |
| Performa complex URL rewrite, such as replacing `/api/<function>/old` with `/new/api/<function>`. | [Request Transformer Advanced plugin](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/) |
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
