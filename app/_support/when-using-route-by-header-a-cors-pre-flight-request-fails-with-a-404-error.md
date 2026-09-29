---
title: When using Route By Header, a CORS pre-flight request fails with a 404 error
content_type: support
description: "A Route configured to match on a custom header using the `headers` field returns a 404 error for CORS pre-flight OPTIONS requests because the pre-flight request doesn't include the custom header."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does a CORS pre-flight request fail with a 404 error when using Route By Header?
  a: |
    The pre-flight OPTIONS request only carries an `Access-Control-Request-Header` header naming the custom header, not the header itself, so Kong's header-based route matching can't find a match and returns a 404. This is expected CORS behavior, not a Kong bug. Work around it by adding a separate Route on the same path that accepts only OPTIONS requests, to catch the pre-flight request.
related_resources:
  - text: route-by-header plugin documentation
    url: /plugins/route-by-header/
  - text: CORS plugin documentation
    url: /plugins/cors/
---

## Problem

When a Route has been setup to match on a custom header using the Route entity's native `headers` matching field, if a CORS pre-flight (OPTIONS) request is sent, then Kong responds with a 404 - "no Route matched with those values" response even when the Route methods includes the OPTIONS value

## Solution

When a CORS pre-flight OPTIONS request is sent, then this request contains an "Access-Control-Request-Header" header which specifies the headers that will be sent with "real" request (including details of the custom header). The pre-flight request does not contain the custom header itself as part of the request payload.

This means that Kong cannot route the request correctly as the request does not contain the header and you will see the 404 error. The 404 is caused by the Route entity's native `headers` matching field itself, not by the route-by-header plugin — any Route configured to match on a header will exhibit this behavior with CORS pre-flight requests, since the plugin only builds on top of that native matching field. This is a known limitation of CORS request and mentioned in the documentation.

This is not a Kong issue, but is due to the way CORS requests work. As the workaround a Route can be configured to catch the same path for the OPTIONS pre-flight request as would be used for the "real" request. This Route can be configured to only accept OPTIONS requests.
