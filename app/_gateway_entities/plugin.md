---
title: Plugins
content_type: reference
entities:
  - plugin

description: Plugins are modules that extend the functionality of {{site.base_gateway}}.

related_resources:
  - text: Plugin Hub
    url: /plugins/

tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform

schema:
    api: gateway/admin-ee
    path: /schemas/Plugin

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

---

## What is a plugin?

{{site.base_gateway}} is a Lua application designed to load and execute modules. These modules, called plugins, allow you to add more features to your implementation.

Kong provides a set of standard Lua plugins that get bundled with {{site.base_gateway}} and {{site.konnect_short_name}}.
The set of plugins you have access to depends on your license tier.

You can also develop custom plugins, adding your own custom functionality to {{site.base_gateway}}.

## Custom plugins

Kong provides an entire development environment for developing plugins, including Plugin Development Kits (or PDKs), database abstractions, migrations, and more.

Plugins consist of modules interacting with the request/response objects or streams via a PDK to implement arbitrary logic. Kong provides PDKs in the following languages:

* Lua
* Go
* Python
* JavaScript

These PDKs are sets of functions that a plugin can use to facilitate interactions between plugins and the core (or other components) of Kong.

To start creating your own plugins, review the Getting Started documentation, or see the following references:

* Plugin Development Kit reference
* Other Language Support

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
* In self-managed open-source {{site.base_gateway}}, the plugin applies to your entire environment.
* In {{site.konnect_short_name}}, the plugin applies to every entity in a given Control Plane.

Every plugin supports a subset of these scopes.

### Plugin precedence

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
> **Note on precedence for Consumer Groups**
> <br><br>
> When a Consumer is a member of two Consumer Groups, each with a scoped instance of the same plugin, {{site.base_gateway}} ensures deterministic behavior by executing only one of these plugin instances. 
> Currently, this is determined by the Consumer Group name, in alphabetical order. 
> For example, if you have two Consumer Groups, A and B, each with an instance of the Rate Limiting Advanced plugin, the plugin in Consumer Group A will be applied.
> <br><br>
> The specific rules that govern this behavior are not defined and are subject to change in future releases.

### Supported scopes by plugin

See the following table for plugins and their compatible scopes:

{% plugin_scopes %}

## Plugin priority

All of the plugins bundled with Kong Gateway have a static priority. 
This can be [adjusted dynamically](#dynamic-plugin-ordering) using the plugin's `ordering` configuration parameter.

<!-- @todo: migrate table from https://docs.konghq.com/gateway/latest/kong-enterprise/plugin-ordering/ -->

## Dynamic plugin ordering

You can override the [priority](#plugin-priority) for any {{site.base_gateway}} plugin using each plugin’s `ordering` configuration parameter. 
This determines plugin ordering during the `access` phase, and lets you create dynamic dependencies between plugins.

<!-- @todo: migrate https://docs.konghq.com/gateway/latest/kong-enterprise/plugin-ordering/ -->


## Protocols

### Supported protocols by plugin

See the following table for plugins and their compatible protocols:

{% plugin_protocols %}

## Schema

{% entity_schema %}

## Set up a Plugin

Kong has many bundled plugins available, all of which have their own specific configurations and examples. See all 
[Kong plugins](/plugins/) for their individual configurations.

Here's an example of configuration for the ACL plugin:

{% entity_example %}
type: plugin
data:
  name: acl
  config:
    allow:
      - dev
      - admin
    hide_groups_header: false
{% endentity_example %}
