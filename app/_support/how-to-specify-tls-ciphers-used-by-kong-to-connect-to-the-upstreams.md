---
title: How to specify TLS ciphers used by Kong to connect to upstreams
content_type: support
description: Configure the Nginx `ngx_http_proxy_module`'s `proxy_ssl_ciphers` directive through Kong's injected configuration to control which TLS ciphers Kong presents when connecting to upstreams.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Kong configuration settings to specify TLS ciphers
    url: /gateway/configuration/#ssl_cipher_suite
  - text: Nginx `proxy_ssl_ciphers` directive documentation
    url: http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_ssl_ciphers
  - text: Nginx configuration values injected into Kong's config
    url: /gateway/configuration/#nginx-injected-directives-section
tldr:
  q: How do I specify the TLS ciphers Kong uses when connecting to upstreams?
  a: |
    Set the Nginx `proxy_ssl_ciphers` directive through Kong's injected Nginx configuration to
    control which TLS ciphers Kong presents in the TLS handshake with upstreams. Configure it in
    `kong.conf` as `nginx_proxy_proxy_ssl_ciphers`, or as the environment variable
    `KONG_NGINX_PROXY_PROXY_SSL_CIPHERS`.
---

## Overview

In the Kong configuration there are some settings to specify the TLS ciphers to be presented to the clients connecting to Kong.

Can I configure a specific set of ciphers to be used by Kong in the TLS handshake with the upstreams?

## Steps

To modify TLS settings when connecting to upstreams, we may need to modify some settings from the Nginx `ngx_http_proxy_module`.

To define the ciphers used by Kong to connect to the upstream, we need to modify the `proxy_ssl_ciphers`.

Kong allows you to inject Nginx configuration values into its config:

So, to configure the `proxy_ssl_ciphers` in the `kong.conf` file we can configure it like:

```bash
nginx_proxy_proxy_ssl_ciphers = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384"
```

We can also configure it as an environment variable, like:

```bash
KONG_NGINX_PROXY_PROXY_SSL_CIPHERS="ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384"
```
