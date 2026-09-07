---
title: How TCP Active Healtchecks Work
content_type: support
description: TCP active health checks run in Kong's stream subsystem, so they behave differently across HTTP and TCP services and can't reliably report health for HTTP services.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do TCP Active Healtchecks work?
  a: |
    TCP active health checks run in Nginx's stream subsystem, which doesn't share health state with the HTTP subsystem. As a result, they report status correctly for TCP services but not for HTTP services, and can even cause the load balancer to route to an unhealthy HTTP target. Use HTTP active health checks, not TCP, when monitoring HTTP services.
related_resources:
  - text: Health checks and circuit breakers
    url: /gateway/traffic-control/health-checks-circuit-breakers/#active-health-checks
---

## Overview

Active health checks actively probe targets for their health. When active health checks are enabled in an upstream entity, Kong will periodically issue HTTP or HTTPS requests to a configured path at each target of the upstream. Active health checks currently only support HTTP/HTTPS targets — see Health checks and circuit breakers for more details. But in Kong Manager we can still configure to use TCP Active Healthchecks. Once we enable them we see different information reported in Kong logs and in the AdminAPI (`/upstreams/<upstream_id>/health`) endpoint.

## Steps

This is how active Health Checks work:

- HTTP Active HealthChecks work with HTTP services. Admin API reports health correctly.
- TCP  Active HealthChecks work with TCP  services. Admin API does not report health correctly.
- TCP  Active HealthChecks do not work with HTTP services. Admin API does not report health correctly.

TCP Active HealtchCheks will only be sent to targets if the Stream subsystem is enabled, by setting Kong `stream_listen` in Kong configuration.

Let's see the logs. An upstream with 2 targets, one healthy (192.168.80.2:5000) and one unhealthy (192.168.80.2:5001)

Case 1. HTTP Active HealtchCheck on an HTTP Service

Logs report a healtlhy and an unhealhty target. Balancer is choosing the right target.

```
2026/09/07 15:18:47 [debug] 2063#0: *609975 [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking healthy targets: #1
2026/09/07 15:18:47 [debug] 2063#0: *609975 [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5000 (currently healthy)
2026/09/07 15:18:47 [debug] 2063#0: *609977 [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking unhealthy targets: #1
2026/09/07 15:18:47 [debug] 2063#0: *609977 [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5001 (currently unhealthy)
2026/09/07 15:18:47 [debug] 2063#0: *609975 [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Reporting 'flask (192.168.80.2:5000)' (got HTTP 200)

2026/09/07 15:18:50 [debug] 2065#0: *610339 [lua] init.lua:1112: balancer(): setting address (try 1): 192.168.80.2:5000
2026/09/07 15:18:50 [debug] 2065#0: *610339 [lua] init.lua:1141: balancer(): enabled connection keepalive (pool=192.168.80.2|5000, pool_size=60, idle_timeout=60, max_requests=100)
2026/09/07 15:18:50 [info] 2065#0: *610339 client 192.168.80.1 closed keepalive connection
192.168.80.1 - - [07/Sep/2026:15:18:50 +0000] "GET /flaskupstream HTTP/1.1" 200 20 "-" "curl/7.68.0" - -
```

Case 2. TCP Active HealtchCheck on a TCP Service

Logs report a healthy and an unhealthy target. Balancer is choosing the right target

```
2026/09/07 15:12:16 [debug] 2074#0: *573907 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking healthy targets: #1
2026/09/07 15:12:16 [debug] 2074#0: *573907 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5000 (currently healthy)
2026/09/07 15:12:16 [debug] 2074#0: *573909 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking unhealthy targets: #1
2026/09/07 15:12:16 [debug] 2074#0: *573909 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5001 (currently unhealthy)

2026/09/07 15:12:17 [info] 2063#0: *574015 client 192.168.80.1:57472 connected to 0.0.0.0:6000
2026/09/07 15:12:17 [debug] 2063#0: *574015 stream [lua] init.lua:1112: balancer(): setting address (try 1): 192.168.80.2:5000
2026/09/07 15:12:17 [info] 2063#0: *574015 proxy 192.168.80.10:47856 connected to 192.168.80.2:5000
2026/09/07 15:12:17 [info] 2063#0: *574015 upstream disconnected, bytes from/to client:78/174, bytes from/to upstream:174/78
192.168.80.1 [07/Sep/2026:15:12:17 +0000] TCP 200 174 78 0.005
```

Case 3. TCP Active HealthCheck on an HTTP Service

Logs report a healthy and an unhealthy target. Balancer is choosing the wrong target.

```
2026/09/07 15:01:44 [debug] 2074#0: *515789 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking healthy targets: #1
2026/09/07 15:01:44 [debug] 2074#0: *515789 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5000 (currently healthy)
2026/09/07 15:01:44 [debug] 2074#0: *515791 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) checking unhealthy targets: #1
2026/09/07 15:01:44 [debug] 2074#0: *515791 stream [lua] healthcheck.lua:1126: log(): [healthcheck] (01b90fff-5797-4b62-876c-a4d0cb242c34:flask-upstream) Checking flask 192.168.80.2:5001 (currently unhealthy)

2026/09/07 15:01:50 [debug] 2074#0: *516274 [lua] init.lua:1112: balancer(): setting address (try 1): 192.168.80.2:5001
2026/09/07 15:01:50 [debug] 2074#0: *516274 [lua] init.lua:1141: balancer(): enabled connection keepalive (pool=192.168.80.2|5001, pool_size=60, idle_timeout=60, max_requests=100)
2026/09/07 15:01:50 [error] 2074#0: *516274 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.80.1, server: kong, request: "GET /flaskupstream HTTP/1.1", upstream: "http://192.168.80.2:5001/", host: "localhost:8000"
2026/09/07 15:01:50 [debug] 2074#0: *516274 [lua] init.lua:1112: balancer(): setting address (try 2): 192.168.80.2:5000
2026/09/07 15:01:50 [debug] 2074#0: *516274 [lua] init.lua:1141: balancer(): enabled connection keepalive (pool=192.168.80.2|5000, pool_size=60, idle_timeout=60, max_requests=100)
192.168.80.1 - - [07/Sep/2026:15:01:50 +0000] "GET /flaskupstream HTTP/1.1" 200 20 "-" "curl/7.68.0" -
```

The reason why this happens is because TCP HealthChecks are done in the Nginx Stream subsystem (TCP proxy) and there is no shared information with the HTTP Nginx subsystem.

So, Active HTTP HealthChecks should be used when monitoring HTTP services.
