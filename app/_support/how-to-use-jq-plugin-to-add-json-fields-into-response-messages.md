---
title: How to use JQ plugin to add JSON fields into response messages
content_type: support
description: Use the `jq` plugin's `response_jq_program` to inject additional JSON fields into upstream response bodies without modifying the upstream service.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: jq plugin documentation
    url: /plugins/jq/
tldr:
  q: How do I use the `jq` plugin to add JSON fields to a response message?
  a: |
    Configure the `jq` plugin's `response_jq_program` (with `response_if_media_type` and
    `response_if_status_code` filters) to merge additional JSON fields, such as
    `{"message":"Message successfully sent."}`, into the upstream response body.
---

## Overview

By the JQ plugin, we can add/remove JSON fields into request or response messages.

## Steps

For example, we would like to add {"message":"Message successfully sent."} into response message.

JQ plugin settings:

```yaml
response_if_media_type:
- application/json
response_if_status_code:
- 200
response_jq_program: '{"message":"Message successfully sent."}+.'
```

Assuming we expose the Kong proxy at http://localhost:8000 and enabled the JQ plugin on the `/add-res` path.

And we configured the `/add-res` path to forward to https://httpbin.org/anything.

Before enabling the JQ plugin:

```bash
curl localhost:8000/add-res
{
"args": {},
"data": "",
"files": {},
"form": {},
"headers": {
"Accept": "*/*",
"Host": "httpbin.org",
"User-Agent": "curl/7.79.1",
"X-Amzn-Trace-Id": "Root=1-62cfa459-67b1b6af5f9377fe27697b1d",
"X-Forwarded-Host": "localhost",
"X-Forwarded-Path": "/add-res",
"X-Forwarded-Prefix": "/add-res"
},
"json": null,
"method": "GET",
"origin": "10.0.0.1, 183.77.162.252",
"url": "https://localhost/anything"
}
```

After enabling the JQ plugin, the `"message": "Message successfully sent."` field is added into the response body:

```bash
curl localhost:8000/add-res
{
"message": "Message successfully sent.",
"args": {},
"data": "",
"files": {},
"form": {},
"headers": {
"Accept": "*/*",
"Host": "httpbin.org",
"User-Agent": "curl/7.79.1",
"X-Amzn-Trace-Id": "Root=1-62cfa303-6b92e5c945f8b85f274c7da4",
"X-Forwarded-Host": "localhost",
"X-Forwarded-Path": "/add-res",
"X-Forwarded-Prefix": "/add-res"
},
"json": null,
"method": "GET",
"origin": "10.0.0.1, 183.77.162.252",
"url": "https://localhost/anything"
}
```

To learn more, see the jq plugin documentation.
