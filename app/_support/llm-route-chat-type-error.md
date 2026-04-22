---
title: Resolving the "LLM route only supports llm chat type requests" error
content_type: support
description: How to fix the "LLM route only supports llm chat type requests" error by sending the correct Content-Type header to {{site.base_gateway}}.
products:
  - gateway
  - ai-gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I resolve the "LLM route only supports llm chat type requests" error?
  a: |
    Add the required `Content-Type: application/json` header so that {{site.base_gateway}} can correctly interpret the payload format.
---

## Sending the correct Content-Type header

This error occurs when sending an incorrect content-type header to {{site.base_gateway}}. Some utilities, such as `curl`, default to using `Content-Type: application/x-www-form-urlencoded`. To address the issue, ensure you are sending the header as `Content-Type: application/json`.

```bash
curl -X POST https://mygateway/api/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "Why is the sky blue?"
      }
    ]
  }'
```
