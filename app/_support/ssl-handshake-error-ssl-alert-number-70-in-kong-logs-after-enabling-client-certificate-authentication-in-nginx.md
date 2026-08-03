---
title: "SSL handshake error \"SSL alert number 70\" in Kong logs after enabling Client Certificate Authentication in Nginx"
content_type: support
description: SSL handshake failures with "SSL alert number 70" after enabling Client Certificate Authentication in Nginx usually mean the client isn't sending a certificate, or is sending the wrong one, for the configured `ssl_verify_client` value.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do clients get an "SSL alert number 70" handshake error after enabling Client Certificate Authentication in Nginx?
  a: |
    This usually means the client isn't sending a certificate, or is sending the wrong one, for the configured `ssl_verify_client` value. Confirm the client includes a certificate and that any load balancer in front of Kong isn't terminating TLS, then verify the Nginx directives (`nginx_http_ssl_verify_client`, `nginx_http_ssl_verify_depth`, `nginx_http_ssl_client_certificate`) are set correctly for your certificate bundle. If the error appeared before Client Certificate Authentication was enabled, the cause is more likely an unrelated TLS mismatch (cipher suite or protocol version) in `ngx_http_ssl_module`.
---

## Problem

Clients fail to call Kong routes after enabling Client Certificate Authentication/Verification in Nginx. We see the following error in Kong logs after enabling it with clients calling the routes:

```

2026/12/01 14:01:00 [info] 1317346#0: *5732 SSL_do_handshake() failed (SSL: error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:SSL alert number 70) while SSL handshaking, client: xxx.xxx.xxx.xxx, server: 0.0.0.0:8443
```

To enable the Client Certificate Authentication in Nginx, we had set the following Nginx directives in the Kong configuration: (attributes below are linked to relevant Nginx documentation for reference)

- `nginx_http_ssl_verify_client = optional_no_ca`
- `nginx_http_ssl_verify_depth = 3`
- `nginx_http_ssl_client_certificate = /etc/kong/certs/kong-ca-bundle.pem`

## Solution

Assuming that the behavior was only noticed after making the changes above to enable Client Certificate Authentication/Verification in Nginx, then this behavior would generally be seen when the client(s) sending the requests to Kong did not contain a client certificate or contained the wrong client certificate (depending on the value of `ssl_verify_client`).

If no client certificate is present in the request or the wrong client certificate is presented, the request is then denied during the handshake process.

To troubleshoot or resolve this behavior:

- Ensure that the client is including a certificate with their request to Kong. If it is, then also ensure that the load balancer fronting Kong Gateway nodes is not terminating SSL/TLS.
- If the above is all correctly set, then ensure that the values for the Nginx directives are also correctly set for the particular use-case required in the environment (i.e. check the client certificate path is valid, ensure it is able to verify enough levels deep in the certificate bundle, etc).

If the errors were actually seen in Kong logs prior to enabling any Client Certificate Authentication functionality in Nginx, then the issue would likely be caused instead by TLS-related mismatches such as cipher suites, protocol versions, or other TLS-related misconfigurations in the Nginx `ngx_http_ssl_module`.
