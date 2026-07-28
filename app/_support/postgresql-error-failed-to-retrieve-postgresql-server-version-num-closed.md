---
title: "\"[PostgreSQL error] failed to retrieve PostgreSQL server_version_num: closed\" error caused by a TLS version mismatch with the database server"
content_type: support
description: "How to resolve the `failed to retrieve PostgreSQL server_version_num: closed` error, which is usually caused by a TLS version mismatch between Kong and the database."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: pg_ssl_version configuration reference
    url: /gateway/configuration/
tldr:
  q: Why does Kong fail to start with a "[PostgreSQL error] failed to retrieve PostgreSQL server_version_num: closed" error?
  a: |
    This error is usually caused by a TLS version mismatch between Kong and the Postgres server. If the database uses TLS 1.2 or TLS 1.3, set `KONG_PG_SSL_VERSION` (`tlsv1_2` or `tlsv1_3`) and restart Kong.
---

## Problem

You might encounter a situation where the Kong pod gets stuck and keeps restarting.

The log of the Kong pod shows the below information.

```
nginx: [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:533: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: closed
stack traceback:
	[C]: in function 'assert'
	/usr/local/share/lua/5.1/kong/init.lua:533: in function 'init'
	init_by_lua:3: in main chunk
```

This error might come from the TLS version mismatch with your DB server.

## Solution

If the DB server uses TLS 1.2 or TLS 1.3, please add the below parameter to your Kong env, and then restart Kong.

```
KONG_PG_SSL_VERSION= tlsv1_2 for TLS1.2 / tlsv1_3 for TLS 1.3
```

For details about this parameter, see the `pg_ssl_version` configuration reference.
