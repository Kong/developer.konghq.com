---
title: Plugins
name: Plugin
entities:
  - plugin

description: Plugins are modules that extend the functionality of Kong Gateway.

related_resources:
  - text: Plugin Hub
    url: /plugins/
  - text: Supported scopes by plugin
    url: 'https://docs.konghq.com/hub/plugins/compatibility/#scopes'
  - text: Supported topologies by plugin
    url:  'https://docs.konghq.com/hub/plugins/compatibility/'
  - text: Supported protocols for each plugin
    url:  'https://docs.konghq.com/hub/plugins/compatibility/#protocols'
  - text: Self-managed Kong Gateway license tiers
    url:  'https://docs.konghq.com/hub/plugins/license-tiers/'
  - text: Konnect pricing tiers
    url: 'https://docs.konghq.com/konnect/compatibility/#plugin-compatibility'

tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform

schema:
    api: gateway/admin-ee
    path: /schemas/Plugin

---

## What is a plugin?

Kong Gateway is a Lua application designed to load and execute modules. These modules, called plugins, allow you to add more features to your implementation.

Kong provides a set of standard Lua plugins that get bundled with {{site.base_gateway}} and {{site.konnect_short_name}}. 
The set of plugins you have access to depends on your license tier.

You can also develop custom plugins, adding your own custom functionality to {{site.base_gateway}}.
