---
title: "Access, Admin Access & Error logs continue to write to `stdout`/`stderr` when specifying an override"
content_type: support
description: Access, admin access, and error logs keep writing to `stdout`/`stderr` because Kong's `docker-entrypoint` script symlinks the default log paths there; changing the path or filename fixes it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do my access and error logs keep writing to `stdout`/`stderr` even after I set `KONG_PROXY_ACCESS_LOG` and `KONG_PROXY_ERROR_LOG` to a different path?
  a: |
    Kong's docker-entrypoint script symlinks the default log file paths (`access.log`, `admin_access.log`, `error.log`) to `/dev/stdout` and `/dev/stderr`. Setting `KONG_PROXY_ACCESS_LOG` and `KONG_PROXY_ERROR_LOG` has no effect if you leave the path and filename at their defaults — the symlinks still win. Point the variables at a different path or filename to actually redirect logging inside the container.
related_resources:
  - text: "Kong Gateway configuration reference: `proxy_access_log`"
    url: /gateway/configuration/#proxy-access-log
  - text: Kong's `docker-entrypoint.sh` script
    url: https://github.com/Kong/docker-kong/blob/master/docker-entrypoint.sh
---

## Problem

When attempting to override the admin access, access & error log location/file names on a docker image you notice the logs are still being redirected to `stdout` and `stderr`. For example, you have set the below variables to use a path inside the container:

`KONG_PROXY_ACCESS_LOG=/usr/local/kong/logs/access.log`

`KONG_PROXY_ERROR_LOG=/usr/local/kong/logs/error.log`

```bash

docker exec kong ls -lart /usr/local/kong/logs
lrwxrwxrwx    1 kong     nogroup         11 Nov 29 15:05 error.log -> /dev/stderr
lrwxrwxrwx    1 kong     nogroup         11 Nov 29 15:05 access.log -> /dev/stdout
```

```bash

docker exec kong printenv | grep KONG_PROXY
KONG_PROXY_ACCESS_LOG=/usr/local/kong/logs/access.log
KONG_PROXY_ERROR_LOG=/usr/local/kong/logs/error.log
```

Why are the logs not being written in the container?

## Cause

This will occur when you are using the default path and file names for the logs. Despite explicitly setting the variables, the values have not changed from their defaults. As seen in our `docker-entrypoint`, we explicitly define a symlink for the below logs:

```bash

ln -sf /dev/stdout $PREFIX/logs/access.log
ln -sf /dev/stdout $PREFIX/logs/admin_access.log
ln -sf /dev/stderr $PREFIX/logs/error.log
```

## Solution

If you wish to redirect logging inside the container you will need to change the path and/or the filename for the logs.

i.e.

`KONG_PROXY_ACCESS_LOG=/usr/local/kong/logs/gruber_access.log`

`KONG_PROXY_ERROR_LOG=/usr/local/kong/logs/gruber_error.log`

```bash

docker exec kong ls -lart /usr/local/kong/logs
-rw-r--r--    1 kong     nogroup       2024 Nov 29 15:10 gruber_access.log
-rw-r--r--    1 kong     nogroup      77233 Nov 29 15:11 gruber_error.log
```

Note: Redirecting logs inside the container can be problematic and is not advised. If the container crashes the logs will be inaccessible.
