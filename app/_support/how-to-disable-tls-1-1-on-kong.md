---
title: How to disable TLS 1.1 on Kong
content_type: support
description: "Learn how to disable TLS 1.1 on Kong Gateway by checking the default `ssl_protocols`/`lua_ssl_protocols` settings and removing any override that still enables it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the current configuration property reference
    url: /gateway/configuration/
tldr:
  q: How do I disable TLS 1.1 on Kong Gateway?
  a: |
    Kong Gateway's default `ssl_protocols`/`lua_ssl_protocols` settings already exclude `TLSv1.1`, so no action is needed unless a `kong.conf` setting, environment variable, or custom nginx template still overrides them to include it. If one does, remove `TLSv1.1` from the value (or remove the override entirely) and restart Kong.
---

## Overview

TLS 1.1 has been deprecated. Older Kong Gateway versions supported TLS 1.1 by default; this article guides you on how to disable TLS 1.1 on Kong if your configuration still enables it.

## Steps

The default value of `lua_ssl_protocols` (and the related `ssl_protocols`/`nginx_http_ssl_protocols`/`nginx_stream_ssl_protocols` settings) does not include `TLSv1.1`: every rendered `ssl_protocols`/`lua_ssl_protocols` directive (proxy, Admin API, Admin GUI, Dev Portal, stream) defaults to `TLSv1.2 TLSv1.3`, with no explicit config set. TLS 1.1 is already disabled out of the box — no action is required, unless your `kong.conf`/environment variables (or a custom nginx template) explicitly override one of these settings to include `TLSv1.1`, for example because that override was carried forward unchanged from an older configuration during an upgrade.

The `lua_ssl_protocols` parameter is related to SSL protocols.

See the current configuration property reference.

If your configuration explicitly sets this parameter to a value that includes `TLSv1.1` (e.g. `"TLSv1.1 TLSv1.2 TLSv1.3"`), remove `TLSv1.1` from the value — or remove the override entirely to fall back to the current secure default — and restart Kong:

- `KONG_LUA_SSL_PROTOCOLS=TLSv1.2 TLSv1.3`
