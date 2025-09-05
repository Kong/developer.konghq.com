---
title: Plugins
content_type: reference
entities:
  - plugin

description: Plugins are modules that extend the functionality of {{site.base_gateway}}.

related_resources:
  - text: Plugin Hub
    url: /plugins/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Custom plugins
    url: /custom-plugins/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway-manager/control-plane-resource-limits/


tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform

search_aliases:
  - add-on
  - extension

schema:
    api: gateway/admin-ee
    path: /schemas/Plugin

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

works_on:
  - on-prem
  - konnect
---

## What is a plugin?

{{site.base_gateway}} is a Lua application designed to load and execute modules. These modules, called plugins, allow you to add more features to your implementation.

Kong provides a set of standard Lua plugins that get bundled with {{site.base_gateway}} and {{site.konnect_short_name}}.

You can also develop [custom plugins](/custom-plugins/), adding your own custom functionality to {{site.base_gateway}}.

## Custom plugins

Kong provides an entire development environment for developing plugins, including Plugin Development Kits (or PDKs), database abstractions, migrations, and more.

Plugins consist of modules interacting with the request/response objects or streams via a PDK to implement arbitrary logic. Kong provides PDKs in the following languages:

* Lua
* Go
* Python
* JavaScript

These PDKs are sets of functions that a plugin can use to facilitate interactions between plugins and the core (or other components) of Kong.

To start creating your own plugins, review the [Getting Started documentation](/custom-plugins/get-started/set-up-plugin-project/), or see the following references:

* [Plugin Development Kit reference](/gateway/pdk/reference/)
* [Custom plugins reference](/custom-plugins/reference/)

## How do plugins work?

A {{site.base_gateway}} plugin allows you to inject custom logic at several entrypoints in the lifecycle of a request, 
response, or TCP stream connection as it is proxied by {{site.base_gateway}}.

### Plugin contexts

{% include plugins/plugin-contexts.md %}

## Scoping plugins

You can run plugins in various contexts, depending on your environment needs.
Each plugin can run globally, or be scoped to some combination of the following:
* [Gateway Services](/gateway/entities/service/)
* [Routes](/gateway/entities/route/)
* [Consumers](/gateway/entities/consumer/)
* [Consumer Groups](/gateway/entities/consumer-group/)

Using scopes, you can customize how {{site.base_gateway}} handles functions in your environment, 
either before a request is sent to your upstream services or after it receives a response.
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

A plugin can have multiple instances in the same configuration. 
Different instances can be used to apply the plugin to various entities, combinations of entities, or even globally. 
You can give each plugin instance a unique name to help identify it. The instance name itself doesn't affect processing - it acts like an internal label instead.

A single plugin instance always runs _once_ per request. 
The configuration with which it runs depends on the entities it has been configured for.

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

All of the plugins bundled with {{site.base_gateway}} have a static priority. 
This can be [adjusted dynamically](#dynamic-plugin-ordering) using the plugin's `ordering` configuration parameter.

{% plugin_priorities %}

### Dynamic plugin ordering

You can override the [priority](#plugin-priority) for any {{site.base_gateway}} plugin using each plugin’s `ordering` configuration parameter. 
This determines plugin ordering during the [`access` phase](#plugin-contexts), and lets you create dynamic dependencies between plugins.

You can choose to run a particular plugin `before` or `after` a specified plugin or list of plugins.

The configuration looks like this:

```yaml
pluginA:
  ordering:
    before|after:
      access:
        - pluginB
        - pluginC
```

#### Example with before token

For example, let’s say you want to limit the amount of requests against your Gateway Service and Route **before** Kong requests authentication.
The following example uses the Rate Limiting Advanced plugin with the Key Auth plugin as the authentication method:

{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    minute: 5
    policy: local
    limit_by: ip
  ordering:
    before:
      access:
        - key-auth
{% endentity_example %}

#### Example with after token

For example, you may want to first transform a request with the Request Transformer plugin, then request authentication.
You can change the order of the authentication plugin (Basic Auth, in this example) so that it always runs **after** transformation:

{% entity_example %}
type: plugin
data:
  name: basic-auth
  ordering:
    after:
      access:
        - request-transformer
{% endentity_example %}


#### Known limitations of dynamic plugin ordering

If using dynamic ordering, manually test all configurations, and handle this feature with care. 
There are a number of considerations that can affect your environment:

* **Consumer and Consumer Group scoping**: If you have [Consumer or Consumer Group-scoped plugins](#scoping-plugins) anywhere in your Workspace or Control Plane, you can't use dynamic plugin ordering. 

  Consumer mapping and dynamic plugin ordering both run in the `access` phase, but the order of the  plugins must be determined after Consumer mapping has happened.
  {{site.base_gateway}} can't reliably change the order of the plugins in relation to mapped Consumers or Consumer Groups.

* **Cascading deletes**: Detecting if a plugin has a dependency to a deleted plugin isn't supported, so handle your configuration with care.

* **Performance**: Dynamic plugin ordering requires sorting plugins during a request, which adds latency to the request. 
In some cases, this might be compensated for when you run rate limiting before an expensive authentication plugin.
    
  Re-ordering _any_ plugin in a Workspace or Control Plane has performance implications to all other plugins within the same environment. 
  If possible, consider offloading plugin ordering to a separate environment.

* **Validation**: Validating dynamic plugin ordering is a non-trivial task and would require insight into the user's business logic. 
{{site.base_gateway}} tries to catch basic mistakes, but it can't detect all potentially dangerous configurations.

## Protocols

Plugins support different protocols.

### Supported protocols by plugin

Each plugin supports a specific set of protocols. By default, all protocols supported by a plugin are enabled.
You can adjust the plugin’s configuration to disable support for specific protocols, if needed.

See the following table for plugins and their compatible (default) protocols:

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
