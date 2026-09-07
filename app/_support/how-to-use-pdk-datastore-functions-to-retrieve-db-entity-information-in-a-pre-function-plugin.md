---
title: How to use PDK Datastore functions to retrieve DB entity information in a `pre-function` plugin
content_type: support
description: "Use PDK `kong.db` functions to query database entities like `jwt_secrets` that fall outside the default core DAO set, and the `untrusted_lua` setting required to access them from a `pre-function` plugin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: PDK plugin development: Access the Datastore
    url: /plugin-development/access-the-datastore/
  - text: Kong JWT plugin handler.lua (GitHub)
    url: https://github.com/Kong/kong/blob/master/kong/plugins/jwt/handler.lua#L101-L107
tldr:
  q: How do I use PDK Datastore functions to retrieve DB entity information in a `pre-function` plugin?
  a: |
    The `untrusted_lua` sandbox tier for `pre-function`/`post-function`/serverless-functions plugins determines whether `kong.db` is available at all, and a stricter tier can make it entirely absent. A `lax`-style tier restores `kong.db`, but only as a curated table exposing a fixed set of core entities (`services`, `routes`, `consumers`, `plugins`, `keys`, `certificates`, `upstreams`, `targets`, `snis`) — entities like `jwt_secrets` are still not reachable. Set `untrusted_lua: on` (`KONG_UNTRUSTED_LUA=on`) to restore the full `kong.db` module with dynamic access to any entity's DAO.

    From there, call the entity's DAO select function (for example `kong.db.jwt_secrets:select_by_key(key)`), use `kong.log.inspect()` to see the row's fields, then reference the fields you need directly (for example `row["secret"]`, `row["consumer"]["id"]`).
---

## Overview

How do I use PDK Datastore functions to retrieve DB entity information in a `pre-function` plugin?

## Steps

Background

The basic description of the PDK functions can be found here.

The doc mentions the following entities:

```lua

-- Core DAOs
local services  = kong.db.services
local routes    = kong.db.routes
local consumers = kong.db.consumers
local plugins   = kong.db.plugins
```

However there are more rows in the DB that can be referenced.

Important prerequisite: the `untrusted_lua` sandbox tier for `pre-function`/`post-function`/serverless-functions plugins controls whether `kong.db` is available at all. Under a stricter tier, `kong.db` may be entirely absent from the sandboxed environment, causing the code below to fail with `attempt to index field 'db' (a nil value)`. A more permissive tier may expose `kong.db` only as a curated table limited to a fixed set of core entities (`services`, `routes`, `consumers`, `plugins`, `keys`, `certificates`, `upstreams`, `targets`, `snis`) — `jwt_secrets`, and any other entity outside that fixed list, would still not be reachable. To use `kong.db.jwt_secrets` (or any other non-core-entity DAO) as shown below, `untrusted_lua` must be set to `on` (`KONG_UNTRUSTED_LUA=on` in `kong.conf`/env), which restores the full `kong.db` module with dynamic access to every entity's DAO. This is a global, node-wide setting — check your Kong Gateway version's documentation for its exact `untrusted_lua` tier behavior.

Example: Extract a secret from the `jwt_secrets` table

This example assumes several components are already in place:

- Consumer and JWT Credential already exist in Kong.

- Service / Route / JWT plugin installed

JWT credential details:

```
Key: test-key
Secret: test-secret
```

This example will focus a lot on the `pre-function` plugin code, how to determine the information available and how to use it.

1. Find the functions needed to invoke row retrieval for a specific table:

   As this example is using the JWT plugin and the `jwt_secrets` table, I went looking inside the jwt plugin code on the public github and found the `select_by_key` function could be used to return details of a jwt_secret row for any particular key.

   Reference code.

   The magic line is:

   ```lua

   local row, err = kong.db.jwt_secrets:select_by_key(jwt_secret_key)
   ```

   Inside the `pre-function` plugin's access phase, put the following code so we can test the error handling:

   ```lua

   local jwt_credential_key = "fake-key"

   local jwt_secret_row, err = kong.db.jwt_secrets:select_by_key(jwt_credential_key)

   if jwt_secret_row == nil then
     kong.log("Error retrieving jwt_secret row")
     return
   end

   kong.log("jwt_secret row retrieved successfully")
   ```

   This will result in the Kong error log showing the error:

   ```

   [pre-function] Error retrieving jwt_secret row
   ```

   Changing the code back to use the valid `test-key` key, the success message is logged:

   ```

   [pre-function] jwt_secret row retrieved successfully
   ```

2. Setup debug function to view all contents of the row:

   The Kong PDK has an inspect function for showing the contents of tables.

   Update the `pre-function` code to include and use this function like below:

   ```lua

   local jwt_credential_key = "test-key"

   local jwt_secret_row, err = kong.db.jwt_secrets:select_by_key(jwt_credential_key)

   if jwt_secret_row == nil  then
     kong.log("Error retrieving jwt_secret row")
     return
   end

   kong.log("jwt_secret row retrieved successfully")

   kong.log.inspect.on()
   kong.log.inspect(jwt_secret_row)
   kong.log.inspect.off()
   ```

   Output row details:

   ```

   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |{
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  algorithm = "HS256",
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  consumer = {
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |    id = "1e31f55a-90a5-4838-afb9-9664b4f70929"
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  },
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  created_at = 1700701173,
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  id = "8d50298c-6231-407f-be5f-5942d9bed606",
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  key = "test-key",
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |  secret = "test-secret"
   | 2023/11/23 03:41:05 [debug] 2395#0: *2646 |}
   ```

3. Use the discovered information to extract and use any values needed:

   The final code for this example removes the debug function as we now know the contents of the table, and we can finally structure our code to use the details provided.

   Final Code:

   ```lua

   local jwt_credential_key = "test-key"

   local jwt_secret_row, err = kong.db.jwt_secrets:select_by_key(jwt_credential_key)

   if jwt_secret_row == nil then
     kong.log("Error retrieving jwt_secret row")
     return
   end

   kong.log(jwt_secret_row["secret"])
   kong.log(jwt_secret_row["consumer"]["id"])
   kong.log(jwt_secret_row["algorithm"])
   ```

   Kong log output:

   ```

   [pre-function] test-secret
   [pre-function] 1e31f55a-90a5-4838-afb9-9664b4f70929
   [pre-function] HS256
   ```
