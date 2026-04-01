---
title: Add a custom plugin configuration
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

tags:
  - custom-plugins
  - pdk

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
  - text: Plugins
    url: /gateway/entities/plugins/

automated_tests: false
---

## Add configuration fields to the schema 

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

## Read configuration values from plugin code 

Modify the `response` function in the `handler.lua` file to read the configuration value from the incoming `conf` parameter instead of the current hardcoded value:
```lua
function MyPluginHandler:response(conf)
    kong.response.set_header(conf.response_header_name, "response")
end
```

## Manually validate the configuration

Let's use Pongo to test the updated configuration.

1. Launch {{site.base_gateway}} and open a shell:
   ```sh
   pongo shell
   ```

1. Run the database migrations and start {{site.base_gateway}}:
   ```sh
   kms
   ```

1. Add a [test Gateway Service](/api/gateway/admin-ee/#/operations/create-service):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services
status_code: 201
method: POST
body:
    name: example_service
    url: https://httpbin.konghq.com
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. [Enable the plugin](/api/gateway/admin-ee/#/operations/create-plugin-with-service), this time with the configuration value:
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services/example_service/plugins
status_code: 201
method: POST
body:
    name: my-plugin
    config:
      response_header_name: X-CustomHeaderName
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. [Add a Route](/api/gateway/admin-ee/#/operations/create-route):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services/example_service/routes
status_code: 201
method: POST
body:
    name: example_route
    paths:
      - /mock
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->

1. Send a request to the Route:
<!-- vale off -->
{% capture request %}
{% validation request-check %}
url: '/mock/anything'
status_code: 200
display_headers: true
{% endvalidation %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on --> 
This time we should see the `X-CustomHeaderName` in the response.

1. Exit the {{site.base_gateway}} shell before proceeding to the next step:
   ```sh
   exit
   ```

## Add automated configuration testing

1. Update the `setup` function inside the `spec/01-integration_spec.lua` module so that the `my-plugin` that is added to the database is configured with a different value for the `response_header_name` field:
   ```lua
   -- Add the custom plugin to the test Route
   blue_print.plugins:insert {
     name = PLUGIN_NAME, 
     route = { id = test_route.id },
     config = {
       response_header_name = "X-CustomHeaderName",
     },
   }
   ```

1. Modify the test assertion to match the new header name:
   ```lua
   -- now validate and retrieve the expected response header 
   local header_value = assert.response(r).has.header("X-CustomHeaderName")
   ```

   The test file should now look like this:
   ```lua
   -- Helper functions provided by Kong Gateway, see https://github.com/Kong/kong/blob/master/spec/helpers.lua
   local helpers = require "spec.helpers"

   -- matches our plugin name defined in the plugins's schema.lua
   local PLUGIN_NAME = "my-plugin"

   -- Run the tests for each strategy. Strategies include "postgres" and "off"
   --   which represent the deployment topologies for Kong Gateway
   for _, strategy in helpers.all_strategies() do
  
     describe(PLUGIN_NAME .. ": [#" .. strategy .. "]", function()
       -- Will be initialized before_each nested test
       local client
   
       setup(function()
  
         -- A BluePrint gives us a helpful database wrapper to
         --    manage Kong Gateway entities directly.
         -- This function also truncates any existing data in an existing db.
         -- The custom plugin name is provided to this function so it mark as loaded
         local blue_print = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

         -- Using the BluePrint to create a test Route, automatically attaches it
         --    to the default "echo" Service that will be created by the test framework
         local test_route = blue_print.routes:insert({
           paths = { "/mock" },
         })

         -- Add the custom plugin to the test Route
         blue_print.plugins:insert {
           name = PLUGIN_NAME, 
           route = { id = test_route.id },
           config = {
             response_header_name = "X-CustomHeaderName",
           },
         }


         -- start kong
         assert(helpers.start_kong({
           -- use the custom test template to create a local mock server
           nginx_conf = "spec/fixtures/custom_nginx.template",
           -- make sure our plugin gets loaded
           plugins = "bundled," .. PLUGIN_NAME,
         }))

       end)

       -- teardown runs after its parent describe block
       teardown(function()
         helpers.stop_kong(nil, true)
       end)

       -- before_each runs before each child describe
       before_each(function()
         client = helpers.proxy_client()
       end)

       -- after_each runs after each child describe
       after_each(function()
         if client then client:close() end
       end)

       -- a nested describe defines an actual test on the plugin behavior
       describe("The response", function()

         it("gets the expected header", function()

           -- invoke a test request
           local r = client:get("/mock/anything", {})

           -- validate that the request succeeded, response status 200
           assert.response(r).has.status(200)

           -- now validate and retrieve the expected response header 
           local header_value = assert.response(r).has.header("X-CustomHeaderName")

           -- validate the value of that header
           assert.equal("response", header_value)

         end)
       end)
     end)
   end
   ```

1. Run the tests:
   ```sh
   pongo run
   ```
   Pongo should report a successful test run.