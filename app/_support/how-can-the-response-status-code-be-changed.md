---
title: Changing the response status code sent to the client with a post-function plugin
content_type: support
description: How to use a `post-function` serverless plugin to rewrite the status code and body Kong returns to the client when the upstream sends back an unwanted status code.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the response status code be changed?
  a: |
    Add a `post-function` plugin running in the `header_filter` phase that checks `kong.service.response.get_status()` and, when it matches the unwanted upstream status code, calls `kong.response.exit()` with the desired status code and body before the response reaches the client.
related_resources: []
---

## Overview

The Upstream service sends a 406 status code but it is required to respond to the client with a 404 status code. How can the status code be changed?

## Steps

You can use a `post-function` serverless plugin to change the response details. For example, create a Kong Service that points to https://httpbin.org (note: httpbin.org is a public demo service outside Kong's control and may be temporarily unavailable; substitute any reachable upstream that lets you request a specific status code);

```bash
curl -X POST 'https://api.kong.lan:8444/default/services' \
-H 'Content-Type: application/json' \
--data-raw '{
    "host": "httpbin.org",
    "protocol": "https",
    "name": "remote-httpbin",
    "port": 443,
    "retries": 0
}'
```

and a corresponding Route for the Service;

```bash
curl -X POST 'https://api.kong.lan:8444/default/services/remote-httpbin/routes' \
-H 'Content-Type: application/json' \
--data-raw '{
    "name": "remote-httpbin",
    "paths": [
        "/remote-httpbin"
    ]
}'
```

Test the Kong API with the `/status` endpoint from httpbin.org (note the 406 response code);

```bash
curl -s https://proxy.kong.lan/remote-httpbin/status/406 -w "%{http_code}"
{"message": "Client did not request a supported media type.", "accept": ["image/webp", "image/svg+xml", "image/jpeg", "image/png", "image/*"]}406
```

Create a `serverless.lua` file containing code like this;

```lua
if (kong.service.response.get_status() == 406) then
  return kong.response.exit(404, {message="no Route matched with those values"})
end
```

Add the plugin to a Route;

```bash
curl -s -X POST 'https://api.kong.lan:8444/default/routes/remote-httpbin/plugins' \
-F 'name="post-function"' \
-F 'config.header_filter=@"./serverless.lua"'
```

Test the Kong API again, with the same `/status` endpoint from httpbin.org. Note the 404 response code from the plugin;

```bash
curl -s https://proxy.kong.lan/remote-httpbin/status/406 -w "%{http_code}"
{"message":"no Route matched with those values"}404
```

Test the Kong API again, with the same `/status` endpoint from httpbin.org. Note the 200 response code from the Upstream is unchanged by the plugin.

```bash
curl -s https://proxy.kong.lan/remote-httpbin/status/200 -w "%{http_code}"
200
```
