---
title: After setting pg_max_concurrent_queries, the number of database connections still exceeds the maximum allowed
content_type: support
description: How to limit the total number of PostgreSQL database connections when running Kong Gateway on multiple nodes in Kubernetes.
products:
  - gateway

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Kong Gateway configuration reference - pg_max_concurrent_queries
    url: /gateway/configuration/#postgres-settings
  - text: Kong Gateway configuration reference - nginx_worker_processes
    url: /gateway/configuration/#nginx-worker-processes

tldr:
  q: Why does my PostgreSQL connection count exceed the limit I set with pg_max_concurrent_queries?
  a: |
    `pg_max_concurrent_queries` is applied **per nginx worker process**, so the actual maximum
    number of concurrent database connections is:

    ```
    pg_max_concurrent_queries × nginx_worker_processes × number of Kong nodes
    ```

    To bring the total under your database connection limit, explicitly set
    `nginx_worker_processes` to a fixed integer value rather than relying on the
    default `auto` setting, which bases the count on the host's vCPUs and can
    produce more workers than expected in Kubernetes.

---

## Problem

The PostgreSQL database used by {{site.base_gateway}} has a maximum number of permitted
connections. After setting `pg_max_concurrent_queries` to a value below that maximum,
the connection limit is still exceeded. {{site.base_gateway}} is running on multiple
nodes deployed in Kubernetes.

## Cause

The `pg_max_concurrent_queries` setting is scoped **per nginx worker process**, not
per Kong node. The actual maximum number of concurrent database connections is therefore:

```
pg_max_concurrent_queries × nginx_worker_processes × number of Kong nodes
```

The `nginx_worker_processes` parameter defaults to `auto`, which sets the number of
worker processes equal to the number of available vCPUs. In a Kubernetes environment,
the calculation is based on the **host** vCPUs (not the container's CPU limit), which
can result in significantly more workers — and therefore more database connections —
than expected.

## Solution

1. Determine the current number of nginx worker processes on a running Kong node:

   ```bash
   ps aux | grep "[n]ginx: worker process" | wc -l
   ```

2. Calculate the maximum connection count you need to stay within your database limit.
   For example, if your database allows 200 connections, you have 4 Kong nodes, and
   you want `pg_max_concurrent_queries` set to 10:

   ```
   200 connections ÷ (4 nodes × 10 queries) = 5 worker processes per node
   ```

3. Explicitly set `nginx_worker_processes` to a fixed integer in `kong.conf`:

   ```
   nginx_worker_processes = 5
   ```

   Or via an environment variable:

   ```bash
   KONG_NGINX_WORKER_PROCESSES=5
   ```

4. Reload or restart {{site.base_gateway}} for the change to take effect:

   ```bash
   kong reload
   ```

5. Verify the worker count reflects the new value:

   ```bash
   ps aux | grep "[n]ginx: worker process" | wc -l
   ```

## Validation

After restarting, confirm the total connection count stays within bounds by monitoring
your database connection metrics. For PostgreSQL, you can check active connections with:

```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = '<your_kong_database>';
```

The count should remain at or below:

```
pg_max_concurrent_queries × nginx_worker_processes × number of Kong nodes
```
