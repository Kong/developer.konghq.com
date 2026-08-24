---
title: TLS v1.3 support for connecting to Upstreams in Kong
content_type: support
description: Support for Upstream TLS v1.3 is possible but is not enabled by default.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Do Upstreams in Kong support TLS v1.3?
  a: |
    Yes. Kong's bundled OpenResty already includes TLS 1.3 in its default protocol set, so Upstream connections negotiate it without any `proxy_ssl_protocols` override. Use `proxy_ssl_protocols` only if you need to restrict which protocol versions Kong negotiates with an Upstream.
related_resources:
  - text: nginx `proxy_ssl_protocols` directive documentation
    url: https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_ssl_protocols
---

## Problem

When connecting to an Upstream that only supports TLS v1.3 an error is returned for the protocol version and the handshake fails;

```

*3933522 SSL_do_handshake() failed (SSL: error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:SSL alert number 70) while SSL handshaking to upstream, client: 172.17.0.1, server: kong, request: "GET /test-v13 HTTP/1.1", upstream: "https://10.0.1.1:8888/", host: "api.kong.lan"
```

Is TLS v1.3 supported for connecting to Upstreams?

## Solution

TLS v1.3 to Upstreams works by default. Kong's bundled OpenResty (1.27.1.2 as of Kong Gateway 3.14.0.0) already includes TLS 1.3 in its own default protocol set, so no `proxy_ssl_protocols` override is needed to enable it, and Kong's own templates never set `proxy_ssl_protocols` themselves.

If you previously added a `proxy_ssl_protocols` override to work around this, you can remove it. The `proxy_ssl_protocols` nginx directive is still useful, but only if you need to *restrict* which protocol versions Kong will negotiate with an Upstream (for example, to disallow older TLS versions).

To set this in Kong, you can inject the proxy directive directly. For example, in the `kong.conf` add this parameter (changing the values list as appropriate to restrict to only the protocol versions you want to allow);

```bash
nginx_proxy_proxy_ssl_protocols = TLSv1.2 TLSv1.3
```
