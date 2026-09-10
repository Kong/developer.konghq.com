---
title: "{{site.base_gateway}}: Graceful Shutdown of Kong in ECS not working"
content_type: support
description: "Kong's master process runs as PID 1 in ECS tasks, so ECS sends SIGTERM directly to it instead of honoring the container's `STOPSIGNAL`, causing in-flight requests to fail. Using an init process such as `dumb-init` enables a graceful shutdown."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: dumb-init
    url: https://github.com/Yelp/dumb-init
tldr:
  q: Why doesn't {{site.base_gateway}} shut down gracefully when ECS scales down a task?
  a: |
    In ECS, Kong's master process runs as `PID 1`, so ECS sends `SIGTERM` directly to it instead of honoring the container's `STOPSIGNAL`, causing in-flight requests to fail. Running Kong under an init process such as `dumb-init` moves the master process off `PID 1` and lets you translate the incoming `SIGTERM` into a `SIGQUIT` for a graceful shutdown.
---

## Problem

When running our Kong in ECS, when tasks scale down we see that Kong is not shutting down gracefully and thus in-flight requests are failing. Based on further investigating we see that ECS appears to not be honoring the `STOPSIGNAL` defined in the docker entrypoint.

## Solution

It is a known limitation of ECS that it does not honor `STOPSIGNAL` definitions.

The primary issue is that Kong's master process is running as `PID 1` in the container. When ECS attempts to stop/scale down a task, it sends a `SIGTERM` signal directly to the Kong master process and thus Kong shuts down immediately.

To remedy the situation, you need the Kong master process to NOT be running as `PID 1`. To achieve this, you need to use a tool such as `dumb-init`. This tool will replace `PID 1` with a 'dummy' process thus moving the Kong master process to some other PID.

From here on out, our dummy process will receive the `SIGTERM` from ECS and, with a change to our `ENTRYPOINT`, we will forward a `SIGQUIT` to the Kong master process allowing for a graceful shutdown:

```dockerfile

ENTRYPOINT ["/usr/local/bin/dumb-init", "--rewrite", "15:3", "--"]
```

Below is a sample dockerfile for a Kong image that includes dumb-init:

```dockerfile

# load kong-ubuntu:latest
FROM kong/kong-gateway:latest-ubuntu

USER root

# add dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

COPY tini-wrapper.sh /tini-wrapper.sh

USER kong

# set tini as entrypoint
ENTRYPOINT ["/usr/local/bin/dumb-init", "--rewrite", "15:3", "--"]

CMD ["/tini-wrapper.sh"]
```

And the corresponding tini-wrapper.sh:

```bash

#!/usr/bin/env bash
set -Eeo pipefail

# translate SIGTERM to SIGQUIT for graceful shutdown
graceful_shutdown() {
    echo "SIGTERM received, sending SIGQUIT to Kong..."
    # get PID of Kong's master process
    local kong_pid=$(pgrep -f "/usr/local/openresty/nginx/sbin/nginx")
    # send SIGQUIT to master and all workers
    kill -SIGQUIT "$kong_pid"
}

trap 'graceful_shutdown' SIGTERM

exec /entrypoint.sh kong docker-start
```

Attached (tini-warp.zip) is a full example of how you might achieve this
