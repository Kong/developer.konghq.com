---
title: How to enable response compression using gzip
content_type: support
description: "Enable gzip response compression in Kong by setting the nginx `gzip` directives (`nginx_proxy_gzip`, `nginx_proxy_gzip_proxied`, `nginx_proxy_gzip_types`) in `kong.conf` or as `KONG_NGINX_PROXY_GZIP*` environment variables."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I enable gzip response compression in Kong?
  a: |
    Inject nginx's gzip directives (`nginx_proxy_gzip`, `nginx_proxy_gzip_proxied`, `nginx_proxy_gzip_types`) via `kong.conf` or the equivalent `KONG_NGINX_PROXY_GZIP*` environment variables (available since Kong EE 0.35; earlier versions need a custom nginx template). Clients must send an `Accept-Encoding: gzip` header to receive a compressed response.
related_resources:
  - text: nginx gzip module documentation
    url: http://nginx.org/en/docs/http/ngx_http_gzip_module.html
  - text: Kong nginx-injected directives configuration reference
    url: /gateway/configuration/#nginx-injected-directives-section
---

## Overview

How to enable response compression using the "gzip" method

## Steps

It is possible to add the relevant nginx directives to the Kong configuration to enable the features that the nginx module supports.

For example, you could add the following properties to `kong.conf` or `KONG_` environment variables to enable compression for all requests:

```conf
nginx_proxy_gzip = on
nginx_proxy_gzip_proxied = any
nginx_proxy_gzip_types = *
```

Or use equivalent environment variables:

```bash
KONG_NGINX_PROXY_GZIP=on
KONG_NGINX_PROXY_GZIP_PROXIED=any
KONG_NGINX_PROXY_GZIP_TYPES=*
```

Those are then injected into the proxy server block portion of the template with the `nginx_proxy_` part removed.

Only requests which set the `Accept-Encoding: gzip` header will result in compressed responses. Without this header, the response will be sent uncompressed even after enabling the relevant nginx directives.
