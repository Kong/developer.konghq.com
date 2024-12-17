---
title: Plugins
content_type: reference
entities:
  - plugin

description: Plugins are modules that extend the functionality of Kong Gateway.

related_resources:
  - text: Plugin Hub
    url: /plugins/
  - text: Supported scopes by plugin
    url: '/plugins/scopes/'
  - text: Supported topologies and deployment options by plugin
    url:  '/plugins/deployment-options/'
  - text: Supported protocols for each plugin
    url:  '/plugins/protocols/'

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
When a Consumer is a member of two Consumer Groups, each with a scoped plugin, 
{{site.base_gateway}} ensures deterministic behavior by executing only one of these plugins. 
However, the specific rules that govern this behavior are not defined and are subject to change in future releases.

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
