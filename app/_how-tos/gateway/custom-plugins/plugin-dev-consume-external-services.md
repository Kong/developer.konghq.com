---
title: Consume external services in a custom plugin
description: Consume data from external services in your custom plugin using an HTTP client and parsing JSON values.
  
content_type: how_to

permalink: /custom-plugins/get-started/consume-external-services/
breadcrumbs:
  - /custom-plugins/

series:
  id: plugin-dev-get-started
  position: 4

tldr:
  q: How can I call external services in my custom plugin?
  a: Use the [lua-resty-http](https://github.com/ledgetech/lua-resty-http) and [lua-cjson](https://github.com/mpx/lua-cjson) libraries to make HTTP requests and parse the JSON responses.

products:
  - gateway

tags:
  - custom-plugins
  - pdk

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Plugins
    url: /gateway/entities/plugins/

automated_tests: false
---

## Include HTTP and JSON support

Start by importing two new libraries to the `handler.lua` file to enable 
HTTP and JSON parsing support. 

We'll use the [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
library for HTTP client connectivity to the third-party service.

For JSON support, we'll use the [lua-cjson](https://github.com/mpx/lua-cjson) library.

Add the libraries to the top of `handler.lua`:

```lua
local http  = require("resty.http")
local cjson = require("cjson.safe")
```

## Send third-party HTTP requests

The `lua-resty-http` library provides a simple HTTP request
function (`request_uri`) that we can use to reach out to our third-party service. 
In this example, we'll send a `GET` request to the _httpbin.org/anything_ API.

Add the following to the top of the `MyPluginHandler:response` function inside the
`handler.lua` module:
```lua
local httpc = http.new()

local res, err = httpc:request_uri("http://httpbin.konghq.com/anything", {
  method = "GET",
})
```

If the request to the third-party service is successful, the `res` 
variable will contain the response.

## Handle response errors

The {{site.base_gateway}} 
[Plugin Development Kit](/gateway/pdk/reference/) 
provides you with various functions to help you handle error conditions.

In this example, we're processing responses from the upstream service
and decorating the client response with values from the third-party service. 
If the request to the third-party service fails, we can terminate the response processing and return to the client with an error, 
or continue processing the response and not complete the custom header logic. 

In this example, we'll terminate the
response processing and return a `500` internal server error to the client.

Add the following to the `MyPluginHandler:response` function, immediately
after the `httpc:request_uri` call:

```lua
if err then
  return kong.response.error(500,
    "Error when trying to access third-party service: " .. err,
    { ["Content-Type"] = "text/html" })
end
```

After this step, the `handler.lua` file looks like this:
```lua
local http  = require("resty.http")
local cjson = require("cjson.safe")

local MyPluginHandler = {
    PRIORITY = 1000,
    VERSION = "0.0.1",
}

function MyPluginHandler:response(conf)

    local httpc = http.new()

    local res, err = httpc:request_uri("http://httpbin.konghq.com/anything", {
    method = "GET",
    })

    if err then
        return kong.response.error(500,
          "Error when trying to access third-party service: " .. err,
          { ["Content-Type"] = "text/html" })
      end
    
    kong.response.set_header(conf.response_header_name, "response")
end
```

## Process JSON data from third-party response

This third-party service returns a JSON object in the response body. 
We'll parse and extract a single value from the JSON body.

1. In your `handler.lua` file, use the `decode` function in the `lua-cjson` library passing in the `res.body` value received from the `request_uri` function. Add this to your file right below what you added in the previous step:
   ```lua
   local body_table, err = cjson.decode(res.body)
   ```

   The `decode` function returns a tuple of values. The first value contains the result of a successful decoding and represents the JSON as a table containing the parsed data. If an error occurs, the second value will contain error information (or `nil` on success).

1. Add the following to the `MyPluginHandler:response` function after the previous line to stop processing in case of an error:
   ```lua
   if err then
     return kong.response.error(500,
       "Error while decoding third-party service response: " .. err,
       { ["Content-Type"] = "text/html" })
   end
   ```

1. Update the following line after the error handling to set the value of the `url` field in the response as the header value instead of `response`:
   ```lua
   kong.response.set_header(conf.response_header_name, body_table.url)
   ```

After this step, the `handler.lua` file looks like this:
```lua
local http  = require("resty.http")
local cjson = require("cjson.safe")

local MyPluginHandler = {
  PRIORITY = 1000,
  VERSION = "0.0.1",
}

function MyPluginHandler:response(conf)

  kong.log("response handler")

  local httpc = http.new()

  local res, err = httpc:request_uri("http://httpbin.konghq.com/anything", {
    method = "GET",
  })

  if err then
    return kong.response.error(500,
      "Error when trying to access third-party service: " .. err,
      { ["Content-Type"] = "text/html" })
  end

  local body_table, err = cjson.decode(res.body)

  if err then
    return kong.response.error(500,
      "Error when decoding third-party service response: " .. err,
      { ["Content-Type"] = "text/html" })
  end

  kong.response.set_header(conf.response_header_name, body_table.url)

end

return MyPluginHandler
```

## Update the tests

At this stage, using the `pongo run` command to execute the integration tests will result in errors.
The value of the header has changed from `response` to `http://httpbin.konghq.com/anything`. 

1. Update the expected header value in `spec/my-plugin/01-integration_spec.lua`:
   ```lua
   -- validate the value of that header
   assert.equal("http://httpbin.konghq.com/anything", header_value)
   ```

1. Run the tests:
   ```sh
   pongo run
   ```
   Pongo should report a successful test run.

{:.info}
> **Note**: This series provides examples to get you started. 
> In a real plugin development scenario, you would want to build integration tests for third-party services by providing a test dependency using a mock service instead of making network calls to the actual third-party service used. 
> Pongo supports test dependencies for this purpose. 
> See the [Pongo documentation](https://github.com/Kong/kong-pongo?tab=readme-ov-file#test-dependencies) for details on setting test dependencies.
