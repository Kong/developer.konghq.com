---
title: Set up a custom plugin project
description: Create a simple custom plugin project for {{site.base_gateway}}.
  
content_type: how_to

permalink: /custom-plugins/get-started/set-up-plugin-project/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 1

tldr:
  q: How do I start developing a custom plugin?
  a: |
    Create a new repository for your plugin and add the following files in the repository:
    * `kong/plugins/<plugin-name>/handler.lua`
    * `kong/plugins/<plugin-name>/schema.lua`

tags:
  - custom-plugins
  - pdk

products:
  - gateway

works_on:
  - on-prem

prereqs:
  skip_product: true
  inline:
    - title: (Optional) Lua
      content: While not required, an understanding of the [Lua](https://www.lua.org/about.html) language is helpful for this series.
      icon: /assets/icons/code.svg

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Plugins
    url: /gateway/entities/plugins/
---

## Initialize a new plugin repository

The first step in developing a custom plugin is to create the required files in the expected folder structure.

1. Open a terminal in the directory where you want to create your plugin project. 

1. Create a new folder for the plugin and navigate into it:
   ```sh
   mkdir -p my-plugin && \
     cd my-plugin
   ```

1. Create the plugin folder structure:
   ```sh
   mkdir -p kong/plugins/my-plugin && \
     mkdir -p spec/my-plugin
   ```

   {:.warning}
   > **Important:** The specific tree structure and filenames shown in this guide are important for ensuring 
   > the development and execution of your plugin works properly with {{site.base_gateway}}. Don't
   > deviate from these names for this guide.

1. Create empty `handler.lua` and `schema.lua` files, which are the minimum required [Lua modules](http://www.lua.org/manual/5.1/manual.html#5.3)
for a functioning plugin:
   ```sh
   touch kong/plugins/my-plugin/handler.lua
   touch kong/plugins/my-plugin/schema.lua
   ```

## Initialize the schema module

The `schema.lua` file defines your plugin's configuration data model. The following is the minimum structure required for a valid plugin.

Add the following code to the `schema.lua` file:
```lua
local PLUGIN_NAME = "my-plugin"

local schema = {
  name = PLUGIN_NAME,
  fields = {
    { config = {
        type = "record",
        fields = {
        },
      },
    },
  },
}

return schema
```
 
This creates an empty base table for the plugin's configuration. 
Later in this series, we'll add configurable values to the table to configure the plugin.


## Initialize the handler module

The `handler.lua` module contains the core logic of your new plugin.

Add the following Lua code into the `handler.lua` file:
```lua
local MyPluginHandler = {
    PRIORITY = 1000,
    VERSION = "0.0.1",
}

return MyPluginHandler
```

This code defines a [Lua table](https://www.lua.org/pil/2.5.html) specifying a set of required 
fields for a valid plugin:

* The `PRIORITY` field sets the static 
[execution order](/gateway/entities/plugin/#plugin-priority) 
of the plugin, which determines when this plugin is executed relative to other loaded plugins.
* The `VERSION` field sets the version for this plugin and should follow the `major.minor.revision` format.
 
## Add handler logic

Plugin logic is defined to be executed at several key points in the lifecycle of
HTTP requests, TCP streams, and {{site.base_gateway}} itself.

Inside the `handler.lua` module, you can add [functions](/custom-plugins/handler.lua/#available-contexts) to the plugin table, 
indicating the points at which the plugin logic should be executed. 

In this example, we'll add a `response` function, which is executed after a response has been
received from the upstream service but before returning it to the client. 

Let's add a header to the response before returning it to the client. Add the following  function implementation to the `handler.lua` file before the `return MyPluginHandler` statement:
```lua
function MyPluginHandler:response(conf)
    kong.response.set_header("X-MyPlugin", "response")
end
```

The [`kong.response`](/gateway/pdk/reference/kong.response/) module provided in the Kong PDK provides
functions for manipulating the response sent back to the client. The code above sets 
a new header on all responses with the name `X-MyPlugin` and value of `response`. 

The full `handler.lua` file now looks like this:

```lua
local MyPluginHandler = {
  PRIORITY = 1000,
  VERSION = "0.0.1",
}

function MyPluginHandler:response(conf)
    kong.response.set_header("X-MyPlugin", "response")
end

return MyPluginHandler
```

{:.warning}
> **Important:** The Kong PDK provides a stable interface and set of functions for 
> custom plugin development. It's important to avoid using modules from 
> the {{site.base_gateway}} codebase that are *not* part of the PDK. These modules
> are not guaranteed to provide a stable interface or behavior, and using them
> in your plugin code may lead to unexpected behavior.
