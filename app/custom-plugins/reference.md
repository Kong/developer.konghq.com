---
title: Custom plugin reference
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn about how to develop custom plugins for {{site.base_gateway}}

tags:
  - custom-plugins

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
---

Kong allows you to develop and deploy custom plugins.

Before building custom plugins, it's' important to understand how {{site.base_gateway}} 
is built, how it integrates with Nginx, and how the high performance [Lua](https://www.lua.org/about.html) 
language is used.

Lua development is enabled in Nginx with the [lua-nginx-module](https://github.com/openresty/lua-nginx-module). Instead of
compiling Nginx with this module, {{site.base_gateway}} is distributed along with
[OpenResty](https://openresty.org/), which includes the `lua-nginx-module`.
OpenResty is not a fork of Nginx, but a bundle of modules extending its
capabilities.

{{site.base_gateway}} is a Lua application designed to load and execute Lua modules,
commonly referred to as plugins. {{site.base_gateway}} provides a broad plugin 
development environment including an SDK, database abstractions, migrations, and more.

Plugins consist of Lua modules interacting with request/response objects or
network streams to implement arbitrary logic. {{site.base_gateway}} provides a 
[**Plugin Development Kit** (PDK)](/gateway/pdk/reference/) which is a set of Lua functions that are used  
to facilitate interactions between plugins, the {{site.base_gateway}} core, and other 
components. 

## Plugin structure

Consider your plugin as a set of [Lua modules](http://www.lua.org/manual/5.1/manual.html#5.3). 
Each file described in this section is a separate module. 
{{site.base_gateway}} will detect and load your plugin's modules if their names follow this convention:
```
kong.plugins.<plugin_name>.<module_name>
```
{:.no-copy-code}

Your modules need to be accessible through your [`package.path`](http://www.lua.org/manual/5.1/manual.html#pdf-package.path) variable, which can be customized to your needs via the [`lua_package_path`](/gateway/configuration/#lua-package-path) configuration property.
However, the preferred way of installing plugins is through [LuaRocks](https://luarocks.org/), which {{site.base_gateway}} natively integrates with.

To make {{site.base_gateway}} aware that it has to look for your plugin's modules, you'll have to add it to the [`plugins`](/gateway/configuration/#plugins) property in your configuration file, which is a comma-separated list. For example:
```yaml
plugins = bundled,my-custom-plugin
```

Or, if you don't want to load any of the bundled plugins:
```yaml
plugins = my-custom-plugin
```

Now, {{site.base_gateway}} will try to load several Lua modules from the following namespace:
```
kong.plugins.my-custom-plugin.<module_name>
```
{:.no-copy-code}

### Basic plugin modules

In its simplest form, a plugin consists of two mandatory modules:
* `handler.lua`: This module is the core of your plugin. It's an interface to implement, in which each function will be run at the desired moment in the lifecycle of a request/connection.
* `schema.lua`: This module holds the schema of the plugin configuration to be entered by the user, and defines rules on it, so that the user can only enter valid configuration values.

Some plugins, such as the [File Log](https://github.com/Kong/kong/tree/master/kong/plugins/file-log) plugin, use only these two modules. However, you can use advanced modules to implement extra functionalities.

To learn how to create a simple plugin with the basic modules, see the [getting started guide](/custom-plugins/#get-started).

### Advanced plugin modules

Some plugins might have to integrate deeper with {{site.base_gateway}}: have their own table in the database, expose endpoints in the Admin API, etc. 
This can be done by adding new modules to your plugin. 
Here is what the structure of a plugin looks like when it implements all of the optional modules:

```
complete-plugin
├── api.lua
├── daos.lua
├── handler.lua
├── migrations
│   ├── init.lua
│   └── 000_base_complete_plugin.lua
└── schema.lua
```
{:.no-copy-code}

Here is the complete list of possible modules to implement:

{% table %}
columns:
  - title: Module
    key: module
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - module: "[`api.lua`](/custom-plugins/api.lua/)"
    required: false
    description: Defines a list of endpoints to be available in the Admin API to interact with the custom entities handled by your plugin.
  - module: "[`daos.lua`](/custom-plugins/daos.lua/)"
    required: false
    description: Defines a list of DAOs (Database Access Objects) that are abstractions of custom entities needed by your plugin and stored in the data store.
  - module: "[`handler.lua`](/custom-plugins/handler.lua/)"
    required: true
    description: An interface to implement. Each function is to be run by {{site.base_gateway}} at the desired moment in the lifecycle of a request/connection.
  - module: "[`migrations/*.lua`](/custom-plugins/migrations/)"
    required: false
    description: The database migrations (e.g. creation of tables). Migrations are only necessary when your plugin has to store custom entities in the database and interact with them through one of the DAOs defined by `daos.lua`.
  - module: "[`schema.lua`](/custom-plugins/schema.lua/)"
    required: true
    description: Holds the schema of your plugin's configuration.
{% endtable %}

The [Key Authentication plugin](/plugins/key-auth/) is an example of a plugin with these modules.
See the [plugin source code](https://github.com/Kong/kong/tree/master/kong/plugins/key-auth) for more details.