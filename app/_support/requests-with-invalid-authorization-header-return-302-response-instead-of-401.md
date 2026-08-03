---
title: Requests with invalid Authorization header return 302 response instead of 401 when using the OpenID Connect plugin
content_type: support
description: The OpenID Connect plugin's default `config.auth_methods` includes all authentication methods, so a request with an invalid Authorization header falls through to the authorization code flow and gets a 302 redirect instead of a 401.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why does a request with an invalid Authorization header get a 302 redirect instead of a 401 when using the OpenID Connect plugin?
  a: |
    By default, the OpenID Connect plugin's `config.auth_methods` includes every supported authentication method. When no bearer token is found, the plugin falls back to the authorization code flow, which redirects to the OpenID Connect provider — producing a 302 instead of a 401. Restrict `config.auth_methods` to only the methods you actually need.
---

## Problem

When configuring the OpenID Connect plugin via Kong Manager, and not changing the default `config.auth_methods` configuration parameter, requests with an invalid `Authorization` header return a 302 response instead of the expected 401 response. Specifically, this was observed for requests where the `Authorization` header was missing `Bearer` from its value.

## Cause

The default value of the `config.auth_methods` parameter when adding the OpenID Connect plugin is to include ALL supported authentication methods. This means that if no bearer token can be found (which happens also if `Bearer` is missing from the `Authorization` header), the OpenID Connect plugin tries the authorization code flow as one of the enabled authorization methods. This flow requires a redirect to the OpenID Connect provider, which explains why the 302 redirect response code is returned.

## Solution

The OpenID Connect plugin configuration should only have those authentication methods enabled that are absolutely necessary for the plugin to work with the expected requests. As documented at /plugins/openid-connect/, "Decide what authentication grants to use with this plugin and configure the `config.auth_methods` field accordingly." Kong Manager has been modified to not populate all `auth_methods` by default, but the UI provides a list of supported methods which are all unchecked, making it necessary for a developer to select those methods that should be supported. The Admin API and declarative configuration will add all methods if the parameter is omitted.

If it is not clear why the OpenID Connect plugin causes unexpected behavior as the one mentioned above, the best way to troubleshoot this is to set the log level in your test instance to `debug`, and then check for log entries containing `openid-connect`. The debug logging is very verbose, and tends to provide great insight into what exactly is happening when the plugin is executed. For example, use the following command:

```bash
tail -f /usr/local/kong//logs/error.log | grep openid-connect
```
