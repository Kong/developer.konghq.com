---
layout: default
title: Plugin precedence

content_type: reference

related_resources:
  - text: Kong Plugin Hub
    url: /hub/
---

A single plugin instance always runs _once_ per request. The
configuration with which it runs depends on the entities it has been
configured for.
Plugins can be configured for various entities, combinations of entities, or even globally.
This is useful, for example, when you want to configure a plugin a certain way for most requests but make _authenticated requests_ behave slightly differently.

Therefore, there is an order of precedence for running a plugin when it has been applied to different entities with different configurations. The number of entities configured to a specific plugin directly correlates to its priority. The more entities a plugin is configured for, the higher its order of precedence.

The complete order of precedence for plugins configured to multiple entities is:

1. **Consumer** + **route** + **service**: Highest precedence, affecting authenticated requests that match a specific consumer on a particular route and service.
1. **Consumer group** + **service** + **route**: Affects groups of authenticated users across specific services and routes.
1. **Consumer** + **route**: Targets authenticated requests from a specific consumer on a particular route.
1. **Consumer** + **service**: Applies to authenticated requests from a specific consumer accessing any route within a given service.
1. **Consumer group** + **route**: Affects groups of authenticated users on specific routes.
1. **Consumer group** + **service**: Applies to all routes within a specific service for groups of authenticated users.
1. **Route** + **service**: Targets all consumers on a specific route and service.
1. **Consumer**: Applies to all requests from a specific, authenticated consumer across all routes and services.
1. **Consumer group**: Affects all routes and services for a designated group of authenticated users.
1. **Route**: Specific to given route.
1. **Service**: Specific to given service. 
1. **Globally configured plugins**: Lowest precedence, applies to all requests across all services and routes regardless of consumer status.

{:.note}
> **Note on precedence for consumer groups**:
When a consumer is a member of two consumer groups, each with a scoped plugin, 
{{site.base_gateway}} ensures deterministic behavior by executing only one of these plugins. 
However, the specific rules that govern this behavior are not defined and are subject to change in future releases.