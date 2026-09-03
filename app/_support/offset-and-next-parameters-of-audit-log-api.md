---
title: About offset and next parameters of Audit Log API
content_type: support
published: false
description: How to page through the {{site.base_gateway}} Audit Log API using the `offset` and `next` response parameters, and what to expect when there are no more records.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
faqs:
  - q: How do I use the "offset" and "next" parameters with the Audit Log API?
    a: |
      By default, the audit API returns at most 100 items:

      ```bash
      curl "<kong>:8001/audit/requests" | jq .data | jq length
      100
      ```

      To get the next 100 items, use the `offset` parameter:

      ```bash
      # Check current offset and next parameters
      curl "<kong>:8001/audit/requests" | jq . | grep offset
        "next": "/audit/requests?offset=<offset1>&sort_by=request_timestamp&sort_desc=true",
        "offset": "<offset1>"

      # Get next 100 items with <offset1>
      curl "<kong>:8001/audit/requests?offset=<offset1>" | jq .
      ```

      The following request returns the 100 items after that:

      ```bash
      curl "<kong>:8001/audit/requests?offset=<offset1>" | jq .
        "next": "/audit/requests?offset=<offset2>&sort_by=request_timestamp&sort_desc=true",
        "offset": "<offset2>"

      curl "<kong>:8001/audit/requests?offset=<offset2>" | jq .
      ```

      By using `offset` recursively, you can get all the items.
  - q: What will the "next" and "offset" attributes be in the response if there are no more records?
    a: |
      `next` will be `null` and there is no `offset` in the response.
tldr:
  q: How do I paginate through the {{site.base_gateway}} Audit Log API using offset and next?
  a: |
    The Audit Log API returns up to 100 items per page. Use the `offset` value from the response's `next` field to fetch subsequent pages; when there are no more records, `next` is `null` and `offset` is absent.
---

## About offset and next parameters of Audit Log API
