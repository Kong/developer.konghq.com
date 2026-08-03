---
title: Using OIDC with a custom bearer token header
content_type: support
description: "Use the serverless `pre-function` plugin to copy a bearer token from a custom header into the `Authorization` header so the OIDC plugin can find it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I get the OIDC plugin to find a bearer token sent in a custom header?
  a: |
    The OIDC plugin only reads the token from the `Authorization` header.
    Use the serverless `pre-function` plugin to copy the value from your custom header into `Authorization` before the OIDC plugin runs.
related_resources:
  - text: "`plugin-development`"
    url: "/gateway/plugin-development/"
  - text: "`serverless-functions`"
    url: "/plugins/serverless-functions/"
---

## Problem

The OIDC plugin fails when we send the bearer token in a custom header, how do we get the plugin to find the token? Custom header example: `jefftoken-xyz: Bearer XXXXXXXXXX`

## Solution

Use the serverless pre-function plugin to change the header from `jefftoken-xyz` to `Authorization`.

1. Create some custom lua code to add a new header using the value from `jefftoken-xyz` and save the file as `custom-auth.lua`:

   ```lua
   local authhead = kong.request.get_header("jefftoken-xyz")

   kong.service.request.set_header("authorization", authhead)
   ```

   Optionally, you can also delete the original header with the following additional line depending on whether the upstream still needs the original value:

   ```lua
   kong.service.request.clear_header("jefftoken-xyz")
   ```

2. Add a pre-function plugin with config file `custom-auth.lua` (make sure your working directory has the `custom-auth.lua` file in it):

   ```bash
   curl -i -X POST http://localhost:8001/services/<your service name>/plugins \
   -H "kong-admin-token: <your admin token value>" \
   -F "name=pre-function" \
   -F "config.access[1]=@custom-auth.lua" \
   ```

The OIDC plugin will now find the bearer token in the `Authorization` header.
