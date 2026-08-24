---
title: "Kong Gateway: unsafe legacy renegotiation disabled error after 3.4.0.0 upgrade"
content_type: support
description: In Kong Gateway 3.4.0.0+ we have bumped OpenSSL to 3.1.1+.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I get an "unsafe legacy renegotiation disabled" error after upgrading to Kong Gateway 3.4.0.0+?
  a: |
    Kong Gateway 3.4.0.0+ bumped OpenSSL to 3.1.1+, which rejects TLS renegotiation with upstreams running outdated SSL libraries.
    Fix it by updating the upstream's SSL libraries, or as a last resort re-enable legacy renegotiation with `nginx_proxy_proxy_ssl_conf_command = Options +UnsafeLegacyRenegotiation` (this weakens security).
---

## Problem

We recently upgraded to Kong Gateway 3.4.0.0+, we are now having trouble connecting to certain backends via Kong and we get the following error in our error.log:

```
226218 SSL_do_handshake() failed (SSL: error:0A000152:SSL routines::unsafe legacy renegotiation disabled) while SSL handshaking to upstream
```

## Cause

In Kong Gateway 3.4.0.0+ we have bumped OpenSSL to 3.1.1+. Receiving the above error indicates that your upstream server/backend is utilizing outdated SSL libraries.

## Solution

If you are receiving this error there are two ways to remedy the situation:

1. Upgrading the SSL libraries utilized by the upstream/backend. This will more than likely require a conversation with the application team who owns the backend.

2. You can reenable legacy renegotiation on Kong using the following environment variable setting.

   Via `kong.conf`/Helm values file env section:

   ```bash
   nginx_proxy_proxy_ssl_conf_command = Options +UnsafeLegacyRenegotiation
   ```

   Via docker run (Konnect):

   ```bash
   -e "KONG_NGINX_PROXY_PROXY_SSL_CONF_COMMAND=Options +UnsafeLegacyRenegotiation" \
   ```

   Via docker compose environment section:

   ```bash
   KONG_NGINX_PROXY_PROXY_SSL_CONF_COMMAND=Options +UnsafeLegacyRenegotiation
   ```

Please note, this is not the optimal way of fixing this and can lead to security vulnerabilities.
