---
title: "Kong Gateway: Prompting for credentials to pass upstream"
content_type: support
description: Use the Request Termination and Response Transformer Advanced plugins across two routes for the same path to prompt the browser for Basic Auth credentials and pass them upstream without validation.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I get the browser to prompt for Basic Auth credentials and pass them upstream without Kong validating them?
  a: |
    Use the Request Termination plugin (`config.status_code = 401`) and Response Transformer Advanced plugin (`config.add.headers = WWW-Authenticate:basic`) on a route matching the path without an `Authorization` header, which triggers the browser's login prompt.
    Add a second route matching the same path but requiring the `Authorization` header, so both the initial credential-carrying request and the browser's follow-up request are proxied upstream once credentials are supplied.
---

## Problem

We would like to allow the Gateway to collect basic auth credentials in the browser and pass them to an upstream without validating. The goal is to have the browser prompt for credentials if a basic auth header is missing. If the header is present it should never prompt and continue upstream. The basic auth plugin provides similar functionality, but must be tied to a consumer. How can this be achieved?

## Solution

This can be accomplished through the use of two plugins, the Request Termination Plugin and the Response Transformer Advanced. To configure this you will need to define two routes for the same path. In this example, the path will be `/auth`.

Route 1: This route will be used to collect credentials in the absence of a basic authorization header. We will define the route simply with `path: /auth`. We will then add our plugins to this route.

- Request Termination: `config.status_code = 401`
- Response Transformer Advanced: `config.add.headers = WWW-Authenticate:basic`

Setting the HTTP status code to 401 will indicate that the request is unauthorized. By also including the `WWW-Authenticate` header it will cause browsers to prompt for authentication. When credentials are provided the browser automatically sends the request back to the requested endpoint and this will now include a basic auth header.

To accommodate for this, we set up the 2nd route.

Route 2: This route will match the same path but will also look to match on the presence of an `Authorization` header. It will serve two purposes:

1. To accept credentials when the consuming app already provided them
2. To capture the 2nd request from the browser once credentials are provided

- `path: /auth`
- `Headers: Authorization: ~*basic\s+([A-Za-z0-9]+=*)`
