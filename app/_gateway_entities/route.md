---
title: Routes
name: Route
entities:
  - route

description: A route is a path to a resource within an upstream application.

related_resources:
  - text: Services
    url: /gateway/entities/service/
  - text: Routing in Kong Gateway
    url: /gateway/routing/
  - text: Expressions router
    url: /gateway/routing/expressions/

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - ui
    - terraform
---

## What is a route?

{{page.description}} Services can store collections of objects like plugin configurations, and policies, and they can be associated with routes. In {{site.base_gateway}}, routes typically map to endpoints that are exposed through the Kong Gateway application. Routes can also define rules that match requests to associated services. Because of this, one route can reference multiple endpoints. A basic route should have a name, path or paths, and reference an existing service.

You can also configure routes with:

* Protocols: The protocol used to communicate with the upstream application.
* Hosts: Lists of domains that match a route
* Methods: HTTP methods that match a route
* Headers: Lists of values that are expected in the header of a request
* Redirect status codes: HTTPS status codes
* Tags: Optional set of strings to group routes with


{% contentfor setup_entity %}
{% entity_example %}
type: route
data:
  name: example-route
  paths:
    - "/mock"
{% endentity_example %}
{% endcontentfor %}

## Route and service interaction

Routes, in conjunction with [services](/gateway/entities/service/), let you expose your services to applications with Kong Gateway. Kong Gateway abstracts the service from the applications by using routes. Since the application always uses the route to make a request, changes to the services, like versioning, don’t impact how applications make the request. Routes also allow the same service to be used by multiple applications and apply different policies based on the route used.

For example, if you have an external application and an internal application that need to access the example_service service, but the external application should be limited in how often it can query the service to assure no denial of service. If a rate limit policy is configured for the service when the internal application calls the service, the internal application is limited as well. Routes can solve this problem.

In the example above, two routes can be created, say /external and /internal, and both routes can point to example_service. A policy can be configured to limit how often the /external route is used and the route can be communicated to the external client for use. When the external client tries to access the service via Kong Gateway using /external, they are rate limited. But when the internal client accesses the service using Kong Gateway using /internal, the internal client will not be limited.

## Dynamically rewrite request URLs with routes

Routes can be configured dynamically to rewrite the requested URL to a different URL for the upstream. For example, your legacy upstream endpoint may have a base URI like `/api/old/`. However, you want your publicly accessible API endpoint to now be named `/new/api`. To route the service's upstream endpoint to the new URL, you could set up a service with the path `/api/old/` and a route with the path `/new/api`. 

{{site.base_gateway}} can also handle more complex URL rewriting cases by using regular expression capture groups in the route path and the [Request Transformer Advanced](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/) plugin. For example, this can be used when you must replace `/api/<function>/old` with `/new/api/<function>`.

{{site.base_gateway}} 3.0.x or later ships with a new router. The new router can use regex expression capture groups to describe routes using a domain-specific language called Expressions. Expressions can describe routes or paths as patterns using regular expressions. For more information about how to configure the router using Expressions, see [How to configure routes using expressions](https://docs.konghq.com/gateway/latest/key-concepts/routes/expressions/).
