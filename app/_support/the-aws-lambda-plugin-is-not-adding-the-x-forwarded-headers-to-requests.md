---
title: "The AWS Lambda plugin is not adding the `X-Forwarded-*` headers to requests"
content_type: support
description: These headers are added by the nginx proxy module when traffic traverses the Gateway.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't the AWS Lambda plugin add `X-Forwarded-*` headers to requests?
  a: |
    Nginx's proxy module normally adds `X-Forwarded-*` headers as traffic passes through {{site.base_gateway}}. The AWS Lambda plugin doesn't use that path — it calls the Lambda function directly using `lua-resty-http` as an HTTP client, so `X-Forwarded-*` headers are never added to the outbound request.
---

## Problem

When using the AWS Lambda plugin we noticed that the `X-Forwarded-*` headers are missing. Being as the Gateway is acting as a proxy, why are these not added?

## Solution

These headers are added by the nginx proxy module when traffic traverses the Gateway. However, when using the lambda plugin it does not follow this same path. The plugin instead uses `lua-resty-http` as an HTTP client to call the AWS Lambda function. As a result, none of the `X-Forwarded-*` headers will be added to these outbound requests.
