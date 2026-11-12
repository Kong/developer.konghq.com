---
title: "{{site.kic_product_name}} logs error: \"http2 requests not supported yet\""
content_type: support
description: This error occurs because the {{site.kic_product_name}} accesses the {{site.base_gateway}} Admin API `/status` endpoint over HTTP/2.0, an incompatibility that's fixed in current {{site.base_gateway}} releases (confirmed on 3.14.0.0).
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: 'Why does {{site.kic_product_name}} log "http2 requests not supported yet" when checking {{site.base_gateway}} status?'
  a: |
    The {{site.kic_product_name}}'s health check hits the {{site.base_gateway}} Admin API's `/status` endpoint over HTTP/2, which older {{site.base_gateway}} versions didn't support on that route. This is fixed in current {{site.base_gateway}} (confirmed on `3.14.0.0`) — if you're on an older version, you can ignore the log noise or remove `http2` from `admin_listen` until you upgrade.
---

## Problem

We see {{site.kic_product_name}} logging messages frequently such as the following:

```
time="2026-09-07T18:07:05Z" level=error msg="checking config status failed: %!w(*kong.APIError=&{500 An unexpected error occurred})"
```

In addition, we see the following stack traces thrown in the {{site.base_gateway}} proxy:

```
2026/09/07 16:36:11 [error] 2052#0: *4682600 [lua] api_helpers.lua:526: handle_error(): /usr/local/share/lua/5.1/lapis/application.lua:424: /usr/local/share/lua/5.1/kong/api/routes/health.lua:49: http2 requests not supported yet
stack traceback: [C]: in function 'capture' /usr/local/share/lua/5.1/kong/api/routes/health.lua:49: in function 'fn' /usr/local/share/lua/5.1/kong/api/api_helpers.lua:293: in function 'fn' /usr/local/share/lua/5.1/kong/api/api_helpers.lua:293: in function </usr/local/share/lua/5.1/kong/api/api_helpers.lua:276> stack traceback: [C]: in function 'error' /usr/local/share/lua/5.1/lapis/application.lua:424: in function 
'handler' 
127.0.0.1 - - [07/Sep/2026:16:36:11 +0000] "GET /status HTTP/2.0" 500 42 "-" "Go-http-client/2.0"
```

How do we resolve this issue?

## Cause

This error occurred because the {{site.kic_product_name}} attempts to access the {{site.base_gateway}} Admin API `/status` endpoint over HTTP/2.0, which was not supported on that endpoint in older {{site.base_gateway}} versions.

## Solution

This was a known issue discussed at GitHub Issue #2435 for the {{site.kic_product_name}}. A pull request (#8690) for {{site.kic_product_name}} was created to address this.

**This issue is fixed on current {{site.base_gateway}} (confirmed on 3.14.0.0).** The Admin API's `/status` route no longer performs an internal `ngx.location.capture` subrequest that used to be incompatible with HTTP/2, and a live test against a {{site.base_gateway}} 3.14.0.0 node with the default `admin_listen = ... 8444 http2 ssl` now returns a clean `200` for `GET /status HTTP/2.0`, with no error logged. If you are on {{site.base_gateway}} 3.14.0.0 (or any reasonably current version), you should not see this error at all, and no workaround is needed.

If you are still on an older, affected {{site.base_gateway}} version, the same two workarounds still apply:

1) Ignore the issue; it only results in log noise and does not affect functionality.

2) If ignoring is not possible, disable HTTP/2.0 on the Admin API by removing `http2` from the `admin_listen` property. Refer to the documentation for more details.

The best long-term fix is to upgrade to a current {{site.base_gateway}} version, where this no longer occurs.
