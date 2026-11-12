---
title: Configuring Kong to redirect HTTP traffic to HTTPS
content_type: support
description: Why Kong returns a 426 response on HTTPS-only routes accessed over HTTP by default, and how to configure `https_redirect_status_code` to redirect clients to HTTPS instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong return a `426` response instead of redirecting when a client uses HTTP on an HTTPS-only route?
  a: |
    A `426` response is Kong's default behavior for a route that only accepts `https`. To redirect the client instead, set the route's `https_redirect_status_code` property to a redirect code (`301`, `302`, `307`, or `308`); Kong then responds with that status and a `Location` header pointing to the `https` version of the request.
related_resources: []
---

## Problem

We have a route that only allows the `https` protocol. When traffic reaches this route via `http`, we want the client to be redirected to use `https`, but instead we see a `426` response with a body of `{"message":"Please use HTTPS protocol"}`.

## Cause

The `426` response is the default configuration option on a route that is only enabled for the `https` protocol.

## Solution

If you want to redirect a client, configure the route's `https_redirect_status_code` property to one of the redirect codes: `301`, `302`, `307`, or `308`. This results in Kong sending a response relevant to the chosen redirect code (for example, `308 Permanent Redirect` when `https_redirect_status_code` is set to `308`), along with a `Location` header containing `https://{hostnameUsedInRequest}/{pathUsedInRequest}`.

When accessing the URL over `http` in a browser, this should automatically redirect the browser to `https`.
