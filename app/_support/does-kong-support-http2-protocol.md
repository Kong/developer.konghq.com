---
title: http2 protocol support for client connections in Kong
content_type: support
description: "Kong supports http2 client connections through nginx: by default over TLS ports and via HTTP/2 prior knowledge on plain ports."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Does Kong support http2 protocol?
  a: |
    Yes. Kong's http2 support follows nginx's, and the default `proxy_listen` for the HTTPS proxy port already includes the `http2` suffix, so http2 client connections work out of the box over TLS. Plain (non-TLS) http2 connections only work when the client uses HTTP/2 prior knowledge, since nginx doesn't negotiate a protocol upgrade on non-TLS ports.
related_resources:
  - text: "{{site.base_gateway}} `proxy_listen` configuration reference"
    url: /gateway/configuration/#proxy-listen
  - text: RFC 7540 section 3.4 (starting HTTP/2 with prior knowledge)
    url: https://datatracker.ietf.org/doc/html/rfc7540#section-3.4
  - text: RFC 7540 known-http2 reference (httpwg.org mirror)
    url: https://httpwg.org/specs/rfc7540.html#known-http
---

## Problem

Whether Kong supports client connections using the http2 protocol version.

## Solution

As Kong is using nginx, support for http2 follows nginx support. The default shipped `proxy_listen` for the SSL proxy port already includes the `http2` suffix (`0.0.0.0:8443 http2 ssl`), so http2 client connections are supported out of the box on the default HTTPS proxy port with no configuration changes needed. A manual `http2` suffix is only required if you override `proxy_listen` with a fully custom listen definition.

If you use a fully custom `proxy_listen` override, remember to add the `http2` suffix to the listen port definition yourself, as below;

```bash
proxy_listen="0.0.0.0:4800, 0.0.0.0:8443 http2 ssl"
```

You can then make both http1.x and http2 client connections to the proxy port.

1) Using http1.1 on the https port

```bash

# curl -k --http1.1 -v https://0.0.0.0:8443/httpbin/anything
*   Trying 0.0.0.0:8443...
* Connected to 0.0.0.0 (127.0.0.1) port 8443 (#0)
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
<...snip certificate details...>
> GET /httpbin/anything HTTP/1.1
> Host: 0.0.0.0:48443
> User-Agent: curl/7.79.1
> Accept: */*
>
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
```

2) Using http2 on the https port

```bash

# curl -k --http2 -v https://0.0.0.0:8443/httpbin/anything
*   Trying 0.0.0.0:8443...
* Connected to 0.0.0.0 (127.0.0.1) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
<...snip certificate details...>
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fd4eb983a90)
> GET /httpbin/anything HTTP/2
> Host: 0.0.0.0:48443
> user-agent: curl/7.79.1
> accept: */*
>
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200
```

Support is also available for http2 on plain listener ports via the same configuration suffix;

```bash
proxy_listen="0.0.0.0:4800 http2, 0.0.0.0:8443 http2 ssl"
```

Note, there is a limitation of nginx that plain http2 connections are only supported with "prior knowledge". When a client attempts an http2 connection on a plain (non-TLS) port without prior knowledge, the request actually starts as a normal http1.1 request carrying an `Upgrade: h2c` header. Kong/nginx does not switch protocols for this request: it silently ignores the Upgrade header and serves the request as an ordinary HTTP/1.1 response instead of upgrading to http2 - it does not reject the request or return a protocol error. Depending on the http client, this can show up as a perfectly normal HTTP/1.1 200 response (confirmed with curl 8.7.1) or, on some older http client versions, as a client-side connection error instead (older curl releases could mishandle the unexpected non-101 response and abort with an error such as `Received HTTP/0.9 when not allowed`). Either way, the connection is never actually upgraded to real http2;

```bash

# curl --http2 -v http://0.0.0.0:8000/httpbin/anything
*   Trying 0.0.0.0:8000...
* Connected to 0.0.0.0 (127.0.0.1) port 8000 (#0)
> GET /httpbin/anything HTTP/1.1
> Host: 0.0.0.0:8000
> User-Agent: curl/8.7.1
> Accept: */*
> Connection: Upgrade, HTTP2-Settings
> Upgrade: h2c
> HTTP2-Settings: AAMAAABkAAQCAAAAAAIAAAAA
>
* Request completely sent off
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Connection: keep-alive
<
* Connection #0 to host 0.0.0.0 left intact
```

Without using prior knowledge, the plain-http2 connection attempt never actually becomes http2 - nginx only supports one protocol version on plain (non-TLS) ports, and it simply falls back to serving the request as HTTP/1.1. You can test a genuine prior-knowledge http2 request using curl and the --http2-prior-knowledge flag;

```bash

# curl --http2 --http2-prior-knowledge -v http://0.0.0.0:8000/httpbin/anything
* Trying 0.0.0.0:8000...
* Connected to 0.0.0.0 (127.0.0.1) port 8000 (#0)
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f22c0691a90)
> GET /httpbin/anything HTTP/2
> Host: 0.0.0.0:8000
> user-agent: curl/7.79.1
> accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200
```

Below are a couple of RFC links with details of prior knowledge.

To summarize support for http2, you will have to either use https connections where both http1 and http2 are supported on the same socket via ALPN negotiation or use prior knowledge for the plain socket connections.
