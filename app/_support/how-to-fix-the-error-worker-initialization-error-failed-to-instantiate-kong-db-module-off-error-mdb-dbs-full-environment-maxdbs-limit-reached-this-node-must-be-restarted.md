---
title: "\"MDB_DBS_FULL: Environment maxdbs limit reached\" worker initialization error when upgrading to Kong Gateway 3.10.0.2 with a custom Nginx template"
content_type: support
description: "How to fix the `worker initialization error: failed to instantiate 'kong.db' module: [off error] MDB_DBS_FULL: Environment maxdbs limit reached` error when Kong Gateway 3.10.0.2 fails to start with a custom Nginx template missing the `lmdb_max_databases` directive."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does Kong Gateway 3.10.0.2 fail to start with a \"MDB_DBS_FULL: Environment maxdbs limit reached\" worker initialization error after upgrading with a custom Nginx template?"
  a: |
    Kong Gateway 3.10.0.2 introduced a new requirement to set `lmdb_max_databases` for the incremental sync process's full sync pagination. A custom Nginx template that's missing the stock `include 'nginx-inject.conf';` line never gets this setting, so LMDB's max-databases limit is exceeded at worker init. Confirm your custom template still includes that file; only if it genuinely can't should you add `lmdb_max_databases 3;` (with `lmdb_environment_path` and `lmdb_map_size`) directly — the value `3` is hardcoded and must not be changed.
---

## Problem

Kong Gateway v3.10.0.2 fails to start after upgrading from a lower version when using a custom Nginx template, producing the following error:

2025/06/16 06:46:31 [crit] 76#0: *1 [lua] init.lua:999: init_worker(): worker initialization error: failed to instantiate 'kong.db' module: [off error] MDB_DBS_FULL: Environment maxdbs limit reached; this node must be restarted, context: init_worker_by_lua*

## Cause

The issue you're encountering with Kong Gateway v3.10.0.2 not starting up after an upgrade from any of the lower versions, accompanied by the error message "failed to instantiate 'kong.db' module: [off error] MDB_DBS_FULL: Environment maxdbs limit reached," is related to the `lmdb_max_databases` configuration. This problem arises due to a new configuration requirement introduced in Kong Gateway version 3.10.0.2, which necessitates setting the `lmdb_max_databases` to a specific value to support the "full sync pagination" in the incremental sync process. This error is specifically caused by a custom nginx template that is missing the `include 'nginx-inject.conf';` line that stock Kong templates carry.

## Solution

To resolve this issue, you need to add the `lmdb_max_databases 3;` directive in your custom nginx template. This setting is mandatory and supports the incremental sync process by using two databases for seamlessly swapping entity configurations, and one database serves as a pointer to the current active database. The value of 3 is hardcoded and should not be changed.

Here is how you can add the `lmdb_max_databases` directive to your custom nginx template:

```nginx
lmdb_environment_path dbless.lmdb;
lmdb_map_size 3072m;
lmdb_max_databases 3;
```

Ensure that your nginx configuration includes these lines to properly configure the LMDB environment for Kong Gateway v3.10.0.2 in DBLESS mode.

That auto-generated file (compiled from `kong/templates/nginx_inject.lua`) already declares `lmdb_environment_path`, `lmdb_map_size`, and `lmdb_max_databases 3;` for you, so the simplest and most robust fix — for any current Kong Gateway version, not just 3.10.0.2 — is to confirm your custom template still contains that `include` line, rather than hand-copying the LMDB directives shown above. Only add the directives manually if your custom template genuinely does not (and cannot) include that file. If you do add them manually, use only `lmdb_environment_path`, `lmdb_map_size`, and `lmdb_max_databases` as shown above — do not add `lmdb_encryption_key`/`lmdb_encryption_mode` directives from older LMDB-configuration guidance, as these are no longer valid nginx directives on current Kong Gateway versions and will prevent Kong from starting at all (`nginx: [emerg] unknown directive "lmdb_encryption_key"`).
