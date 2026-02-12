---
title: Add custom plugin testing
description: Set up a testing environment for your custom plugin.
  
content_type: how_to

permalink: /custom-plugins/get-started/add-plugin-testing/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 2

tldr:
  q: How can I set up automated tests for my custom plugin?
  a: Install Pongo, initialize your testing environment, and write test files under the `spec/<plugin-name>` directory.

products:
  - gateway
min_version:
  gateway: '3.9'
tags:
  - custom-plugins
  - pdk

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

## Install Pongo

[Pongo](https://github.com/Kong/kong-pongo) is a tool that helps you validate and 
distribute custom plugins for {{site.base_gateway}}. 

Pongo uses Docker to bootstrap a {{site.base_gateway}} environment that allows you to quickly load your plugin, 
run automated testing, and manually validate the plugin's behavior against various {{site.base_gateway}} versions.

The following script can automate the installation of Pongo for you. 
If you prefer, you can follow the [manual installation instructions](https://github.com/Kong/kong-pongo?tab=readme-ov-file#installation)
instead.

1. Run the following to install or update Pongo:
   ```sh
   curl -Ls https://get.konghq.com/pongo | bash
   ```

1. Add Pongo to your path. The result of the previous command should contain instructions on how to do that. For example:
   ```sh
   export PATH=$PATH:~/.local/bin
   ```

1. Ensure that the `pongo` command is available in your `PATH` by running the command within your project directory:
   ```sh
   pongo help
   ```

## Initialize the test environment

Pongo lets you validate a plugin's behavior by giving you tools to quickly run a 
{{site.base_gateway}} instance with the plugin installed and available. 

{:.info}
> **Note**: {{site.base_gateway}} runs in a variety of
> [deployment topologies](/gateway/deployment-topologies/). 
> By default, Pongo runs {{site.base_gateway}} in [_traditional mode_](/gateway/traditional-mode/), which uses a database 
> to store configured entities such as Routes, Gateway Services, and plugins. 
> {{site.base_gateway}} and the database are run in separate containers,
> letting you cycle the gateway independently of the database. This enables a quick and 
> iterative approach to validating the plugin's logical behavior while keeping the gateway
> state independent in the database.

Pongo provides an optional command that initializes the project directory with some
default configuration files. You can run it to start a new project.

{:.warning}
> **Important:** These commands must be run inside the `my-plugin` project root directory so that Pongo properly 
> packages and includes the plugin code in the running {{site.base_gateway}}.

1. Initialize the project folder:
   ```sh
   pongo init
   ```

1. Start the dependencies, which only include the PostgreSQL in this example: 
   ```sh
   pongo up
   ```

   Once the dependencies are running successfully, you can run a {{site.base_gateway}} container and open a 
   shell within it. Pongo runs a {{site.base_gateway}} container with various CLI tools pre-installed to help with testing.

1. Launch {{site.base_gateway}} and open a shell:
   ```sh
   pongo shell
   ```
   Your terminal is now running a shell _inside_ the {{site.base_gateway}} container. Your 
   shell prompt should change, showing you the {{site.base_gateway}} version, the host plugin directory, 
   and current path inside the container. For example, your prompt may look like the following:
   ```sh
   [Kong-3.9.0:my-plugin:/kong]$
   ```
   {:.no-copy-code}

1. Run the database migrations and start {{site.base_gateway}}:
   ```sh
   kms
   ```

   You should see a success message saying that {{site.base_gateway}} has started.

1. Validate that the plugin is installed by querying the [Admin API](/api/gateway/admin-ee/)
using `curl` and filtering the response with `jq`:
   ```sh
   curl -s localhost:8001 | \
     jq '.plugins.available_on_server."my-plugin"'
   ```

   You should see a response that matches the information in the plugin's table:

   ```json
   {
     "priority": 1000,
     "version": "0.0.1"
   }
   ```

## Manually test the plugin

With the plugin installed, we can now configure [{{site.base_gateway}} entities](/gateway/entities/) to invoke and validate the plugin's behavior.

For each of the following `POST` requests to the Admin API, you should receive an `HTTP/1.1 201 Created` response from {{site.base_gateway}} indicating the successful creation of the entity.

1. Still within the {{site.base_gateway}} container's shell, [add a new Gateway Service](/api/gateway/admin-ee/#/operations/create-service):
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

1. [Enable the custom plugin](/api/gateway/admin-ee/#/operations/create-plugin-with-service) on the `example_service` Service:
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /services/example_service/plugins
status_code: 201
method: POST
body:
    name: my-plugin
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->
    
1. [Add a new Route](/api/gateway/admin-ee/#/operations/create-route) for sending requests through the `example_service`:
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
The plugin is now configured and will be invoked when {{site.base_gateway}} proxies
requests via the `example_service`. 
Prior to forwarding the response from the 
upstream, the plugin should append the `X-MyPlugin` header to the list of response headers.

1. Send a request to test the behavior and use the `-i` flag to display the response headers:
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
You should see `X-MyPlugin: response` in the set of headers, indicating that the plugin's logic has been invoked.

1. Exit the {{site.base_gateway}} shell before proceeding to the next step:
   ```sh
   exit
   ```


## Write an automated test

For quickly getting started, manually validating a plugin using the Pongo shell works
well. For production scenarios, you will likely want to deploy automated testing 
and maybe a test-driven development (TDD) methodology. 
Let's see how Pongo can help with this as well.

Pongo supports running automated tests using the 
[Busted](https://lunarmodules.github.io/busted/) Lua test framework. In plugin
projects, the test files reside under the `spec/<plugin-name>` directory. 
For this project, this is the `spec/my-plugin` folder you created earlier.  

1. In your plugin directory, create a test file:
   ```sh
   touch spec/my-plugin/01-integration_spec.lua
   ```
 
1. Copy and paste this code in the test file: 
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
           local header_value = assert.response(r).has.header("X-MyPlugin")

           -- validate the value of that header
           assert.equal("response", header_value)

         end)
       end)
     end)
   end
   ```
   This test validates the plugin's current behavior. See the code comments for details on the design of the test and the test helpers provided by {{site.base_gateway}}.

## Run the test

Pongo can run automated tests with the `pongo run` command. When this is executed,
Pongo determines if dependency containers are already running and will use them
if they are. The test library handles truncating existing data in between test runs.

Execute a test run:
```sh
pongo run
```

You should see a successful report that looks similar to this:

```sh
[pongo-INFO] auto-starting the test environment, use the 'pongo down' action to stop it
Kong version: 3.9.0

[==========] Running tests from scanned files.
[----------] Global test environment setup.
[----------] Running tests from /kong-plugin/spec/my-plugin/01-integration_spec.lua
[ RUN      ] /kong-plugin/spec/my-plugin/01-integration_spec.lua:63: my-plugin: [#postgres] The response gets the expected header
[       OK ] /kong-plugin/spec/my-plugin/01-integration_spec.lua:63: my-plugin: [#postgres] The response gets the expected header (12.56 ms)
[ RUN      ] /kong-plugin/spec/my-plugin/01-integration_spec.lua:63: my-plugin: [#off] The response gets the expected header
[       OK ] /kong-plugin/spec/my-plugin/01-integration_spec.lua:63: my-plugin: [#off] The response gets the expected header (11.42 ms)
[----------] 2 tests from /kong-plugin/spec/my-plugin/01-integration_spec.lua (48425.41 ms total)

[----------] Global test environment teardown.
[==========] 2 tests from 1 test file ran. (48436.36 ms total)
[  PASSED  ] 2 tests.
```
{:.no-copy-code}

Pongo can also run as part of a Continuous Integration (CI) system. See the 
[repository documentation](https://github.com/Kong/kong-pongo?tab=readme-ov-file#setting-up-ci) for more details. 
