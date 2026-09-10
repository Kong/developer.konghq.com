---
title: After upgrading to Kong 3.10.0.0 I can not log into Kong Manager after making documented changes
content_type: support
description: Kong 3.10.x moved Kong Manager session handling to the openid-connect plugin, which can produce a session cookie header larger than Nginx's default proxy buffer, causing login to fail with an upstream error.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why can't I log into Kong Manager after upgrading to Kong 3.10.0.0 and configuring openid-connect authentication?
  a: |
    Kong 3.10.x moved Kong Manager session handling to the openid-connect plugin, which returns a session cookie header that can be larger than in previous versions — often larger than Nginx's default header buffer when proxied through Kong, causing an "invalid response from upstream" error. Increase `nginx_proxy_proxy_buffer_size` (try 8k, 10k, 12k, or 16k) to fix it; note this is a global Nginx setting that affects all traffic through the same data plane.
related_resources: []
---

## Problem

While upgrading to Kong 3.10.0.0 we changed the Kong Manager configuration according to the document requirements when using openid-connect authentication for the Manager.

We are proxying all traffic to the Kong Manager service through Kong, and after the changes made, we can still not log into Kong Manager but get the following error in the Browser:

```
Error

An invalid response was received from the upstream server.

request_id: 8150ea003c03816da5ecc51920993417
```

Are we missing a configuration option?

## Cause

The changes regarding openid-connect authentication in Kong Manager in version 3.10.X.X of Kong mean that the session handling is now done via the openid-connect plugins. This means the plugin will initiate the creation of a session cookie as documented in the openid-connect plugin documentation.

With this new configuration a session cookie header will be sent back to the Browser client which depending on what information is returned by the IdP in the tokens it generates during the login process can be much larger than the session data that was generated in previous versions when using the default session object.

If you are proxying your traffic through Kong, this may breach the default header limit, and you should see an error log entry similar to this:

```
2025/03/12 12:34:49 [error] 2385#0: *4019 upstream sent too big header while reading response header from upstream, client: 192.168.1.4, server: kong, request: "GET /auth?code=<code>&state=<state>&session_state=:session_state>", host: "api.kong.lan", referrer: "https://login.live.com/", request_id: "8150ea003c03816da5ecc51920993417"
```

## Solution

To address this issue, you will have to increase the `nginx_proxy_proxy_buffer_size` setting.

Since the size of the cookie headers depends on what information the IdP returns in the tokens, you may have to try different values for the `nginx_proxy_proxy_buffer_size` starting with 8k, 10k, 12k or 16k.

Please note that this setting is a global setting which means all requests that are proxied through the same Kong data plane as the Kong Manager traffic will be affected by this, i.e. traffic with larger headers will be allowed.
