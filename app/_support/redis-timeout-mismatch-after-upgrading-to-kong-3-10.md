---
title: Redis timeout mismatch after upgrading to Kong 3.10.0.0
content_type: support
description: After upgrading to Kong 3.10.0.0, Kong may fail to start with a Redis `timeout`/`connect_timeout` schema violation error; removing the deprecated `timeout` field from the plugin's config resolves it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does Kong fail to start after upgrading to 3.10.0.0 with a Redis `timeout`/`connect_timeout` schema violation error?
  a: |
    Kong 3.10 validates that the deprecated `timeout` Redis field and the new `connect_timeout` field agree when both are set in a plugin's config; a mismatch blocks startup. Remove the deprecated `timeout` key from the affected plugin's config (for example `rate-limiting-advanced`) directly in the database after taking a backup.
---

## Problem

After running and finishing the migrations to Kong 3.10.0.0, the following error is logged and Kong doesn't start:

`nginx: [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:824: error building initial plugins: [postgres] schema violation (timeout: both deprecated and new field are used but their values mismatch: timeout = 2000 vs connect_timeout = 1000)`

## Cause

Upon upgrading to Kong 3.10.0.0, you may encounter an error during startup related to a conflict between deprecated and new Redis timeout parameters. This issue arises when both the deprecated `timeout` field and the new `connect_timeout` field are present in the plugin configuration, and their values do not match.

## Solution

To resolve this issue, you need to remove the deprecated `timeout` field from the plugin configuration in the database. The following SQL query can be safely executed to remove the `timeout` field for the `rate-limiting-advanced` plugin:

```sql
UPDATE plugins
SET config = config::jsonb #- '{redis,timeout}'
WHERE name = 'rate-limiting-advanced';
```

Before running this query, ensure you have a backup of your database to prevent any accidental data loss. This query specifically targets the `rate-limiting-advanced` plugin configuration, removing the `timeout` field from the Redis configuration stored in the `config` column of the `plugins` table, which is of type `jsonb`.

This solution was confirmed to resolve the issue, allowing Kong to start without errors related to the Redis timeout configuration.
