---
title: openid-connect plugin authentication fails, and logs have a timeout error when loading discovery information
content_type: support
description: The timeout log entry when accessing the IdP discovery endpoint indicates that the Kong node cannot reach the discovery endpoint.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does openid-connect plugin authentication fail with a timeout error when loading discovery information?
  a: |
    Kong logs a `notice`-level timeout when it can't reach the IdP's discovery endpoint, so it can't load OIDC discovery info and returns a 401. Work around it by manually setting `authorization_endpoint`, `token_endpoint`, and `extra_jwks_uris` on the `openid-connect` plugin — or, if none of these are reachable either, configure `http_proxy`/`https_proxy` for the plugin (directly or via `admin_gui_auth_conf`).
related_resources: []
---

## Problem

When trying to use the openid-connect plugin for Kong Manager, Portal or proxy authentication using authorization code flow, I am getting a 401 response, and see "notice" log entries like the following:

```
2025/02/16 10:05:15 [notice] 24#0: *3711 [lua] cache.lua:502: get_config(): [openid-connect] loading configuration for https://<IdPEndpoint>.well-known/openid-configuration using discovery failed: timeout, client: <clientIP>, server: kong_admin, request: "GET /auth?<userTryingToLogin>", host: "https://<kongHostName>", referrer: "https://<konghostname>/"
```

Note that the `(falling back to previous configuration)` clause is logged separately at the `debug` log level and does not appear alongside this message at Kong's default `notice` log level.

## Cause

The timeout log entry when accessing the IdP discovery endpoint indicates that the Kong node cannot reach the discovery endpoint. As a result, Kong will fail to load discovery information.

## Solution

This can be worked around by manually specifying the following `openid-connect` plugin parameters:

```
authorization_endpoint
token_endpoint
extra_jwks_uris
```

However, in most cases, if Kong cannot reach the discovery endpoint, it will also be unable to reach the endpoints above.

Start by verifying that the discovery endpoint and these three endpoints are accessible from the Kong node. If they are not reachable, you must either update the network configuration or configure the `openid-connect` plugin to use an HTTP proxy.

The plugin supports HTTP proxy configuration via the following properties, documented in the `http_proxy`, `http_proxy_authorization`, and `https_proxy` sections of the documentation.

Try configuring both `http_proxy` and `https_proxy` if one alone does not resolve the issue.

These configuration options can be set either directly in the plugin configuration or via the `admin_gui_auth_conf` variable.
