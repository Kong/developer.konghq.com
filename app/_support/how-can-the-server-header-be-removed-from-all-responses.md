---
title: Removing the Server header from all responses
content_type: support
description: Configure the `headers` parameter in `kong.conf`, plus the bundled `headers-more-nginx-module` for nginx-generated error pages, to remove the Server header from Kong responses.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can the Server header be removed from all responses?
  a: |
    Set the `headers` parameter in `kong.conf` (dropping `server_tokens` from its value, for example `headers=latency_tokens`) to remove the Server header from normal responses. For error pages generated directly by nginx, use the bundled `headers-more-nginx-module` — for example, by setting `KONG_NGINX_HTTP_MORE_CLEAR_HEADERS=Server`.
related_resources:
  - text: "Kong Gateway configuration reference: `headers` parameter"
    url: /gateway/configuration/#headers
---

## Overview

When an error response is returned from Kong, the Server header is included in the response to the client:

```bash
curl -X TRACE -v http://kong:8000/echo
*   Trying 10.0.10.1...
* TCP_NODELAY set
* Connected to kong (10.0.10.1) port 8000 (#0)
> TRACE /echo HTTP/1.1
> Host: kong:8000
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 405 Not Allowed
< Server: openresty/1.13.6.2
< Date: Thu, 21 Nov 2026 15:26:13 GMT
< Content-Type: text/html; charset=UTF-8
< Content-Length: 179
< Connection: close
<
<html>
<head><title>405 Not Allowed</title></head>
<body bgcolor="white">
<center><h1>405 Not Allowed</h1></center>
<hr><center>openresty/1.13.6.2</center>
</body>
</html>
* Closing connection 0
```

In the above example, you can see the header `Server: openresty/1.13.6.2`. This is considered an exposure of potentially sensitive information and needs to be suppressed.

## Steps

For normal responses, the `headers` parameter in `kong.conf` can be configured. By default, this will add a Server header.

For example, to remove the Server header, remove the `server_tokens` value from the parameter. For example:

```bash
headers=latency_tokens
```

For error pages, you can use the `ngx_headers_more` module to remove the Server header. The Kong build ships with this module included, which you can check with the `nginx -V` command and check for the `headers-more-nginx-module` in the output. For example:

```bash
# /usr/local/openresty/nginx/sbin/nginx -V
nginx version: openresty/1.15.8.2
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC)
built with OpenSSL 1.1.1c 28 May 2026
TLS SNI support enabled
configure arguments: --prefix=/usr/local/openresty/nginx --with-cc-opt='-O2 -I/tmp/tmp/openssl-1.1.1c/include' --add-module=../ngx_devel_kit-0.3.1rc1 --add-module=../echo-nginx-module-0.61 --add-module=../xss-nginx-module-0.06 --add-module=../ngx_coolkit-0.2 --add-module=../set-misc-nginx-module-0.32 --add-module=../form-input-nginx-module-0.12 --add-module=../encrypted-session-nginx-module-0.08 --add-module=../srcache-nginx-module-0.31 --add-module=../ngx_lua-0.10.15 --add-module=../ngx_lua_upstream-0.07 --add-module=../headers-more-nginx-module-0.33 --add-module=../array-var-nginx-module-0.05 --add-module=../memc-nginx-module-0.19 --add-module=../redis2-nginx-module-0.15 --add-module=../redis-nginx-module-0.3.7 --add-module=../rds-json-nginx-module-0.15 --add-module=../rds-csv-nginx-module-0.09 --add-module=../ngx_stream_lua-0.0.7 --with-ld-opt='-Wl,-rpath,/usr/local/openresty/luajit/lib -L/tmp/tmp/openssl-1.1.1c -Wl,--disable-new-dtags,-rpath,/usr/local/kong/lib,-u,pcre_version' --with-pcre=/tmp/tmp/pcre-8.41 --with-pcre-jit --with-http_realip_module --with-http_ssl_module --with-http_stub_status_module --with-stream_ssl_preread_module --with-stream_realip_module --with-http_v2_module --add-module=/tmp/tmp/kong-licensing/ngx_module --add-module=/tmp/tmp/lua-kong-nginx-module --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module
```

You can then inject another nginx parameter to clear the Server header:

```bash
-e "KONG_NGINX_HTTP_MORE_CLEAR_HEADERS=Server"
```
