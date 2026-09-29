---
title: How to disable SSL ciphers in Kong-Gateway Proxy
content_type: support
description: "Configure Kong's `ssl_cipher_suite` and `ssl_ciphers` settings to enable only the SSL/TLS ciphers you want, instead of disabling the ones you don't."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I disable SSL ciphers I don't want, as many are enabled by default?
  a: |
    Set `ssl_cipher_suite` to `custom` in `kong.conf` (or via the `KONG_SSL_CIPHERS` / `KONG_SSL_CIPHER_SUITE` environment variables) and list only the ciphers you want enabled, rather than trying to disable the ones you don't want.
---

## Overview

How do I disable SSL ciphers I don't want, as many are enabled by default?

## Steps

Kong allows you to configure SSL ciphers by enabling only the ones you require rather than disabling unwanted ones. Configure this by setting the `ssl_cipher_suite` to `custom` and specifying your preferred ciphers.

Set the following in your `kong.conf` file:

```conf
ssl_cipher_suite = custom
```

```conf
ssl_ciphers = <list of ciphers to enable>
```

Example using environment variables:

```bash
KONG_SSL_CIPHERS=ECDHE-RSA-AES256-GCM-SHA384,DHE-PSK-ARIA256-GCM-SHA384,ECDHE-RSA-CHACHA20-POLY1305
KONG_SSL_CIPHER_SUITE=custom
KONG_SSL_PROTOCOLS=TLSv1.2
```

After restarting Kong, verify the loaded SSL ciphers with:

```bash
/usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf -T | grep ssl_ciphers
```

Note: running `nginx -T` on its own (without `-p`/`-c`) fails on current images because the binary's compiled-in default config path doesn't match Kong's runtime layout — the `-p /usr/local/kong -c nginx.conf` flags are required.

For more information, see the `ssl_cipher_suite` and `ssl_protocols` property references.
