---
title: How to pass optional field as empty string in request body using the request validator plugin
content_type: support
published: false
description: Set the request validator plugin's `len_min` parameter to `0` to allow an optional string field to accept an empty string value.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the related documentation
    url: /plugins/request-validator/#body-schema-definition
tldr:
  q: How do I let an optional field accept an empty string in the request validator plugin's schema?
  a: |
    Set the field's `len_min` parameter to `0` in the request validator plugin's schema. Without it, an empty string value fails with a "request body doesn't conform to schema" error.
---

## Overview

How to pass an optional field as empty string in request body using request validator.

When using request validator plugin to validate request body and trying to pass empty string value in one of the optional fields in request body using the code below, produces an error that the request body doesn't conform to schema

```json
{
"location": {
"type": "string",
"required": false
}
```

## Steps

The solution would be to set the `len_min` parameter to `0` like so:

```json
[ { "location": { "type": "string", "required": false, "len_min": 0 }} ]
```

With that setting it works with a 0 length string.

```bash
curl -k --header 'Content-Type: application/json' https://proxy.kong.lan/httpbin/anything --data '{ "location": "" }'
{
  "args": {},
  "data": "{ \"location\": \"\" }",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Connection": "keep-alive",
    "Content-Length": "18",
    "Content-Type": "application/json",
    "Host": "kongpose_httpbin_1",
    "User-Agent": "curl/7.79.1",
    "X-Forwarded-Host": "proxy.kong.lan",
    "X-Forwarded-Path": "/httpbin/anything",
    "X-Forwarded-Prefix": "/httpbin"
  },
  "json": {
    "location": ""
  },
  "method": "POST",
  "origin": "172.20.0.1, 172.20.0.31",
  "url": "http://proxy.kong.lan/anything"
}
```

But with this body schema

```json
[ { "location": { "type": "string", "required": false }} ]
```

we get an error

```bash
curl -k --header 'Content-Type: application/json' https://proxy.kong.lan/httpbin/anything --data '{ "location": "" }'
{"message":"request body doesn't conform to schema"}
```

The related documentation can be found here.
