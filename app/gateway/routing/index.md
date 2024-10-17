---
title: Routing in Kong Gateway

content_type: reference
layout: reference

related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: Expressions router
    url: /gateway/routing/expressions/

breadcrumbs:
  - /gateway/
---

## How requests are routed

For each incoming request, {{site.base_gateway}} must determine which
service gets to handle it based on the routes that are defined.  With
release 3.0, {{site.base_gateway}} introduced a router that can be
running in two modes: the `traditional_compat` mode, which is
configured like prior releases, and the `expressions` mode which uses
a new configuration scheme. We recommend that new deployments use
the expressions router as it is more powerful and expressive.

The default mode of the router is `traditional_compat` and the
following sections describe how it operates. `traditional_compat`
mode is designed to behave like the router in versions before
{{site.base_gateway}} 3.x. For a description of the `expressions` mode, see
[How to Configure Routes using Expressions](/gateway/routing/expressions/).

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

## Regular expressions and prefix paths

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
path match must be performed, using the [expressions router](/gateway/routing/expressions/)
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
