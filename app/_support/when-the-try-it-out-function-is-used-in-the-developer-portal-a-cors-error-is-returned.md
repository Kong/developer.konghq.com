---
title: "When the \"Try It Out\" function is used in the Developer Portal a CORS error is returned"
content_type: support
description: The Developer Portal's "Try It Out" feature sends a CORS preflight request that other clients like curl or Insomnia don't, so a CORS error appears unless a CORS plugin is added to the Route to provide the required Access-Control headers.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the Developer Portal's "Try It Out" function return a CORS error?
  a: |
    The Developer Portal's "Try It Out" feature sends a CORS preflight `OPTIONS` request that clients like curl or Insomnia skip, so the browser blocks the response unless a CORS plugin is added to the Route to supply the `Access-Control-*` headers and allow the `OPTIONS` method.
related_resources:
  - text: CORS plugin documentation
    url: "/plugins/cors/"
---

## Problem

After an Open API Spec file has been loaded to the Developer Portal and the "Try It Out" functionality is used, a CORS error is returned in the browser;

```
Server response

 	TypeError: Failed to fetch
```

The same API works fine when using a different client such as curl or Insomnia.

Inside the browsers developer tools under "Console" you can see the CORS preflight error.

Error:

```
"Access to fetch at '<KONGHOSTNAME>:<KONGPROXY-PORT>/dadjokes' from origin '<KONGDEVPORTAL-HOST>:8003' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. If an opaque response serves your needs, set the request's mode to 'no-cors' to fetch the resource with CORS disabled."
```

## Cause

CORS is a method of preventing browsers from running scripts from untrusted hosts which can be a security problem. When requests are made from a browser, there is a CORS pre-flight request sent first, with an `OPTIONS` method, the response to this pre-flight request tells the browser which hosts are trusted via an `Origin` header, along with other CORS headers such as allowed HTTP methods, etc. These are the `Access-Control-*` headers. Tools such as curl or Insomnia do not run any scripts and so do not send a CORS pre-flight request before the main HTTP request.

## Solution

To resolve this issue, you need to add a CORS plugin to the Route. This can be configured to respond to the pre-flight request and provide the necessary Access-Control headers for the browser. Please also verify the Route allows the `OPTIONS` http method. If `Methods` is blank on the route, all methods can be used and `OPTIONS` does not have to be specified.
