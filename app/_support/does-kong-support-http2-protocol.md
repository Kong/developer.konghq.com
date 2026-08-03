---
title: Kong support for the `http2` protocol
content_type: support
description: Kong supports the `http2` protocol via nginx, but it must be enabled in the listen port configuration before clients can use it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Does Kong support `http2` protocol?
  a: |
    Yes. Because Kong is built on nginx, `http2` support follows nginx's `http2` support — it's available but must be enabled via configuration. Add the `http2` suffix to the relevant `proxy_listen` entry to accept `http2` connections. On plain (non-TLS) listen ports, clients must use "prior knowledge" `http2` connections, since nginx doesn't support protocol negotiation without TLS ALPN.
related_resources:
  - text: Kong Gateway configuration reference for `proxy_listen`
    url: /gateway/configuration/#proxy-listen
  - text: "RFC 7540: prior knowledge for starting HTTP/2"
    url: https://datatracker.ietf.org/doc/html/rfc7540#section-3.4
  - text: "HTTP/2 known HTTP methods (httpwg spec)"
    url: https://httpwg.org/specs/rfc7540.html#known-http
---

## Problem

It's not clear whether Kong supports client connections using the `http2` protocol version, and if so, how to enable it.

## Solution

As Kong is using nginx, the support for `http2` follows nginx support. That is to say, `http2` connections are supported but need to be enabled via a configuration setting. The documentation covers configuring the listen ports to accept `http2` connections.

For example, to set the proxy port to accept an `http2` connection over the ssl port, you would need to add the `http2` suffix to the listen port definition as below:

```bash
proxy_listen="0.0.0.0:4800, 0.0.0.0:8443 http2 ssl"
```

You can then make both `http1.x` and `http2` client connections to the proxy port.

1) Using `http1.1` on the https port

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

2) Using `http2` on the https port

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

Support is also available for `http2` on plain listener ports via the same configuration suffix:

```bash
proxy_listen="0.0.0.0:4800 http2, 0.0.0.0:8443 http2 ssl"
```

Note, there is a limitation of nginx that plain `http2` connections are only supported with "prior knowledge". When sending an `http2` connection, it actually starts with an `http1` connection with an Upgrade header for the `http2` protocol and the request will fail with a protocol not allowed error:

```bash

# curl --http2 -v http://0.0.0.0:8000/httpbin/anything
*   Trying 0.0.0.0:8000...
* Connected to 0.0.0.0 (127.0.0.1) port 8000 (#0)
> GET /httpbin/anything HTTP/1.1
> Host: 0.0.0.0:8000
> User-Agent: curl/7.79.1
> Accept: */*
> Connection: Upgrade, HTTP2-Settings
> Upgrade: h2c
> HTTP2-Settings: AAMAAABkAAQCAAAAAAIAAAAA
>
* Received HTTP/0.9 when not allowed
* Closing connection 0
```

Without using prior knowledge, the connection will fail as nginx only supports one protocol version on plain `http2` ports. You can test a prior knowledge request using curl and the `--http2-prior-knowledge` flag:

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

To summarize support for `http2`, you will have to either use https connections where both http1 and `http2` are supported on the same socket via ALPN negotiation or use prior knowledge for the plain socket connections.
