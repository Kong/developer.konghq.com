---
title: Enabling Brotli HTTP response compression in Kong Gateway
content_type: support
description: Kong Gateway bundles the `ngx_brotli` module, letting you turn on Brotli response compression with a few `KONG_NGINX_PROXY_BROTLI*` environment variables.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I enable Brotli HTTP response compression?
  a: |
    Kong Gateway bundles the `ngx_brotli` module, so Brotli compression is available out of the box. Set the environment variables `KONG_NGINX_PROXY_BROTLI`, `KONG_NGINX_PROXY_BROTLI_COMP_LEVEL`, and `KONG_NGINX_PROXY_BROTLI_TYPES` to turn it on, then verify by requesting with an `Accept-Encoding: br` header and checking for `Content-Encoding: br` in the response.
related_resources: []
---

## Overview

How can I enable Brotli compression for responses from Kong?

## Steps

Kong Gateway supports Brotli compression, bundling the `ngx_brotli` module with Kong. This allows users to enable Brotli compression in a manner similar to gzip. Below are the steps and configurations needed to enable Brotli compression in Kong:

1. Verify ngx_brotli Module is Loaded:

First, ensure that the `ngx_brotli` module is included in your Kong version by running the following command in your Kong container (substitute your own image tag, e.g. `3.14.0.0`):

```bash

docker run -it --rm --user root kong/kong-gateway:3.14.0.0 nginx -V
```

2. Enable Brotli Compression

To enable Brotli compression, you need to set the following environment variables in your Kong configuration;

```yaml

KONG_NGINX_PROXY_BROTLI: "on"
KONG_NGINX_PROXY_BROTLI_COMP_LEVEL: 4
KONG_NGINX_PROXY_BROTLI_TYPES: "*"
```

These settings activate Brotli compression, set the compression level to 4, and enable compression for all MIME types.

3. Testing Brotli Compression

After enabling Brotli compression, you can test it by making an API call with the `Accept-Encoding: br` header. To view the uncompressed output, pipe the response through a Brotli decompressor:

```bash

curl -v -H "Accept-Encoding: br" http://proxy.kong.lan:8000/httpbin/anything | brotli -d
```

In the response you will see the `Content-Encoding: br` header indicating that the response was compressed using Brotli compression.

Without piping the output to the decompressor, the response will be in binary format, indicating the compressed data.

In summary, enabling Brotli compression in Kong is straightforward thanks to the bundled `ngx_brotli` module. By setting the appropriate environment variables, users can optimize their API traffic using this efficient compression method. For gzip and potentially other compression methods, users should consult Kong's documentation for guidance and support.
