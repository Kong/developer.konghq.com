---
title: How to split a large query parameter whose value contains a question mark
content_type: support
description: Use the `request-transformer-advanced` plugin to split a query parameter whose value contains an embedded question mark into two separate query parameters.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I split a large query parameter whose value contains a question mark into two separate query parameters?
  a: |
    Use the `request-transformer-advanced` plugin to do this in two steps, since its transformations run in a fixed order (remove, rename, replace, add, append):

    - Configure `config.replace.querystring` with a Lua function that extracts everything before the embedded `?` from the original `apikey` value.
    - Configure `config.add.querystring` with a Lua function that reads the value for the new parameter (for example `AppID`) from the raw, unmodified querystring via `kong.request.get_raw_query()` — not from `query_params`, which by the time `add` runs already reflects the `replace` step's rewritten value.
---

## Overview

Is it possible to split a large query parameter into 2 smaller query parameters when the value contains a question mark character?

Examples:

URL received:

```

http://<HOST>:8000/path?apikey=123123?key1=value1
```

Query parameter:

```

"?apikey=123123?key1=value1"
```

Current response:

```

"args": {
    "apikey": "123123?key1=value1"
}
```

Desired result:

```

"?apikey=123123&AppID=value1"
```

## Steps

This can be done through the Request Transformer Advanced plugin.

The query parameter for `apikey` is coming into kong as a long string. To split this up we will utilize the advanced templates inside the Request Transformer Advanced plugin. This will allow us to grab the value of `apikey` and split the string into 2 query parameters.

Important: Request Transformer Advanced applies its transformations in a fixed order (remove, rename, replace, add, append). If `config.replace.querystring` rewrites a parameter's value, any `config.add.querystring` template that runs afterwards no longer sees that parameter's *original* value — it only sees the already-replaced one. Since both steps in this recipe need to read from the original, unmodified `apikey` value, the `add` step must read it via `kong.request.get_raw_query()` (the raw, untouched querystring) rather than via `query_params.apikey`, which will already reflect the `replace` step's output by the time `add` runs.

1. We need to create a function for `config.replace.querystring`. This will replace the value for `apikey` to just the data before the `?key1value`. In the function we find the location of the `?` and then create a substring of the starting point up until the `?`.

   Doing this created the first query parameter of just `apikey=123123`.

   Save the file as `test.lua`.

   Sample Snippet:

   ```lua
   apikey:$((function() 
       local s=query_params.apikey:find("?") 
       local first=query_params.apikey:sub(1,s-1)
       return first
   end)())
   ```

2. Next we need to create a function for `config.add.querystring`. This will create a 2nd query parameter `AppID` with the value of `value1`. In this function we read the raw, original querystring (not `query_params`, which by this point has already been rewritten by Step 1's `replace` transformation) via `kong.request.get_raw_query()`, find the location of the `=` after `key1`, and then create a substring of the remaining value.

   Doing this created the second query parameter of just `AppID=value1`.

   Save this file as `test2.lua`.

   Sample Snippet:

   ```lua
   AppID:$((function() 
       local raw = kong.request.get_raw_query()
       local s = raw:find("?")
       local second = raw:sub(s+1,#raw)
       local third = second:find("=")
       local secvalue = second:sub(third+1,#second)
       return secvalue
   end)())
   ```

3. Create the plugin via `curl` parsing in the 2 files.

   ```bash
   curl --location --request POST 'http://<HOST>:8001/plugins' \
   --header 'Kong-Admin-Token: <TOKEN>' \
   --form 'config.replace.querystring=@"/<pathToFile>/test.lua"' \
   --form 'config.add.querystring=@"/<pathToFile>/test2.lua"' \
   --form 'name="request-transformer-advanced"'
   ```

   Initial Request:

   ```

   http://<HOST>:8000/path?apikey=123123?key1=value1
   ```

   Final Response:

   ```

   "args": 
   {
   	"AppID": "value1",
   	"apikey": "123123"
   }
   ```

At this point the query parameters are split into 2 separate parameters.
