---
title: HTTP 413 "Configuration does not fit in LMDB database" error when posting a declarative configuration in DB-less mode
content_type: support
description: This error will occur when Kong is configured with an insufficient cache size to hold and process the new configuration.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "`lmdb_map_size` configuration reference"
    url: /gateway/configuration/#lmdb-map-size
tldr:
  q: Why do I get an HTTP 413 "Configuration does not fit in LMDB database" error when posting a declarative configuration to Kong in DB-less mode?
  a: |
    Kong's DB-less/hybrid config store (LMDB) has a fixed map size (`lmdb_map_size`, default `2048m`) that must be large enough to hold your declarative configuration. If your configuration exceeds that limit, raise `lmdb_map_size` in `kong.conf`, as an environment variable (`KONG_LMDB_MAP_SIZE`), or in your Helm values file.
---

## Problem

When attempting to post a new configuration in DB-less mode you receive the below error:

```bash
curl -X POST http://localhost:8001/config --form config=@"kong.yaml"

HTTP/1.1 413 Request Entity Too Large
Date: Thu, 27 Aug 2026 07:17:22 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
X-Kong-Admin-Request-ID: SdhfUn252BkqyAbmq3DmLjZYxdDS5oV0
Content-Length: 113
Server: kong/3.14.0.0-enterprise-edition

{"message":"Configuration does not fit in LMDB database, consider raising the \"lmdb_map_size\" config for Kong"}
```

The corresponding Kong Gateway error log entry reads:

```
[error] ... [kong] config.lua:180 not enough space for declarative config, client: <client-ip>, server: kong_admin, request: "POST /config HTTP/1.1", host: "<host>:8001"
```

## Cause

This error occurs when Kong's DB-less/hybrid configuration store (LMDB) is configured with an insufficient map size to hold and process the new declarative configuration.

## Solution

This is adjusted via the `lmdb_map_size` setting in `kong.conf`/environment variables/Helm values file, for example:

```conf
lmdb_map_size = 2048m
```

As an environment variable: `KONG_LMDB_MAP_SIZE=2048m`.

Note that `lmdb_map_size` now defaults to `2048m` (raised from earlier, much smaller defaults in older Kong versions), so a customer hitting this error today genuinely needs a very large declarative configuration to trigger it at the default setting; if it still occurs, raise `lmdb_map_size` further.
