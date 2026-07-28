---
title: "Deck conversion of an OAS file to Kong configuration using \"deck file openapi2kong\" results in regex-based routes, leading to \"no route matched\" errors"
content_type: support
description: "When using the `deck` tool to convert an OAS file into a Kong configuration, we adhere to the OAS standards by ensuring the route is an exact match."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I resolve `deck file openapi2kong` converting an OAS path to a regex-based route that causes "no route matched" errors on extended paths?
  a: |
    `deck` converts OAS paths to regex-based routes anchored with `$`, so requests to extended paths beyond the exact match (for example with `strip_path` set to `true`) return 404 "no route matched" errors. Fix this by adding a templated path parameter (for example `/kong/test/{id}`) in the OAS file, then use the Request Transformer plugin's `replace.uri` to rewrite the upstream URI using the captured parameter.
---

## Problem

An OAS file has the path specified below.

```yaml
paths:
  /kong/test
    get:
     . . .
```

`deck` converts the path to the regex-based route `~/kong/test$`, leading to "no route matched" errors when accessing extended paths like `/kong/test/<id>`.

## Solution

When using the `deck` tool to convert an OAS file into a Kong configuration, we adhere to the OAS standards by ensuring the route is an exact match. This is achieved through the use of regex, with the addition of the "$" character at the end. Particularly when the customer uses an extended path with `strip_path` set to `true`, this can cause issues where requests return a 404 error because no route is found.

To address this issue, you can modify the OAS file to include path templating and use the Request Transformer plugin to dynamically adjust the upstream request URI. Here are the detailed steps to resolve the issue:

1. Change the path in the OAS file to include a templated parameter. For example, change `/kong/test/{id}`. This will help convert the path to a regex-based route in the declarative config with capture groups similar to `/kong/test/(?<id>[^#?/]+)$`.

   ```yaml
   paths:
     /kong/test/{id}:
       get:
         ...
   ```

2. Add a Request Transformer plugin at the Service level or individual route level with the `replace.uri` parameter set to include the captured parameter from the URI.

   ```yaml
   x-kong-plugin-request-transformer-advanced:
     name: request-transformer-advanced
     instance_name: test-vibin
     enabled: true
     config:
       replace:
         uri: /anything/$(uri_captures['id'])
   ```

By following these steps, you can ensure that requests to paths like `http://localhost:8000/kong/test/incidents` are correctly routed to `http://{httpbin.org}/anything/incidents` in the backend.

For more information on path templating, you can refer to the OpenAPI Specification documentation on paths and operations: Path Templating

For details on how to use the Request Transformer plugin, you can check the Kong documentation or the example provided in the GitHub repository: Request Transformer Plugin

Remember to adjust the `{host_url1}` and `{id}` placeholders to match your actual upstream URL and desired path parameter.
