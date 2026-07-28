---
title: 404 Not Found on CORS OPTIONS (preflight) requests
content_type: support
description: "Kong returns 404 Not Found for CORS OPTIONS preflight requests unless a route is configured to accept the OPTIONS method for the path, in addition to enabling the CORS plugin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: CORS (MDN Web Docs)
    url: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
tldr:
  q: Why does Kong return a 404 Not Found error for CORS OPTIONS (preflight) requests?
  a: |
    Browsers send a preflight `OPTIONS` request before certain cross-origin requests. If Kong has no route configured to accept `OPTIONS` for that path, it returns `404 Not Found` even though the CORS plugin is enabled. Configure a route that matches the `OPTIONS` method, in addition to enabling the CORS plugin, so preflight requests are handled.
---

## Problem

I use a web browser to send requests to Kong from a different Service.

Assuming `kong` is running on `http://kong:8000` and requests are sent from `http://example.com`, and the request path is `/xxx`, since `kong:8000` and `example.com` are different domains, I have enabled the CORS plugin with the following configuration to allow these requests:

```yaml
scope: global
methods: GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS,TRACE,CONNECT
headers: *
origins: http://example.com
preflight_continue: false
```

However, when I send requests I still see the following error output from the browser:

```
Access to fetch at 'http://kong:8000/xxx' from origin 'http://example.com' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: It does not have HTTP ok status.
```

The browser sends an `OPTIONS` HTTP request to `http://kong:8000/xxx` and gets a `404 Not Found` response.

## Cause

There are 2 types of CORS requests:

1st type: simple request

The browser only sends 1 request to `http://kong:8000/xxx`, and you will not encounter this error if you have enabled the CORS plugin described above.

2nd type: preflight request

The browser sends a preflight request (`OPTIONS` method) before the actual request, as shown below:

```
preflight request: OPTIONS http://kong:8000/xxx
actual request: GET/POST/PATCH/DELETE/... http://kong:8000/xxx
```

You will encounter this error if you have not configured the following route in Kong:

```
OPTIONS /xxx
```

## Solution

1. Enable the CORS plugin described above.
2. Create the following route object in Kong to receive all CORS `OPTIONS` requests:

   ```yaml
   service: null
   protocols: http,https
   host: null
   sni: null
   methods: OPTIONS
   paths: /
   ```
