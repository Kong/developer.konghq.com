---
layout: default
title: Supported scopes by plugin

content_type: reference
layout: reference

related_resources:
  - text: Kong Plugins
    url: /plugins/

breadcrumbs:
  - /gateway/
---

## Scoping plugins

You can run plugins in various contexts, depending on your environment needs.
Each plugin can run globally, or be scoped to some combination of the following:
* Services
* Routes
* Consumers
* Consumer groups

Using scopes, you can customize how Kong handles functions in your environment, 
either before a request is sent to your backend services or after it receives a response.
For example, if you apply a plugin to a single [**route**](/gateway/entities/route/), that plugin will trigger only on the specific path requests take through your system.
On the other hand, if you apply the plugin [**globally**](#global-scope), it will run on every request, regardless of any other configuration.

### Global scope

A global plugin is not associated to any service, route, consumer, or consumer group is considered global, and will be run on every request,
regardless of any other configuration.

* In self-managed {{site.ee_product_name}}, the plugin applies to every entity in a given workspace.
* In self-managed {{site.ce_product_name}}, the plugin applies to your entire environment.
* In {{site.konnect_short_name}}, the plugin applies to every entity in a given control plane.

Every plugin supports a subset of these scopes.

## Supported scopes by plugin

See the following table for plugins and their compatible scopes:

[Placeholder for table that gets generated from plugin schemas, which will show all the plugin scope compatibilities (equivalent of [scopes](https://docs.konghq.com/hub/plugins/compatibility/#scopes).)]
