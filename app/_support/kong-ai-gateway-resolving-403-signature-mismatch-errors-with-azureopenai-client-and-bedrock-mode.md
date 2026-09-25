---
title: "Kong AI Gateway: Resolving 403 Signature Mismatch Errors with `AzureOpenAI` Client and Bedrock Mode"
content_type: support
description: "Kong AI Gateway returns a 403 signature mismatch error when using the `AzureOpenAI` client to access Bedrock models, caused by the `api_version` query parameter breaking AWS signature verification."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong AI Gateway return a 403 "signature mismatch" error when using the `AzureOpenAI` client in Bedrock mode?
  a: |
    The `AzureOpenAI` SDK client always appends an `api_version` query parameter, which breaks AWS signature verification when the request is routed to a non-Azure provider like Bedrock. Set `api_version=""` when constructing the `AzureOpenAI` client so the SDK does not append the parameter, and the request signs and verifies correctly.
related_resources: []
---

## Problem

When using the `AzureOpenAI` client from the OpenAI Python SDK to access Bedrock models through a Kong AI Gateway, you may encounter the following error:

```
403 Forbidden – The request signature calculated does not match the signature you provided.
```

## Cause

This typically occurs due to the inclusion of the `api_version` query parameter in the request URL, which interferes with AWS signature verification.

The `AzureOpenAI` client requires the `api_version` parameter, but when this parameter is present in requests routed to non-Azure providers like Bedrock, it breaks the AWS signature verification process used by Kong.

## Solution

To resolve this issue:

1. Set the `api_version` parameter to an empty string when configuring the `AzureOpenAI` client. While the field is mandatory in the SDK, setting it to `""` allows the request to be signed and verified correctly.
2. This workaround ensures that the SDK does not append the `api_version` as a query parameter, preventing signature verification errors.

For example

```python
client = AzureOpenAI(
    api_version="", 
    azure_endpoint=endpoint,
    api_key="mykey",  
)
```
