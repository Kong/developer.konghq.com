---
title: "\"API route collides with an existing API\" error when creating a route in a different workspace"
content_type: support
description: "{{site.ee_product_name}}'s route collision check warns when a new route in one workspace could unintentionally take traffic from a route in another workspace. Disable the check or reorder route creation to avoid it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`route_validation_strategy` configuration"
    url: "/gateway/configuration/#route-validation-strategy"
tldr:
  q: Why does Kong show an "API route collides with an existing API" error when creating a new route?
  a: |
    {{site.ee_product_name}}'s route collision check assumes different workspaces are managed by different teams, so it warns when a new route in one workspace could unintentionally take traffic from an existing route in another workspace. To resolve it, give the more generic route a distinct `host` value, disable the check with `route_validation_strategy`, or create routes in other workspaces before creating the generic catch-all route.
---

## Problem

When adding a new route with a path that doesn't exist in any workspace, Kong returns the following error:

```
API route collides with an existing API
```

## Cause

In {{site.ee_product_name}} Edition, it is assumed that different workspaces are being used by different teams who do not know about each other's routes, and thus the default route collision check is meant to warn one team that a route already exists in a different workspace which will be affected by the new route. The message that is displayed means that the new route would "steal" traffic from the original route, i.e. traffic that would have gone to the original route would now go to the new route.

An extreme example to illustrate the issue is: if you first add a super generic route with a path `/` without any host in workspace `default`, all requests will match this route. Any other route in a different workspace you might create later would "steal" some traffic from the generic or catch-all route. Because of this potential for redirecting traffic from a route in a different workspace, we send the route collision warning.

If a route that would "steal" traffic from another route is created in the same workspace, we allow the route creation because we assume that team members in the same workspace are aware of what each other are doing.

Also, if the order of route creation is reversed, i.e. the narrower route in one workspace is created before the generic route in a different workspace, the route collision detector won't fire, because the generic route does not "steal" traffic from the more specific route which was created first. The algorithm for route collision detection as documented has some limitations. For example, if the generic route has a method defined, and the more specific route in a different workspace does not, the more specific route is still allowed to be created even though there is a potential for it "stealing" traffic from the generic route.

If the route collision warning message happens, and it is not clear why, it would be necessary to check all the routes in the other workspaces (other than the workspace in which you are trying to create the new route) for a route that would be affected by the new route.

## Solution

There are three options to address the issue:

1. Make sure the more generic routes have a host value set that is different from the other routes.
2. Disable route collision checking with the `route_validation_strategy` setting.
3. Create all other routes in other workspaces first, and then create the more generic catch-all route.
