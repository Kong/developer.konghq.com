---
title: "Kong Gateway: `kong vault get` fails when using GCP Workload Identity"
content_type: support
description: "Retrieving a GCP secret with `kong vault get` over Workload Identity can fail with an `invalid access token` error when resty CLI's default 64 `worker_connections` limit is exceeded during token retrieval."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does `kong vault get` fail with an invalid access token error when using GCP Workload Identity?
  a: |
    The failure is usually an invalid or expired GCP access token, though it can also stem from resty CLI's default 64 `worker_connections` limit being exceeded during token retrieval. If you hit a `worker_connections are not enough` error, work around it by running resty CLI with a higher connection limit, e.g. `resty -c 128 /usr/local/bin/kong vault get ...`.
---

## Problem

When we try to retrieve a secret from GCP Secrets Manager using `kong vault get` via Workload Identity, we receive the following error:

```

2023/08/03 15:48:56 [verbose] Kong: 3.14.0.0-enterprise-edition
2023/08/03 15:48:56 [verbose] prefix in use: /kong_prefix
2023/08/03 15:48:56 [verbose] reading config file at /kong_prefix/.kong_env
2023/08/03 15:48:56 [verbose] prefix in use: /kong_prefix
2023/08/03 15:48:57 [alert] 251#0: *7 64 worker_connections are not enough, context: ngx.timer
2023/08/03 15:48:57 [alert] 251#0: *11 64 worker_connections are not enough, context: ngx.timer
2023/08/03 15:48:57 [alert] 251#0: *2 64 worker_connections are not enough, context: ngx.timer
Error:
/usr/local/share/lua/5.1/kong/cmd/vault.lua:88: unable to load value (secrets/pizza/versions) from vault (gcp): invalid access token (invalid credentials) [{vault://gcp/secrets/pizza/versions/1}]
stack traceback:
[C]: in function 'get'
/usr/local/share/lua/5.1/kong/cmd/vault.lua:88: in function 'cmd_exec'
/usr/local/share/lua/5.1/kong/cmd/init.lua:97: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:97>
[C]: in function 'xpcall'
/usr/local/share/lua/5.1/kong/cmd/init.lua:97: in function </usr/local/share/lua/5.1/kong/cmd/init.lua:54>
/usr/local/bin/kong:9: in function 'file_gen'
init_worker_by_lua:49: in function <init_worker_by_lua:47>
[C]: in function 'xpcall'
init_worker_by_lua:56: in function <init_worker_by_lua:54>
```

The underlying cause (an invalid/expired GCP access token, or another vault-backend error) is reported through the `kong vault get` CLI's error wrapper message, `"could not get value from external vault (<underlying error>)"` (`kong/pdk/vault.lua`); the exact wording shown above may differ slightly depending on the specific vault backend and error encountered.

## Cause

This error occurs because we utilize resty CLI which has a worker connection limit of 64 by default. The retrieval of the secret is seemingly using more than 64 connections and thus the token retrieval process breaks down.

## Solution

Kong Gateway's Lua-timer subsystem (`lua-resty-timer-ng`) uses a bounded concurrency range designed to avoid exhausting the available `worker_connections`, so this specific failure mode is uncommon. If you still encounter a `worker_connections are not enough` error during `kong vault get`, use the workaround below.

Current workaround:

Allow resty CLI to utilize more connections (this will double the maximum to 128 connections):

```bash
/usr/local/bin/resty -c 128 /usr/local/bin/kong vault get {vault://gcp/secrets/pizza/versions/1}
```
