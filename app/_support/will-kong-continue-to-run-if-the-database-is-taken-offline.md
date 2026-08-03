---
title: Kong runtime, Vitals, and audit log behavior when the database is taken offline
content_type: support
description: What happens to Kong Gateway runtime traffic, Vitals data, and audit logging when the primary database is taken offline, such as during a PostgreSQL master standby failover to a secondary instance.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Will Kong continue to run if the database is taken offline?
  a: |
    Kong keeps serving requests from its entities cache, so runtime traffic only fails if it depends on an object (such as an uncached consumer, token, or API key) that wasn't already loaded before the database went offline, or if the request requires a database write. Vitals writes fail and some Vitals data is lost while the database is down, and Kong Manager, the Admin API, and audit endpoints (such as `/audit/requests`) return a 500 error because those responses are not cached.
related_resources: []
---

## Problem

In a master standby PostgreSQL database configuration, when the primary database goes offline during a switch-over to the secondary DB instance, it's unclear whether Kong continues to run without error from cache, and what happens to audit logging and Vitals statistics that would normally be written to the database while it is offline.

## Cause

If the DB is offline, you will get errors for runtime traffic if objects that the requests depend on have not been loaded in the entities cache before the database went offline. For example, if a consumer that was not cached before tries to access an API, related access tokens, API keys etc. can not be read from the database, so the requests will fail. Also, any writes that may be necessary for example when creating new access tokens will fail.

## Solution

For Vitals, the following error will occur in the Kong logs:

```
2026/04/20 01:46:53 [warn] 208#0: *2064 [lua] strategy.lua:562: insert_stats(): [vitals-strategy] failed to insert seconds: host is unreachable, context: ngx.timer                           
2026/04/20 01:46:53 [error] 202#0: *2178 [lua] connector.lua:390: unable to clean expired rows from PostgreSQL database (host is unreachable), context: ngx.timer
```

After you bring the DB up, some of the Vitals data generated while the DB was down may be lost.

You would not be able to make any audit API requests while the DB is down. The response to audit API endpoints such as `/audit/requests` will return a 500 status error.

```bash
[~] http localhost:8001/audit/requests  
HTTP/1.1 500 Internal Server Error
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 43
Content-Type: application/json; charset=utf-8
Date: Tue, 20 Apr 2026 01:49:38 GMT
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Admin-Latency: 32705
X-Kong-Admin-Request-ID: 6aCDDjgrjWI9ns9dZlQKf6b3GSY6ntLZ

{
    "message": "And unexpected error occurred"
}
```

Kong Manager and Admin API also will not work (request will return 500) because all Admin API related responses are NOT cached so if the database is down, the data can not be retrieved from the database any longer.
