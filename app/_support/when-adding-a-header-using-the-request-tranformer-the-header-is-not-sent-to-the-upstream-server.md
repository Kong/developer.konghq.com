---
title: When adding a header using the request-tranformer the header is not sent to the upstream server
content_type: support
description: The `request-transformer` plugin evaluates `config.remove.headers`, `config.replace.headers`, and `config.add.headers` in that order, so a header added via `config.add.headers` is skipped if the client already sent it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why isn't a header added by the request-transformer plugin sent to the upstream server?
  a: |
    The `request-transformer` plugin processes headers in a fixed order: it removes headers listed in `config.remove.headers`, replaces headers listed in `config.replace.headers`, and only then adds headers from `config.add.headers` — but `config.add.headers` is skipped whenever the client already sent that header. To override a client-sent header, use `config.replace.headers`, or combine `config.remove.headers` with `config.add.headers`.
related_resources:
  - text: request-transformer documentation
    url: /plugins/request-transformer/
---

## Problem

When a request is received from a client, the request-transformer plugin has been configured to add a header which should be sent to the upstream service. When the upstream service receives the request, the header is missing

## Cause

The behavior of the `request-transformer` plugin is documented. It evaluates header changes in a fixed order using three parameters:

- `config.remove.headers` - List of header names. Unset the header(s) with the given name.
- `config.add.headers` - List of `headername:value` pairs. If and only if the header is not already set, set a new header with the given value. Ignored if the header is already set.
- `config.replace.headers` - List of `headername:value` pairs. If and only if the header is already set, replace its old value with the new one. Ignored if the header is not already set.

The plugin first gets a list of the request headers and performs a removal action. If a header is marked for removal (`config.remove.headers`), then the header value is set to nil and that header is marked for removal at a later time.

Next, the same list of headers is checked for the `config.replace.headers` list. If a match is found, then the value of that header sent by the client is changed to match the value as per the config.

The final check for headers to add is now done on the same list of request headers. Only if the header from the `config.header.add` list does not exist in the request headers sent by the client is it added.

The last step performed is to remove the headers that were previously flagged for removal.

## Solution

In short, the parameters work as below:

- `config.remove.headers` - remove a header that the client sends before sending the request upstream
- `config.replace.headers` - change the value of an existing header sent by the client before sending the request upstream
- `config.add.headers` - if the client does not send a header, then add a header before sending the request upstream

If you wish to change the value of a header sent by the client, you can use the `config.replace.headers` configuration. Alternatively, combining `config.remove.headers` with `config.add.headers` also correctly overrides a client-sent header value, since the header is removed before the add step evaluates whether the header already exists.
