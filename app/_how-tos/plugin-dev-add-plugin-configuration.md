---
title: Add custom plugin configuration
description: Add features to your custom plugin.
  
content_type: how_to

permalink: /custom-plugins/get-started/add-plugin-configuration/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 3

tldr:
  q: How can I configure features in my custom plugin?
  a: Add configuration fields in the plugins's `schema.lua` file, and define the features using the configuration fields in `handler.lua`.

products:
  - gateway

tools:
  - admin-api

works_on:
  - on-prem

prereqs:
  skip_product: true

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
---

## 1. Add configuration fields to the schema 

Let's add some configuration fields to our `schema.lua` file.

1. Include the {{site.base_gateway}} [`typedefs` module](https://github.com/Kong/kong/blob/master/kong/db/schema/typedefs.lua) at the top of the `schema.lua` file:
   ```lua
   local typedefs = require "kong.db.schema.typedefs"
   ```

1. Add the following `header_name` type definition within the `fields` array we defined earlier:
   ```lua
    { response_header_name = typedefs.header_name {
        required = false,
        default = "X-MyPlugin" } },
   ```
   This type definition defines the field to be a string that cannot be null and conforms to the rules for header names. It also indicates that the configuration value is *not* required, which means it's optional for the user when configuring the plugin. We also specify a  default value that will be used when a user does not specify a value.

The full `schema.lua` now looks like this:
```lua
local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "my-plugin"

local schema = {
  name = PLUGIN_NAME,
  fields = {
    { config = {
        type = "record",
        fields = {
          { response_header_name = typedefs.header_name {
            required = false,
            default = "X-MyPlugin" } },
        },
      },
    },
  },
}

return schema
```

## 2. Read configuration values from plugin code 

Modify the `response` function in the `handler.lua` file to read the configuration value from the incoming `conf` parameter instead of the current hardcoded value:
```lua
function MyPluginHandler:response(conf)
    kong.response.set_header(conf.response_header_name, "response")
end
```

## 3. Manually validate the configuration

Let's use Pongo to test the updated configuration.

1. Launch {{site.base_gateway}} and open a shell:
  ```sh
  pongo shell
  ```

2. run the database migrations and start {{site.base_gateway}}:
  ```sh
  kms
  ```

3. Add a test service:
   {% control_plane_request %}
   url: /services
   status_code: 201
   method: POST
   body:
       name: example_service
       url: https://httpbin.konghq.com
   {% endcontrol_plane_request %}

4. Enable the plugin, this time with the configuration value:
   {% control_plane_request %}
   url: /services/example_service/plugins
   status_code: 201
   method: POST
   body:
       name: my-plugin
       config:
         response_header_name: X-CustomHeaderName
   {% endcontrol_plane_request %}

5. Add a route:
   {% control_plane_request %}
   url: /services/example_service/routes
   status_code: 201
   method: POST
   body:
       name: example_route
       paths:
         - /mock
   {% endcontrol_plane_request %}

6. Send a request to the route:
   {% validation request-check %}
   url: '/mock/anything'
   status_code: 200
   display_headers: true
   {% endvalidation %}

   This time we should see the `X-CustomHeaderName` in the response.

7. Exit the {{site.base_gateway}} shell before proceeding to the next step:
   ```sh
   exit
   ```

## 4. Add automated configuration testing

1. Update the `setup` function inside the `spec/01-integration_spec.lua` module so that the `my-plugin` that is
added to the database is configured with a different value for the `response_header_name` field.

   Here is the code:
   ```lua
   -- Add the custom plugin to the test route
   blue_print.plugins:insert {
     name = PLUGIN_NAME, 
     route = { id = test_route.id },
     config = {
       response_header_name = "X-CustomHeaderName",
     },
   }
   ```

1. Modify the test assertion to match our configured header name.

   Replace this line:
   ```lua
   local header_value = assert.response(r).has.header("X-MyPlugin")
   ```

   With this line:
   ```lua
   local header_value = assert.response(r).has.header("X-CustomHeaderName")
   ```

1. Run the tests:
   ```sh
   pongo run
   ```
   Pongo should report a successful test run.