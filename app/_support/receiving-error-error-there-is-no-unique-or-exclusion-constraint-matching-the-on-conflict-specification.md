---
title: "\"there is no unique or exclusion constraint matching the ON CONFLICT specification\" error when Kong's binary is newer than its applied migrations"
content_type: support
description: "This error means a running Kong node's `INSERT ... ON CONFLICT` statement doesn't match any unique index in the database, because the Kong binary is newer than the migrations actually applied."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Upgrade Kong Gateway
    url: /gateway/upgrade/
tldr:
  q: What does "there is no unique or exclusion constraint matching the ON CONFLICT specification" mean and how do I fix it?
  a: |
    This happens when the Kong Gateway binary is newer than the migrations applied to its database, so an `INSERT ... ON CONFLICT` statement references an index that doesn't exist yet. Run the pending migrations (`kong migrations up` then `kong migrations finish`) before starting the newer binary, or restore a database backup matching the older version instead.
---

## Problem

We are receiving the following error repeatedly throughout our Kong logs.

```

[error] 2035#0: *423 [lua] init.lua:49: flush_data(): error occurred during counters data flush: ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification, client: 12.123.123.124, server: kong_cluster_telemetry_listener
```

What does this error mean and how can we resolve it?

## Cause

The error means that a running Kong node issued an `INSERT ... ON CONFLICT (...)` statement whose conflict columns don't match any unique index that actually exists on the target table in the database. This happens whenever the Kong Gateway binary is newer than the migrations that have actually been applied to the database it's connected to, so a column or index the binary expects isn't there yet.

This is a general class of issue that can occur on any upgrade where migrations weren't fully applied before starting the newer binary, not just one specific version pair. For example, upgrading from Kong 2.6 to 2.7 without running the 2.7 migrations produces exactly this error, because the 2.7 migration adds new `year` and `month` columns (and a unique index built on them) to the `license_data` table that a database still on the 2.6 schema doesn't have. The same mechanism still applies on current Kong Gateway: the 3.12.0.0 migration changed that same table's unique index again (adding `license_creation_date` to it), so a 3.12.0.0-or-later binary connecting to a database that hasn't had that migration applied hits the identical class of error.

## Solution

To fix this:

- If you're not ready to complete the upgrade, restore a database backup that matches the Kong version you were previously running, and hold off starting the newer binary until you're ready to migrate.
- If you are proceeding with the upgrade, run the pending migrations to completion against the database (`kong migrations up`, followed by `kong migrations finish` once all nodes are upgraded) before starting the newer Kong binary against it, so the schema matches what that binary expects.

Reference: Upgrade Kong Gateway
