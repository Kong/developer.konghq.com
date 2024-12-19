---
title: Supported scopes by plugin

description: This page describes the different entity scopes available for each plugin.

content_type: reference
layout: reference

products:
  - gateway

related_resources:
  - text: Kong Plugins
    url: /plugins/

breadcrumbs:
  - /gateway/
---

## Scoping plugins

You can run plugins in various contexts, depending on your environment needs.
Each plugin can run globally, or be scoped to some combination of the following:
* [Gateway Services](/gateway/entities/service/)
* [Routes](/gateway/entities/route/)
* [Consumers](/gateway/entities/consumer/)
* [Consumer Groups](/gateway/entities/consumer-group/)

Using scopes, you can customize how {{site.base_gateway}} handles functions in your environment, 
either before a request is sent to your backend services or after it receives a response.
For example, if you apply a plugin to a single [**Route**](/gateway/entities/route/), 
that plugin will only trigger when a request matches the Route's specific path.

### Global scope

A global plugin is not associated to any Service, Route, Consumer, or Consumer Group is 
considered global, and will be run on every request, regardless of any other configuration.

* In self-managed {{site.ee_product_name}}, the plugin applies to every entity in a given Workspace.
* In self-managed {{site.ce_product_name}}, the plugin applies to your entire environment.
* In {{site.konnect_short_name}}, the plugin applies to every entity in a given Control Plane.

Every plugin supports a subset of these scopes.

## Supported scopes by plugin

See the following table for plugins and their compatible scopes:

[Placeholder for table that gets generated from plugin schemas, which will show all the plugin scope compatibilities (equivalent of [scopes](https://docs.konghq.com/hub/plugins/compatibility/#scopes).)]

## Plugin precedence

A single plugin instance always runs _once_ per request. The
configuration with which it runs depends on the entities it has been
configured for.
Plugins can be configured for various entities, combinations of entities, or even globally.
This is useful, for example, when you want to configure a plugin a certain way for most requests but make _authenticated requests_ behave slightly differently.

Therefore, there is an order of precedence for running a plugin when it has been applied to different entities with different configurations. The number of entities configured to a specific plugin directly correlates to its priority. The more entities a plugin is configured for, the higher its order of precedence.

The complete order of precedence for plugins configured to multiple entities is:

1. **Consumer** + **Route** + **Service**: Highest precedence, affecting authenticated requests that match a specific Consumer on a particular Route and Service.
2. **Consumer group** + **Service** + **Route**: Affects groups of authenticated users across specific Services and Routes.
3. **Consumer** + **Route**: Targets authenticated requests from a specific Consumer on a particular Route.
4. **Consumer** + **Service**: Applies to authenticated requests from a specific Consumer accessing any Route within a given Service.
5. **Consumer group** + **Route**: Affects groups of authenticated users on specific Routes.
6. **Consumer group** + **Service**: Applies to all Routes within a specific Service for groups of authenticated users.
7. **Route** + **Service**: Targets all Consumers on a specific Route and Service.
8. **Consumer**: Applies to all requests from a specific, authenticated Consumer across all Routes and Services.
9. **Consumer Group**: Affects all Routes and Services for a designated group of authenticated users.
10. **Route**: Specific to given Route.
11. **Service**: Specific to given Service. 
12. **Globally configured plugins**: Lowest precedence, applies to all requests across all Services and Routes regardless of Consumer status.

{:.info}
> **Note on precedence for Consumer Groups**:
When a Consumer is a member of two Consumer Groups, each with a scoped plugin, {{site.base_gateway}} ensures deterministic behavior by executing only one of these plugins. Currently, this is determined by the Group name, in alphabetical order. 
However, the specific rules that govern this behavior are not defined and are subject to change in future releases.