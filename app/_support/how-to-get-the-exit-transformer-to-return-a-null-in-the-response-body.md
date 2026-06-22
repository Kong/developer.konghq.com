---
title: How to get the Exit Transformer to return a null in the response body
content_type: support
description: Configure the Exit Transformer plugin to return a field with a null value in the response body by updating the untrusted Lua environment variables and using cjson.null.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Exit transformer plugin
    url: /plugins/exit-transformer/
tldr:
  q: How do I configure the Exit Transformer plugin to return a field with a null value in the response body?
  a: |
    Update the untrusted Lua environment variables to allow `cjson`:
    set `KONG_UNTRUSTED_LUA: "sandbox"` and `KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES: "cjson"`
    (review the `untrusted_lua` configuration reference first). Then, in your `exit-transformer`
    function, assign the field using `(require "cjson").null` instead of a bare `null`. When the
    plugin runs, the field is returned with a `null` value in the response body.
---

## Overview

When using the Exit Transformer plugin, you may want to return a field with a `null` value in the response body. However, if you try to assign a field a value of `null` directly in your Lua code, you will encounter an error because `null` is not defined in Lua.

For example:

```lua
return function(status, body, headers) 
    if status > 399 then
        body = { hello = "test", goodbye = null}
    end

    return status, body, headers
end
```

In the above code, `null` is not defined, so you will get an error in your logs. 

## Steps

To accomplish this we need to make a few updates to the environment variables and then change the Lua slightly to require `cjson`.

First, let's update the environment variables below:

```yaml
KONG_UNTRUSTED_LUA: "sandbox"
KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES: "cjson"
```

Please review the untrusted Lua configuration reference before updating this on your environment.

Next, let's add the following to our exit transformer (to do this I saved this to a file called `bodyNull.lua`):

```lua
return function(status, body, headers) 
    if status > 399 then
        body = { hello = (require "cjson").null }
    end

    return status, body, headers
end
```

Then we need to create the exit transformer plugin:

```bash
curl --location --request POST 'http://localhost:8001/plugins' \
--header 'Kong-Admin-Token: <token>' \
--form 'config.functions=@"/<pathtofile>/bodyNull.lua"' \
--form 'name="exit-transformer"'
```

For this specific test I created a `request-termination` plugin set to a status of 400 to trigger the Lua from the exit transformer.

```bash
curl -X POST http://localhost:8001/plugins \
    --header 'Kong-Admin-Token: <token>' \
    --data "name=request-termination"  \
    --data "config.status_code=400" \
```

Now if we run a request we can see that the field `hello` is returned with a null value.

```json
{
	"hello": null
}
```
