---
title: How to customize Kong access logs
content_type: support
description: Explains how to write a custom Nginx template with a `map` block so Kong's access log skips 2xx and 3xx requests.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I customize Kong's access logs to skip 2xx and 3xx requests?
  a: |
    Write a custom Nginx template based on Kong's default one, adding an nginx `map` block (`map $status $loggable { ~^[23] 0; default 1; }`) and setting `proxy_access_log` to use `if=$loggable`. Start Kong with `--nginx-conf` pointing at the custom template, escaping the `$` as `$$` or `\$` when it's set via an environment variable, so only non-2xx/3xx requests are logged.
related_resources: []
---

## Overview

How can I customize Kong access log, for example not logging 2xx and 3xx requests?

## Steps

To customize Kong access logs, basically you need to write a custom Nginx template and use the `map` module to remove the 2xx and 3xx requests. For the template, take as model the file `/usr/local/kong/kong.conf` and add the map:

```nginx
pid pids/nginx.pid;
error_log /dev/stderr notice;
# injected nginx_main_* directives
daemon off;
worker_processes auto;
worker_rlimit_nofile 16384;
env KONG_LICENSE_DATA;
env KONG_LICENSE_PATH;
include 'nginx-inject.conf';

events {
    # injected nginx_events_* directives
    multi_accept on;
    worker_connections 16384;
}

http {
    map $status $loggable {
        ~^[23]  0;
        default 1;
    }
    include 'nginx-kong.conf';
}
```

This file needs to be located in the `/usr/local/kong/` directory as references `/usr/local/kong/nginx-kong.conf`

Then you need to start Kong to use this config:

```bash
kong start --nginx-conf /usr/local/kong/custom-nginx.conf
```

And configure `proxy_access_log` as below:

```
proxy_access_log = /dev/stdout combined if=$loggable
```

If using environment variables you may need to escape the `$` character:

```
KONG_PROXY_ACCESS_LOG: "/dev/stdout combined if=$$loggable"
```

If running docker from the terminal directly, you also need to escape the `$` character as `\$`:

```bash
docker run --network bridge -d --name kong-dbless \
  -v $(pwd)/custom_nginx.conf:/usr/local/kong/custom-nginx.conf \
  -v "$(pwd)/declarative:/kong/declarative/" \
  -v "$(pwd)/tmp_volume:/tmp" \
  -v "$(pwd)/prefix_volume:/var/run/kong" \
  -e "KONG_PREFIX=/var/run/kong" \
  -e "KONG_DATABASE=off" \
  -e "KONG_DECLARATIVE_CONFIG=/kong/declarative/kong3.yaml" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_PROXY_LISTEN=0.0.0.0:8000" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout combined if=\$loggable" \
  -e "KONG_LICENSE_DATA=$KONG_LICENSE_DATA" \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -p 8002:8002 \
  -p 8445:8445 \
  -p 8003:8003 \
  -p 8004:8004 \
  kong/kong-gateway \
  kong start --nginx-conf /usr/local/kong/custom-nginx.conf
```

### Additional information

- Kong docs: How to Customize Gateway Logs
- Nginx docs: Configuring Logging - Enabling Conditional Logging
