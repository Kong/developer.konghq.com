---
title: Plugins
content_type: reference
entities:
  - plugin

description: Plugins are modules that extend the functionality of {{site.base_gateway}}.

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
