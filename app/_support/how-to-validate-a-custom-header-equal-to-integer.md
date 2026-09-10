---
title: how to use request validator plugin to validate whether a custom header is equal to an integer
content_type: support
description: "Use the `request-validator` plugin's `parameter_schema` to require a custom header value to match a specific integer, then apply the plugin to a route through the Admin API."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I use the request-validator plugin to check that a custom header equals a specific integer?
  a: |
    Define a `parameter_schema` entry for the header in the `request-validator` plugin config, using a JSON Schema with `minimum` and `maximum` set to the required integer value. Apply the plugin to the route through the Admin API, then Kong rejects requests where the header doesn't match.
related_resources: []
---

## Overview

How to use the `request-validator` plugin to validate whether a custom header is equal to an integer?

## Steps

1. Write the below JSON file called `header-equal-int.json`. The following config requires that the `x-h1` header value is `1`. Replace `x-h1` and `1` with your actual values:

   ```json
   {
     "name": "request-validator",
     "config": {
       "version": "draft4",
       "parameter_schema": [
         {
           "name": "x-h1",
           "in": "header",
           "required": true,
           "schema": "{\"type\": \"number\", \"minimum\": 1, \"maximum\": 1}",
           "style": "simple",
           "explode": false
         }
       ]
     }
   }
   ```

2. Enable the request-validator plugin on your route with the JSON file above:

   ```bash
   curl -X POST http://{KONG}:8001/routes/{ROUTE}/plugins \
       -H "Content-Type: application/json" \
       --data @header-equal-int.json
   ```

   You could also patch the above JSON file to an existing request-validator plugin:

   ```bash
   curl -X PATCH http://{KONG}:8001/plugins/<PLUGIN-ID> \
       -H "Content-Type: application/json" \
       --data @header-equal-int.json
   ```

3. Testing:

   ```bash
   ❯ curl <KONG>:8000/{ROUTE} -H "x-h1:2"
   {"message":"request param doesn't conform to schema"}%

   ❯ curl <KONG>:8000/{ROUTE} -H "x-h1:0"
   {"message":"request param doesn't conform to schema"}%

   ❯ curl <KONG>:8000/{ROUTE} -H "x-h1:a"
   {"message":"request param doesn't conform to schema"}

   ❯ curl <KONG>:8000/{ROUTE} -H "x-h1:1"
   200 response
   ```

   Confirmed Kong will proxy the request to upstreams only when `x-h1` equals `1`.
