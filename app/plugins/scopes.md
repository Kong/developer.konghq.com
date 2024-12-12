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
that plugin will trigger only on the specific path requests take through your system.
On the other hand, if you apply the plugin [**globally**](#global-scope), it will 
run on every request, regardless of any other configuration.

### Global scope

A global plugin is not associated to any Gateway Service, Route, Consumer, or Consumer Group is 
considered global, and will be run on every request, regardless of any other configuration.

* In self-managed {{site.ee_product_name}}, the plugin applies to every entity in a given Workspace.
* In self-managed {{site.ce_product_name}}, the plugin applies to your entire environment.
* In {{site.konnect_short_name}}, the plugin applies to every entity in a given Control Plane.

Every plugin supports a subset of these scopes.

## Supported scopes by plugin

See the following table for plugins and their compatible scopes:

[Placeholder for table that gets generated from plugin schemas, which will show all the plugin scope compatibilities (equivalent of [scopes](https://docs.konghq.com/hub/plugins/compatibility/#scopes).)]
