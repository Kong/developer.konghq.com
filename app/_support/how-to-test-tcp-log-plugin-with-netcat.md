---
title: How to test `tcp-log` plugin with netcat
content_type: support
description: Configure the `tcp-log` plugin to send logs to a local netcat listener, and confirm the logs arrive as valid JSON.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I test the `tcp-log` plugin using netcat?
  a: |
    Run `nc -l 8080` (optionally piped to `jq .` for readable output) in one terminal, point the `tcp-log` plugin's config at `localhost:8080`, then send a request through the route. The log entry Kong sends appears as JSON in the netcat output.
---

## Overview

How do I test the `tcp-log` plugin with netcat?

## Steps

Set up netcat to listen on port 8080 in a separate terminal:

```bash
nc -l 8080
```

To make the output easier to read, use jq:

```bash
nc -l 8080 | jq .
```

Configure your `tcp-log` plugin to use your localhost on port 8080.

Hit your route in a separate terminal:

```bash
http :8000/loop
```

Watch the output of netcat:

```
nc -l 8080 | jq .

{
  "workspace": "21b9e471-4bbf-46d9-b777-7262a4d54929",
  "route": {
    "https_redirect_status_code": 426,
    "request_buffering": true,
    "response_buffering": true,
    "updated_at": 1636696445,
    "preserve_host": false,
    "ws_id": "21b9e471-4bbf-46d9-b777-7262a4d54929",
    "protocols": [
      "http"
    ],
    "created_at": 1636696445,
    "name": "ext-bin-route",
    "strip_path": true,
    "service": {
      "id": "c93ad723-1720-4c8f-a220-cd5f157df049"
    },
    "regex_priority": 0,
    "path_handling": "v0",
    "id": "bdd495e8-0379-42f5-86ec-c233e471beac",
    "paths": [
      "/bin",
      "/loop"
    ]
  },
  "response": {
    "status": 200,
    "size": 828,
    "headers": {
      "content-length": "504",
      "via": "kong/3.14.0.0-enterprise-edition",
      "access-control-allow-origin": "*",
      "access-control-allow-credentials": "true",
      "content-type": "application/json",
      "x-kong-upstream-latency": "963",
      "server": "gunicorn/19.9.0",
      "date": "Fri, 12 Nov 2026 06:06:36 GMT",
      "connection": "close",
      "x-kong-proxy-latency": "33"
    }
  },
  "tries": [
    {
      "ip": "54.156.165.4",
      "balancer_latency": 0,
      "port": 443,
      "balancer_start": 1636697195334
    }
  ],
  "request": {
    "uri": "/loop",
    "size": 139,
    "querystring": {},
    "method": "GET",
    "headers": {
      "host": "localhost:8000",
      "accept-encoding": "gzip, deflate",
      "user-agent": "HTTPie/2.4.0",
      "connection": "keep-alive",
      "accept": "*/*"
    },
    "url": "http://localhost:8000/loop"
  },
  "service": {
    "created_at": 1636696445,
    "host": "httpbin.org",
    "updated_at": 1636696445,
    "name": "httpbin",
    "write_timeout": 60000,
    "path": "/anything",
    "ws_id": "21b9e471-4bbf-46d9-b777-7262a4d54929",
    "read_timeout": 60000,
    "protocol": "https",
    "retries": 5,
    "id": "c93ad723-1720-4c8f-a220-cd5f157df049",
    "port": 443,
    "connect_timeout": 60000
  },
  "started_at": 1636697195301,
  "client_ip": "172.18.0.1",
  "upstream_uri": "/anything",
  "latencies": {
    "proxy": 963,
    "kong": 35,
    "request": 998
  }
}
```
