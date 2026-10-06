---
title: "\"could not deserialize/serialize JSON payload to table: bad argument #1 to '?' (string expected, got nil) while logging request\" error on bodyless GET/DELETE Admin API requests with audit logging enabled"
content_type: support
description: The audit log code only checks the body of admin requests when a request body is actually present.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does Kong log a `could not deserialize/serialize JSON payload to table: bad argument #1 to '?' (string expected, got nil) while logging request` error, and how can I fix it?"
  a: |
    By default, the audit log module only tries to deserialize/log a JSON payload when the request actually has a body. A bodyless GET or DELETE Admin API request that still sends a `content-type: application/json` header trips this check and logs the error — but the request is still recorded correctly in `audit_requests`, so it's harmless. Drop the `content-type: application/json` header from bodyless GET/DELETE requests to avoid the message.
---

## Problem

When audit logging is enabled, the following error messages are seen in the logs for GET, and DELETE Admin API requests;

```

2026/09/07 00:22:33 [error] 5417#0: *69428 [kong] audit_log.lua:232 could not deserialize/serialize JSON payload to table: bad argument #1 to '?' (string expected, got nil) while logging request, client: 127.0.0.1, server: kong_admin, request: "GET /plugins HTTP/1.1", host: "0:8001"
```

```

2026/09/07 00:23:55 [error] 5417#0: *71608 [kong] audit_log.lua:232 could not deserialize/serialize JSON payload to table: bad argument #1 to '?' (string expected, got nil) while logging request, client: 127.0.0.1, server: kong_admin, request: "DELETE /plugins/5392345b-3395-4236-b7e7-f62352159899 HTTP/1.1", host: "0:8001"
```

Why are these errors shown and how can they be fixed?

## Cause

The audit log code (`kong/enterprise_edition/audit_log.lua`) only attempts to deserialize/log the JSON payload when a request body is actually present (`payload ~= nil`). Because of this, a bodyless GET or DELETE Admin API request that still carries a `content-type: application/json` header does not produce this error, and the request continues to be logged correctly in the `audit_requests` table.

## Solution

If you do see this error on a bodyless GET/DELETE Admin API request with a `content-type: application/json` header, it is harmless — the Admin request is still logged correctly in the `audit_requests` table — and can be avoided by making the GET/DELETE requests without a `content-type: application/json` header.
