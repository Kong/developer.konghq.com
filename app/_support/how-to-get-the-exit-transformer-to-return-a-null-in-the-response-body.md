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
  - text: Disclaimer - review the untrusted_lua configuration reference before updating this on your environment
    url: /gateway/reference/configuration/#untrusted_lua
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

When configuring the `exit-transformer` to respond with an updated response body, we notice that any field returned with `null` as its value is not being returned in the response body.

For example:

```lua
return function(status, body, headers) 
    if status > 399 then
        body = { hello = "test", goodbye = null}
    end

    return status, body, headers
end
```

How can we resolve this and have a `null` returned as its value?

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
