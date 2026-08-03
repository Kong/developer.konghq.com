---
title: 'Kong Gateway: HTTP 404 `Corresponding path and method spec does not exist in API Specification` error when using the Mocking plugin'
content_type: support
published: false
description: The path in the route must match with the path mentioned in the API spec file.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I get the `Corresponding path and method spec does not exist in API Specification` error when using the Mocking plugin?
  a: |
    The Mocking plugin only serves paths that exist in the API spec file. The error means the request path on the route does not match a path defined in the spec.
    Align the route path with the path in the API spec so they match.
---

## Problem

Getting this error message while using the Mocking plugin: `Corresponding path and method spec does not exist in API Specification`. In older versions of Kong, we would see a different error message: `Path does not exist in API Specification`.

## Solution

The path in the route must match the path mentioned in the API spec file. If Kong is unable to find a matching path, then you encounter this issue. Compare the API spec path against the route path: if there is a mismatch, you encounter this error. Changing the path to match resolves this error message.
