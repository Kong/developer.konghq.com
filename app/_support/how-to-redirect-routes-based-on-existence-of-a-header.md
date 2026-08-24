---
title: How to redirect routes based on existence of a header
content_type: support
description: "Use a Request Termination plugin and an Exit Transformer plugin to redirect requests to different routes based on whether a header like `x-vendor` is present."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I redirect a request to a different route based on whether a header exists?
  a: |
    Use a Request Termination plugin and an Exit Transformer plugin on a shared "main" route: the Exit Transformer's function checks for the header (for example `x-vendor`) with `kong.request.get_header()` and returns a 302 with a `Location` header pointing at one downstream route if the header is missing, or another if it's present. Each downstream route can then have its own plugins (for example Rate Limiting Advanced) applied independently.
---

## Overview

Is it possible to have Kong re-route a request based on Header existence to alter which plugins are triggered? Example: Route 1 - Has the Rate Limiting Advanced plugin. Should trigger if the header `x-vendor` does not exist. Route 2 - Has no plugin. Should trigger if the header `x-vendor` exists.

## Steps

This can be accomplished through out-of-the-box plugins with some custom code.

To start off you will need 3 Routes created all pointing to their respective services (or the same service). For this example, we will utilize the same service for all 3 Routes. The main service will have a Request Termination plugin and an Exit Transformer plugin.

Create Service:

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/services/ \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
	"name": "test",
	"host": "mockbin.org",
	"path": "/",
	"port": 80,
	"protocol": "http"}'
```

Create Route (main):

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/services/test/routes \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
	"name": "mainPath",
	"paths": ["/main"],
	"protocols": ["http", "https"]}'
```

Note: Route's `protocols` field defaults to `["https"]` only (not `["http", "https"]`) since Kong 3.x — explicitly setting `protocols` as shown above is required, or the final plain-`http://` curl tests below will fail with `426 {"message":"Please use HTTPS protocol"}` instead of working.

Create Route (1):

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/services/test/routes \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
	"name": "route1",
	"paths": ["/route1"],
	"protocols": ["http", "https"]}'
```

Create Route (2):

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/services/test/routes \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
	"name": "route2",
	"paths": ["/route2"],
	"protocols": ["http", "https"]}'
```

Create Request Termination Plugin (Attached to Main Route):

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/routes/mainPath/plugins/ \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
 "name": "request-termination",
 "config":
	{
		"status_code": 403}}'
```

Create Exit Transformer Plugin (Attached to Main Route):

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/routes/mainPath/plugins/ \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
 "name": "exit-transformer",
 "config":
	{
		"functions":[
      "return function(status, body, headers)\n  status = 302\n  local path = kong.request.get_header(\"x-vendor\")       \n  if not path then\n    headers = { [\"Location\"] = \"http://<HOSTNAME>:8000/route1\"}\n    body = { message = \"missing a header, x-vendor\" }\n  else\n    headers = { [\"Location\"] = \"http://<HOSTNAME>:8000/route2\"}\n    body = { message = \"redirect is needed\" }\n  end\n  return status, body, headers\nend\n"
    ]}}'
```

Create Rate Limiting Advanced plugin (Attached to Route 1). Note that `sync_rate` cannot be set at all when `strategy` is (or defaults to) `"local"` — live-tested on Kong Gateway 3.14.0.0: including `"sync_rate":0` alongside `"strategy":"local"` fails with `400 schema violation ("sync_rate cannot be configured when using a local strategy")` regardless of whether `strategy` is set explicitly or left to its `"local"` default. `sync_rate` must be omitted entirely (as below) for the local strategy; only set it if `strategy` is `"redis"` or `"cluster"` instead:

```bash

curl --request POST \
  --url http://<HOSTNAME>:8001/routes/route1/plugins \
  --header 'Content-Type: application/json' \
  --header 'Kong-Admin-Token: <TOKEN>' \
  --data '{
  "name": "rate-limiting-advanced",
	"tags":["rate1"],
	"config": 
	{ 
		"limit":[2], 
		"window_size":[60], 
		"strategy":"local"}}'
```

---

Now we can run a quick test to confirm. When hitting the Main Route with and without the `x-vendor` header. The Exit Transformer responds with a 302 and a `Location` header, so the verification curl commands need `-L`/`--location` to actually follow the redirect onto Route 1 or Route 2 — without it, curl only sees the 302 from the main route and never reaches either route's plugins.

With the header `x-vendor`, the request is redirected to Route 2, which has no rate limiting plugin, so it is not counted.

```bash

curl --request GET \
  --location \
  --url http://<HOSTNAME>:8000/main \
  --header 'x-vendor: test'
```

Without the header `x-vendor`, the request is redirected to Route 1. Call this 3x and you will see the rate limiting advanced plugin be triggered.

```bash

curl --request GET \
  --location \
  --url http://<HOSTNAME>:8000/main
```
