---
title: How to create a catch-all route for unmatched paths
content_type: support
description: Describes how to configure a catch-all route with the Request Termination plugin to return a custom message for requests that don't match any other route.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I create a catch-all route for unmatched paths?
  a: |
    Create a route with path `/` and attach the Request Termination plugin to it. Configure the plugin to return the content type, status code, and message you want (for example, a 404 HTML page saying the requested path wasn't found) whenever a request doesn't match any other route.
related_resources: []
---

## Overview

How can unmatched routes be handled with a custom message?

## Steps

A route can be created along with the Request Termination plugin to generate a custom message for an unmatched route.

1. Create a new route with a path of `/`

2. Add a Request Termination plugin to the route. This can be configured to return any desired `content-type` & HTTP status code, but for this example it will return an HTML page with the message 'The requested path was not found.' and status code 404.

3. Request a non-existent path on your server to test
