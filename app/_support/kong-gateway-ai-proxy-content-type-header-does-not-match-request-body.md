---
title: "Kong Gateway: AI Proxy \"content-type header does not match request body\""
content_type: support
description: "Explains why the AI Proxy plugin's `content-type header does not match request body` error is dead code in current Kong Gateway releases, and how to resolve the `request body doesn't contain valid inputs` error that replaced it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does the AI Proxy plugin log `content-type header does not match request body`, and how do I resolve it?
  a: |
    This literal error message is dead code in current Kong Gateway releases and no longer appears — the same underlying issue now surfaces as `request body doesn't contain valid inputs`. Confirm the content type is `application/json` and that the request body matches the shape your configured LLM provider expects.
---

## Problem

When attempting to use the AI-Proxy plugin we receive the below error:

Response Body:

```json

{
	"error": {
		"message": "content-type header does not match request body"
	}
}
```

Kong Error log:

```
2024/05/27 13:09:33 [warn] 2160906#0: *2936 [kong] handler.lua:23 [ai-proxy] content-type header does not match request body, client: 192.168.10.10, server: kong, request: "POST /ai HTTP/1.1", host: "kong", request_id: "cbfefa2a2e15db3d91ce0224dea8fb1d"
```

What causes this and how can it be resolved?

## Cause

The exact error message shown above (`content-type header does not match request body`) is now unreachable dead code in current Kong Gateway releases — you will not see this literal message anymore. The underlying situation it used to describe (a genuine mismatch between the content-type header and the request body, or a request body the AI Proxy plugin cannot parse) still occurs, but now instead surfaces as a different error:

```json
{
	"error": {
		"message": "request body doesn't contain valid inputs"
	}
}
```

## Solution

If you encounter this error, check that the content type is `application/json` and use a validator to confirm the JSON payload is properly structured and matches the shape expected by the configured LLM provider format.

Note: an undersized `nginx_http_client_body_buffer_size` (causing the request body to be buffered to disk) does not, on its own, reproduce this error. Buffered-to-disk log lines near the time of the error are not the root cause and increasing this value is not a fix for this issue.
