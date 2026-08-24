---
title: "How to fake down `/status` endpoint"
content_type: support
description: "Simulate the `/status` endpoint going down on a standalone Kong node by looping it back through an upstream and marking the target unhealthy via the Admin API."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I temporarily disable or fake down the `/status` endpoint on a standalone Kong node?
  a: |
    On a standalone/traditional Kong node, loop the `/status` endpoint back through an upstream and mark its target unhealthy via the Admin API (`PUT /upstreams/{id}/targets/{id}/unhealthy`) so `/status` returns `503`; mark it healthy again to restore it. This doesn't work against a hybrid Control Plane's Admin API, which returns `404` for that endpoint.
---

## Overview

We currently have an  LB doing health checks for the `/status` endpoint at every nth second interval. If we want to do an upgrade to the Kong node, we will take down the Admin API but we don’t want the LB to route the request when the node is down during the interval gap. Is there any way we can turn off the `/status` endpoint?

## Steps

`/status` endpoint can be controlled by `status_listen` configuration in `kong.conf`.

To turn it off, you need to restart kong but in case a restart is not possible, you can loopback the `/status` endpoint in Kong and use `Mark Healthy/Unhealthy` to turn it off/on using Kong upstream health check.

This technique applies to standalone/traditional Kong nodes only. On a hybrid-mode Admin API, `PUT /upstreams/{id}/targets/{id}/unhealthy` returns `404`, so this approach does not work against a hybrid Control Plane's Admin API.

On a standalone node, note that the health checker is "lazy": the first health-check-related request against a freshly created upstream/target can return `400` until a request has actually been proxied through it at least once. Send one warm-up request through the upstream before marking targets healthy/unhealthy; after that, the endpoint behaves as described below.

Here are the steps to set it up:

1. Create an upstream for loopbacking the admin API

```bash

http :8001/upstreams name=status_check -f
```

2. Set Admin API host as the target for the upstream `status_check`

```bash

http :8001/upstreams/status_check/targets target=<KongAdminAPI hostname>:8001 -f
```

3. Create a service with path `/status` and a route for the upstream

```bash

http :8001/services name=status_health host=status_check path=/status -f 
http :8001/services/status_health/routes name=status_route paths=/status -f
```

4. Right now we have Kong serving `/status` at the proxy port

```bash

http :8000/status
HTTP/1.1 200 OK

{
    "database": {
        "reachable": true
    },
    "memory": {
        "lua_shared_dicts": {
            "kong": {
                "allocated_slabs": "0.04 MiB",
                "capacity": "5.00 MiB"
            },
            "kong_healthchecks": {
                "allocated_slabs": "0.04 MiB",
                "capacity": "5.00 MiB"
            },
            ...
        },
        "workers_lua_vms": [
            {
                "http_allocated_gc": "182.51 MiB",
                "pid": 2914
            },
            ...
        ]
    },
    "server": {
        "connections_accepted": 137,
        "connections_active": 7,
        "connections_handled": 137,
        "connections_reading": 0,
        "connections_waiting": 0,
        "connections_writing": 7,
        "total_requests": 137
    }
}
```

5. Mark the target unhealthy to fake the `/status` endpoint down

```bash

# the template  
# :8001/upstreams/<upstream_id>/targets/<targets-id>/[healthy/unhealthy]

http :8001/upstreams/f3fa8cc2-003a-49fe-8734-c3f433281a46/targets/7355da4e-6684-4d3d-9890-863e2e444510/unhealthy
HTTP/1.1 204 No Content 
Access-Control-Allow-Origin: * 
Connection: keep-alive
```

6.  Try to curl the `status` endpoint again

```bash

http :8000/status                                                                                                                                                                                                                                        
HTTP/1.1 503 Service Temporarily Unavailable
Connection: keep-alive
Content-Length: 58
```

You can see the endpoint returns 503 as it is currently unhealthy as an upstream. To set it healthy, use the endpoint in step 5.

```bash

http :8001/upstreams/f3fa8cc2-003a-49fe-8734-c3f433281a46/targets/7355da4e-6684-4d3d-9890-863e2e444510/healthy
HTTP/1.1 204 No Content 
Access-Control-Allow-Origin: * 
Connection: keep-alive

http :8000/status 
HTTP/1.1 200 OK
```
