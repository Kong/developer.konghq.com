---
title: DNS resolution failed when setting `http_proxy` for the OpenID Connect plugin behind a proxy
content_type: support
description: The `config.http_proxy` and `config.https_proxy` parameters refer to the protocol of the IdP's URL, not the protocol between Kong and the proxy.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the OpenID Connect plugin fail discovery with a DNS resolution error when `http_proxy` is configured?
  a: |
    `config.http_proxy` and `config.https_proxy` refer to the protocol of the IdP's discovery URL, not the protocol Kong uses to reach the proxy itself. Set `config.https_proxy` (not `http_proxy`) whenever the IdP's endpoint is `https://`, even if Kong reaches the proxy over plain HTTP.
related_resources: []
---

## Problem

The user is running Kong in an internal environment and must go through a proxy to access OIDC IdP URLs as below:

When setting up `http_proxy` to proxy as `config.http_proxy: <proxy_ip>:<proxy_port>` in the OIDC plugin, the user gets DNS resolution errors as below:

```

[openid-connect] loading configuration for https://<IDP_HOST>/auth/realms/demo using discovery, client: 172.26.0.4, server: kong, request: "GET /test HTTP/1.1", host: "kong-ee:8000"

2026/05/07 02:13:20 [notice] 25#0: *23541 [lua] cache.lua:258: discover(): [openid-connect] loading configuration for https://<IDP_HOST>/auth/realms/demo using discovery failed: [cosocket] DNS resolution failed: dns lookup pool exceeded retries (1): timeout. Tried: ["(short)<IDP_HOST>:(na) - cache-miss","<IDP_HOST>:33 - cache-miss/scheduled/querying/try 1 error: timeout/scheduled/querying/try 2 error: timeout/dns lookup pool exceeded retries (1): timeout","<IDP_HOST>:1 - cache-miss/scheduled/querying/try 1 error: timeout/scheduled/querying/try 2 error: timeout/dns lookup pool exceeded retries (1): timeout","<IDP_HOST>:5 - cache-miss/scheduled/querying/try 1 error: timeout/scheduled/querying/try 2 error: timeout/dns lookup pool exceeded retries (1): timeout"] (falling back to previous configuration), client: 172.26.0.4, server: kong, request: "GET /test HTTP/1.1", host: "kong-ee:8000"
```

## Cause

Let's check the description of these two parameters:

- `http_proxy`: The proxy URL for HTTP communications.
- `https_proxy`: The proxy URL for HTTPS communications.

These two parameters are not referring to the http or https protocol between Kong and the proxy, they are referring to the http or https protocol of your IdP URL.

## Solution

For example, if your IdP's discovery endpoint is `https://<IDP_URL>/.well-known/openid-configuration`, even though Kong is talking to your proxy via http, you need to set `config.https_proxy=http://<proxy_ip>:<proxy_port>`.

Once the right parameter is used, you should see OIDC loading the discovery information correctly.

```

2026/05/07 12:43:57 [debug] 25#0: *2468 [lua] handler.lua:96: [openid-connect] loading discovery information
2026/05/07 12:43:57 [debug] 25#0: *2468 [lua] handler.lua:139: [openid-connect] initializing library
```
