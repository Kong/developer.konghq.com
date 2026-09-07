---
title: UUID version used to generate the correlation ID
content_type: support
description: "The correlation-id plugin in Kong uses the `resty.jit-uuid` library to generate a version 4 UUID (v4 UUID)."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Which UUID version is used to generate the Correlation ID?
  a: |
    The `correlation-id` plugin uses the `resty.jit-uuid` library to generate a version 4 UUID. Its default generator, `uuid#counter`, creates one UUID per Nginx worker at startup and appends an incrementing counter per request rather than issuing a fresh UUID each time — set `config.generator` to `uuid` for a fully random UUID on every request. Kong Gateway also generates a unique Request ID by default (exposed via the `X-Kong-Request-Id` header), so the plugin isn't required just to get unique per-request tracking.
related_resources:
  - text: the lua-resty-jit-uuid library documentation
    url: https://thibaultcha.github.io/lua-resty-jit-uuid/#generate_v4
  - text: Kong changelog
    url: /gateway/changelog/
  - text: the associated pull request
    url: https://github.com/Kong/kong/pull/11663
---

## Problem

It's unclear what version of UUID is used to generate the correlation ID in Kong, and how to ensure that a unique Request ID is generated for all requests.

## Solution

The `correlation-id` plugin in Kong uses the `resty.jit-uuid` library (wrapped internally via `kong.tools.uuid`) to generate a version 4 UUID (v4 UUID). The specific format of the UUID generated can be found in the documentation for the `lua-resty-jit-uuid` library.

Note that the plugin's `config.generator` setting controls whether every request actually gets its own fresh v4 UUID. The plugin's default generator, `uuid#counter`, generates ONE v4 UUID per Nginx worker at startup and appends an incrementing counter to it for each request (`<worker-uuid>#<counter>`) — this is not a fresh UUID per request. If you need a distinct, fully-random v4 UUID on every single request, set `config.generator` to `uuid` explicitly (a third mode, `tracker`, is also available).

It is not necessary to use the `correlation-id` plugin to generate a unique Request ID for all requests. Kong Gateway includes a unique Request ID by default, which is populated in various components such as the error log, access log, error templates, log serializer, and the `X-Kong-Request-Id` header. This feature enhances the ability to trace requests throughout the system.

The configuration for this feature can be customized for both upstream and downstream communications using the `headers` and `headers_upstream` configuration options — both include `x-kong-request-id` by default as of Kong Gateway 3.14.0.0. More details about this feature and its implementation can be found in the Kong changelog and the associated pull request.

By following these guidelines, users can ensure that a unique Request ID is generated for all requests, facilitating better tracking and correlation of requests within Kong.
