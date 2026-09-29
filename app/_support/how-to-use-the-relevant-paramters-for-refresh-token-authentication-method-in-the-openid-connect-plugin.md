---
title: How to use the relevant parameters for refresh token authentication method in the `openid-connect` plugin
content_type: support
description: The `refresh_token_param_type` parameter determines where Kong will look for the refresh token in an incoming request.
tldr:
  q: How do I configure the `openid-connect` plugin to accept a refresh token in the request body?
  a: |
    Set `refresh_token_param_type` to `body` so Kong reads the refresh token from the request body (JSON or form-urlencoded), and set `refresh_token_param_name` to the key you send (e.g. `refresh-token`).
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Overview

We are trying to use the refresh token authentication method with the `openid-connect` plugin but it is not clear how to make this work when setting `refresh_token_param_type` to body. What is an example of how to configure the `openid-connect` plugin, and send the refresh token in a body

## Steps

The `refresh_token_param_type` parameter determines where Kong will look for the refresh token in an incoming request.

If this is set to `body` only then kong expects the refresh token to be sent as part of the request body. The body can be either in a JSON or form url encoded.

These are two curl examples:

```bash
curl --request POST \
--url <kong_proxy_endpoint> \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data refresh-token=<token>
```

```bash
curl --request POST \
--url <kong_proxy_endpoint> \
--header 'Content-Type: application/json' \
--data '{"refresh-token": "<token>"}'
```

Note that the `refresh_token_param_name` parameter determines what key Kong will be looking for the token for. For the above examples to work, `refresh_token_param_name` needs to be set to `refresh-token`
