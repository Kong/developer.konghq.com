---
title: How to add Request and Response payloads to the logging plugins
content_type: support
description: "The log content can easily be changed using the `kong.log.set_serialize_value` PDK functions."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I add request and response payloads to the logging plugins output?
  a: |
    Use a pre-function plugin to call `kong.service.request.enable_buffering()` and `kong.log.set_serialize_value()` in the access and log phases to add the request and response bodies to the log serializer, then enable a logging plugin (e.g. file-log) to capture them.
related_resources: []
---

## Overview

When using the standard Kong logging plugins, the request and response payloads are not logged. How can the payloads be added to the logging plugins output?

## Steps

The log content can easily be changed using the `kong.log.set_serialize_value` PDK functions.

The below example assumes that both the request and response bodies are JSON payloads. If this is not the case, then you may need to use the `get_raw_body` PDK functions.

We start by creating a service and an associated route

```bash
curl 'https://api.kong.lan:8444/default/services' \
-H 'Content-Type: application/json' \
-d '{
   "host":"httpbin.org",
   "connect_timeout":500,
   "protocol":"https",
   "name":"public-httpbin",
   "port":443,
   "path":"/anything",
   "retries":0
}'
```

```bash
curl 'https://api.kong.lan:8444/default/services/public-httpbin/routes' \
-H 'Content-Type: application/json' \
-d '{
    "paths": ["/httpbin"],
    "name": "public-httpbin"
}'
```

We then setup a pre-function plugin that adds the request and response payloads to the logging serializer, create the plugin as per the example below. Note, it is required to enable buffering for the service to ensure that Kong has the full payload content to log;

```bash
curl 'https://api.kong.lan:8444/default/routes/public-httpbin/plugins' \
-F 'name="pre-function"' \
-F 'config.access="kong.service.request.enable_buffering() kong.log.set_serialize_value(\"request.body\", kong.request.get_body())"' \
-F 'config.log="kong.log.set_serialize_value(\"response.body\", kong.service.response.get_body())"'
```

Then we add a file-log plugin

```bash
curl -H "kong-admin-token: password" -X POST 'http://localhost:8001/default/routes/public-httpbin/plugins/' \
--data name="file-log" \
--data config.path="/dev/stdout"
```

Sending a sample request with a JSON payload;

```bash
curl 'http://proxy.kong.lan:8000/httpbin' \
-H 'Content-Type: application/json' \
-d '{"abc":123}'
```

And the file log will contain an entry like this;

```json
{
    "service": {
        "port": 443,
        "created_at": 1716284577,
        "host": "httpbin.org",
        "write_timeout": 60000,
        "updated_at": 1716284577,
        "name": "Public-httpbin",
        "id": "d7b8c0d2-8d16-46f1-a1e4-85308e680aab",
        "ws_id": "bddec271-ce57-46d2-9bc0-25c5bb8d25e3",
        "protocol": "https",
        "connect_timeout": 500,
        "retries": 0,
        "read_timeout": 60000,
        "enabled": true,
        "path": "/anything"
    },
    "route": {
        "service": {
            "id": "d7b8c0d2-8d16-46f1-a1e4-85308e680aab"
        },
        "paths": [
            "/httpbin"
        ],
        "request_buffering": true,
        "response_buffering": true,
        "preserve_host": false,
        "https_redirect_status_code": 426,
        "regex_priority": 0,
        "ws_id": "bddec271-ce57-46d2-9bc0-25c5bb8d25e3",
        "created_at": 1716285246,
        "updated_at": 1716285246,
        "name": "Public-httpbin",
        "id": "1a7a1dd9-e2b9-47ef-81d2-5417a680af1c",
        "path_handling": "v0",
        "protocols": [
            "http",
            "https"
        ],
        "strip_path": true
    },
    "latencies": {
        "kong": 6,
        "request": 393,
        "proxy": 387
    },
    "request": {
        "headers": {
            "connection": "keep-alive",
            "content-length": "11",
            "host": "proxy.kong.lan:8000",
            "user-agent": "PostmanRuntime/7.39.0",
            "accept": "*/*",
            "content-type": "application/json",
            "accept-encoding": "gzip, deflate, br"
        },
        "url": "http://proxy.kong.lan:48000/httpbin",
        "querystring": {},
        "size": 224,
        "method": "POST",
        "uri": "/httpbin",
        "body": {
            "abc": 123
        }
    },
    "workspace": "bddec271-ce57-46d2-9bc0-25c5bb8d25e3",
    "client_ip": "192.168.224.12",
    "upstream_uri": "/anything",
    "tries": [
        {
            "ip": "54.160.164.209",
            "balancer_latency": 0,
            "port": 443,
            "balancer_start": 1716285593157
        }
    ],
    "response": {
        "status": 200,
        "size": 961,
        "headers": {
            "date": "Tue, 21 May 2024 09:59:53 GMT",
            "via": "kong/3.14.0.0-enterprise-edition",
            "x-kong-proxy-latency": "6",
            "content-type": "application/json",
            "server": "gunicorn/19.9.0",
            "connection": "close",
            "access-control-allow-origin": "*",
            "x-kong-upstream-latency": "387",
            "content-length": "638",
            "access-control-allow-credentials": "true"
        },
        "body": {
            "origin": "192.168.224.12, 138.201.126.179",
            "headers": {
                "X-Forwarded-Path": "/httpbin",
                "Accept-Encoding": "gzip, deflate, br",
                "X-Amzn-Trace-Id": "Root=1-664c7099-00ad85c23827e3ff2183b830",
                "Content-Type": "application/json",
                "X-Forwarded-Prefix": "/httpbin",
                "User-Agent": "PostmanRuntime/7.39.0",
                "Content-Length": "11",
                "Accept": "*/*",
                "X-Forwarded-Host": "proxy.kong.lan",
                "Host": "httpbin.org"
            },
            "url": "https://proxy.kong.lan/anything",
            "files": {},
            "data": "{\"abc\":123}",
            "form": {},
            "method": "POST",
            "args": {},
            "json": {
                "abc": 123
            }
        }
    },
    "started_at": 1716285593151
}
```

You can see this contains both the Request payload (`request.body`) and the Response payload (`response.body`).
