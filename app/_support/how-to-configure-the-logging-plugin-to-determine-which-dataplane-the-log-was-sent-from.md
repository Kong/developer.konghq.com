---
title: How to configure the logging plugin to determine which DataPlane the log was sent from
content_type: support
description: "Add `custom_fields_by_lua` entries that call `kong.node.get_id()` and `kong.node.get_hostname()` to a logging plugin config so each log entry shows which data plane sent it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure a logging plugin to show which DataPlane sent each log entry?
  a: |
    Add `custom_fields_by_lua` entries to the logging plugin config that call `kong.node.get_id()` and `kong.node.get_hostname()`. This writes the data plane's node ID and hostname into each log entry.
related_resources:
  - text: "`kong.node.get_id()`"
    url: /gateway/pdk/reference/kong.node/#kong-node-get-id
  - text: "`kong.node.get_hostname()`"
    url: /gateway/pdk/reference/kong.node/#kong-node-get-hostname
---

## Overview

Is there a way to configure the logging plugins to determine which DataPlane was the log sent from?

## Steps

The log plugins offer the ability to add `custom_fields_by_lua` to the generated logs.

To determine which DataPlane sent the logs, the following two fields can be added to the logs:

- `kong.node.get_id()`
- `kong.node.get_hostname()`

The example below uses the File log for simplicity.

Here's the json config:

```json
{
  "id": "5e2e3383-3873-43e9-9449-35c461dec755",
  "consumer": null,
  "enabled": true,
  "service": null,
  "tags": null,
  "created_at": 1681385908,
  "ordering": null,
  "name": "file-log",
  "route": null,
  "protocols": [
    "grpc",
    "grpcs",
    "http",
    "https"
  ],
  "config": {
    "custom_fields_by_lua": {
      "logged-hostname": "return kong.node.get_hostname(),nil",
      "logged-node-id": "return kong.node.get_id(),nil"
    },
    "path": "/dev/stdout",
    "reopen": false
  }
}
```

The above config produces this log

```json
{
  "tries": [
    {
      "balancer_start": 1681386275454,
      "ip": "172.24.0.2",
      "balancer_latency": 0,
      "port": 8080
    }
  ],
  "request": {
    "size": 111,
    "headers": {
      "user-agent": "curl/7.86.0",
      "accept": "*/*",
      "x-forwarded-for": "172.24.0.1",
      "host": "proxy.kong.lan"
    },
    "url": "http://proxy.kong.lan:48000/echo",
    "querystring": {},
    "method": "GET",
    "uri": "/echo"
  },
  "latencies": {
    "kong": 0,
    "request": 1,
    "proxy": 1
  },
  "logged-hostname": "b51525ede933",
  "logged-node-id": "b70097dc-6598-40dd-bd1b-31b3fcb7841e",
  "service": {
    "id": "e399a95c-5a02-4594-814e-8d364167903e",
    "protocol": "http",
    "created_at": 1681294138,
    "ws_id": "ca2580e6-4d67-461a-9c01-e0f76d5832b6",
    "write_timeout": 60000,
    "host": "echo-server",
    "name": "local-echo-server",
    "retries": 5,
    "updated_at": 1681294138,
    "connect_timeout": 60000,
    "enabled": true,
    "read_timeout": 60000,
    "port": 8080
  },
  "started_at": 1681386275454,
  "workspace": "ca2580e6-4d67-461a-9c01-e0f76d5832b6",
  "client_ip": "172.24.0.1",
  "upstream_uri": "/",
  "response": {
    "headers": {
      "via": "kong/3.14.0.0-enterprise-edition",
      "x-kong-proxy-latency": "0",
      "date": "Thu, 13 Apr 2023 11:44:35 GMT",
      "connection": "close",
      "x-kong-upstream-latency": "1",
      "content-type": "text/plain; charset=UTF-8",
      "content-length": "323"
    },
    "size": 556,
    "status": 200
  },
  "route": {
    "id": "f491db3f-7018-4197-ae6e-42f69202d6e1",
    "created_at": 1681294138,
    "paths": [
      "/echo"
    ],
    "ws_id": "ca2580e6-4d67-461a-9c01-e0f76d5832b6",
    "request_buffering": true,
    "response_buffering": true,
    "regex_priority": 0,
    "name": "echo",
    "preserve_host": false,
    "path_handling": "v0",
    "updated_at": 1681294138,
    "https_redirect_status_code": 426,
    "protocols": [
      "http",
      "https"
    ],
    "service": {
      "id": "e399a95c-5a02-4594-814e-8d364167903e"
    },
    "strip_path": true
  }
}
```

Note the new fields that were added

```json
"logged-hostname": "b51525ede933",
"logged-node-id": "b70097dc-6598-40dd-bd1b-31b3fcb7841e",
```
