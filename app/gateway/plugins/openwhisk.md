---
title: Apache OpenWhisk

layout: reference
content_type: reference

permalink: /plugins/openwhisk/

related_resources:
  - text: Kong Plugin Hub
    url: /plugins/
  - text: OpenWhisk plugin GitHub repository
    url: https://github.com/Kong/kong-plugin-openwhisk
  - text: OpenWhisk Actions
    url: https://github.com/apache/openwhisk/blob/master/docs/actions.md

breadcrumbs:
  - /plugins/

act_as_plugin: true
name: OpenWhisk
publisher: test
icon: /assets/icons/plugins/openwhisk.png
categories:
  - serverless
source_code_url: https://github.com/Kong/kong-plugin-openwhisk

description: Invoke and manage OpenWhisk actions from Kong

works_on:
    - on-prem
    - konnect

products:
  - gateway

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

min_version:
  gateway: '3.4'

tags:
    - serverless
---

This plugin invokes [OpenWhisk Actions](https://github.com/apache/openwhisk/blob/master/docs/actions.md).
The Apache OpenWhisk plugin can be used in combination with other [request plugins](/plugins/?terms=request) to secure, manage, or extend the function.

## Install the OpenWhisk plugin

This plugin is not bundled with {{site.base_gateway}}.

1. Install the OpenWhisk plugin using the LuaRocks package manager:

   ```sh
   luarocks install kong-plugin-openwhisk
   ```

2. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append `openwhisk` to the `plugins` field. Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,openwhisk
   ```

3. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

You can also install the OpenWhisk plugin from [source](https://github.com/Kong/kong-plugin-openwhisk).

## Using the OpenWhisk plugin

To learn how to use this plugin with OpenWhisk, see the [Kong OpenWhisk plugin README](https://github.com/Kong/kong-plugin-openwhisk).

## Limitations of the OpenWhisk plugin

### Using a fake upstream service

When using the OpenWhisk plugin, the response is returned by the plugin itself without proxying the request to any upstream service. This means that a Gateway Service's `host`, `port`, `path` properties are ignored, but must still be specified for the entity to be validated by {{site.base_gateway}}. 
The `host` property in particular must either be an IP address, or a hostname that gets resolved by your nameserver.

### Response plugins

There is a known limitation in the system that prevents some response plugins from being executed.
