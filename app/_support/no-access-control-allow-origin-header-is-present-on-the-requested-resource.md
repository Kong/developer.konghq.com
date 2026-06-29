---
title: "Why is no Access-Control-Allow-Origin header present on the response even though I configured the CORS plugin?"
content_type: support
description: "The CORS plugin omits the Access-Control-Allow-Origin header when config.origins contains an invalid character or when the request origin does not match a configured origin."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why is no Access-Control-Allow-Origin header present on the response even though I configured the CORS plugin?
  a: |
    The CORS plugin omits the `Access-Control-Allow-Origin` header for two main reasons. First,
    `config.origins` may contain an invalid character such as a leading or trailing space, quotes, or
    brackets; the field takes a simple comma-separated list and does not require brackets. Second, when
    multiple origins are configured, the plugin only returns the ACAO header if the request's Origin
    matches one of them. Review `config.origins`, remove invalid characters, and confirm the request's
    Origin matches a configured value.
related_resources: []
---

## Problem

When using the CORS plugin we see proxy requests being denied. When viewing the error in the browser developer tools an error similar to the below is found in the console:

```
Access to XMLHttpRequest at 'https://proxy/echo' from origin 'https://konghq.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

A value has been added to `config.origins` in the CORS plugin, but the header is not present on the response.

## Cause

This can occur for a couple of reasons:

1. The `config.origins` contains an invalid character. These can be as simple as a leading or trailing space character or adding quotes or brackets. As the field accepts a string array it is common to assume you need to use brackets, however the field does not require them and instead a simple comma separated list can be used.
2. You have configured several origins. When you specify more than one origin the plugin will only return the ACAO header if a match is found. For example, if you configured it as `config.origins=https://konghq.com,https://kuma.io`, generating a cross site request from an Origin of `https://mockbin.org` would return this error. If the same request was issued from `https://kuma.io` the header would be added as it matches one of the defined origins.

## Solution

Review the value of `config.origins` and remove any invalid characters such as leading or trailing spaces, quotes, or brackets, using a simple comma separated list. When configuring several origins, confirm that the request's Origin matches one of the configured values, since the plugin only returns the ACAO header on a match.
