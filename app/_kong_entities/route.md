---
title: Routes
entities:
  - route

content_type: reference

related_resources:
  - text: Services
    url: /kong-entity/service/
---

## What is a route?

A route is a path to a resource within an upstream application. Routes are added to services to allow access to the underlying application. In Kong Gateway, routes typically map to endpoints that are exposed through the Kong Gateway application. Routes can also define rules that match requests to associated services. Because of this, one route can reference multiple endpoints. A basic route should have a name, path or paths, and reference an existing service.

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
formats:
  - admin-api
  - konnect
  - kic
  - deck
  - ui
{% endentity_example %}
{% endcontentfor %}

## Route and service interaction

Routes, in conjunction with [services](/kong-entities/service/), let you expose your services to applications with Kong Gateway. Kong Gateway abstracts the service from the applications by using routes. Since the application always uses the route to make a request, changes to the services, like versioning, don’t impact how applications make the request. Routes also allow the same service to be used by multiple applications and apply different policies based on the route used.

For example, if you have an external application and an internal application that need to access the example_service service, but the external application should be limited in how often it can query the service to assure no denial of service. If a rate limit policy is configured for the service when the internal application calls the service, the internal application is limited as well. Routes can solve this problem.

In the example above, two routes can be created, say /external and /internal, and both routes can point to example_service. A policy can be configured to limit how often the /external route is used and the route can be communicated to the external client for use. When the external client tries to access the service via Kong Gateway using /external, they are rate limited. But when the internal client accesses the service using Kong Gateway using /internal, the internal client will not be limited.


## How requests are routed
<!-- Should there be a separate reference for the router vs the route entity? -->

For each incoming request, {{site.base_gateway}} must determine which
service gets to handle it based on the routes that are defined.  With
release 3.0, {{site.base_gateway}} introduced a new router that can be
running in two modes, the `traditional_compat` mode, which is
configured like prior releases, and the `expressions` mode which uses
a new configuration scheme. It is recommended that new deployments use
the expressions router as it is more powerful and expressive.

The default mode of the router is `traditional_compat` and the
following sections describe how it operates. `traditional_compat`
mode is designed to behave like the router in versions before
{{site.base_gateway}} 3.x. For a description of the `expressions` mode, see
[How to Configure Routes using Expressions](expressions).

In general, the router orders all defined routes by their priority and
uses the highest priority matching route to handle a request. If there
are multiple matching routes with the same priority, it is not defined
which of the matching routes will be used and {{site.base_gateway}}
will use either of them according to how its internal data structures
are organized.

If a route contains prefix or regular expression paths, the priority
of the route will be calculated separately for each of the paths and
requests will be routed accordingly.

In `traditional_compat` mode, the priority of a route is determined as
follows, by the order of descending significance:

1. Priority points
2. Wildcard hosts
3. Header count
4. Regular expressions and prefix paths

### Priority points

For the presence of each of a route's `methods`, `host`, `headers`,
and `snis`, a "priority point" will be added to the route. The number
of "priority points" determines the overall order in which the routes
will be considered. Routes with a higher "priority point" values will
be considered before those with lower values. This means that if one
route has `methods` defined, and second one has `methods` and
`headers` defined, the second one will be considered before the first
one.

### Wildcard hosts

Among the routes with the same "priority point" value, those that have
any wildcard host specification will be considered after routes that
don't have any wildcard host (or no host) specified.

### Header count

The resulting groups are sorted so the routes with a higher number of
specified headers have higher priority than those with a lower number
of headers.

### Regular expressions and prefix paths

Within the resulting groups of routes with equal priority, the router
sorts the routes as follows:

 - Routes that have a regular expression path are considered first and
   are ordered by their `regex_priority` value. Routes with a higher
   `regex_priority` are considered before routes with lower
   `regex_priority` values.
 - Routes that have no regular expression path are ordered by the
   length of their paths. Routes with longer paths are considered
   before routes with shorter paths.

For a route with multiple paths, each path will be considered
separately for priority determination. Effectively, this means that
separate routes exists for each of the paths.

## Regular expressions

Regular expressions used in routes use more resources to evaluate than
simple prefix routes. If many regular expressions must be evaluated
to route a request, the latency introduced by {{site.base_gateway}}
can suffer and its CPU usage can increase. In installations with
thousands of routes, replacing regular expression routes by simple
prefix routes can improve throughput and latency of
{{site.base_gateway}}. If regex must be used because an exact
path match must be performed, using the [expressions router](expressions)
will significantly improve {{site.base_gateway}}'s performance in this case.

Starting with version 3.0, {{site.base_gateway}} uses the regular
expression engine shipped with the [Rust](https://docs.rs/regex/latest/regex/) programming language if the
router is operating in `expressions` or `traditional_compatible` mode.
Prior versions used the
[PCRE library](https://www.pcre.org/original/doc/html/pcrepattern.html)
to evaluate regular expression. While the two engines are largely
compatible, subtle differences exist between the two. Refer to
the documentation pertinent to the engine that you are using if you
have problems getting regular expression routes to work.


## Dynamically rewrite request URLs with routes

Routes can be configured dynamically to rewrite the requested URL to a different URL for the upstream. For example, your legacy upstream endpoint may have a base URI like `/api/old/`. However, you want your publicly accessible API endpoint to now be named `/new/api`. To route the service's upstream endpoint to the new URL, you could set up a service with the path `/api/old/` and a route with the path `/new/api`. 

{{site.base_gateway}} can also handle more complex URL rewriting cases by using regular expression capture groups in the route path and the [Request Transformer Advanced](/hub/kong-inc/request-transformer-advanced/) plugin. For example, this can be used when you must replace `/api/<function>/old` with `/new/api/<function>`.

{{site.base_gateway}} 3.0.x or later ships with a new router. The new router can use regex expression capture groups to describe routes using a domain-specific language called Expressions. Expressions can describe routes or paths as patterns using regular expressions. For more information about how to configure the router using Expressions, see [How to configure routes using expressions](/gateway/{{page.release}}/key-concepts/routes/expressions/).
