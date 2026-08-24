---
title: "Kong Konnect: How to publish/unpublish an API Product using the Admin API"
content_type: support
description: Publish or unpublish an API Product without specifying a version by using the Konnect Admin API's v2 API Products endpoint.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I publish or unpublish an API Product using the Admin API instead of the UI?
  a: |
    Use the Admin API's `v2/api-products/` endpoint (`PATCH /v2/api-products/<APIProductID>`) instead of the UI.
    Send `portal_ids` with a portal ID to publish an API Product to the Developer Portal, or send an empty `portal_ids` array to unpublish it.
    The v2 endpoint is now Legacy — new integrations should use the Konnect API Catalog's v3 publications endpoint instead.
related_resources:
  - text: API Products update-api-product reference
    url: /api/konnect/api-products/v2/#/API%20Products/update-api-product
---

## Problem

We are looking for a way to publish/unpublish an API Product without specifying a version. This is possible from the UI, but there doesn't seem to be a way to do it via the Admin API. For example, how can we automate this process using the Admin API?

## Solution

It is possible to do from the Admin API as well. To do this we can use the `v2/api-products/` endpoint.

Note: the v2 API Products endpoint still works but is now marked Legacy, superseded by the Konnect API Catalog's v3 publications endpoint. New integrations should target the v3 API Catalog publications endpoint instead of v2 API Products.

To add the API Product object to Developer Portal we can use the following command:

```bash

curl --request PATCH \
--url 'https://us.api.konghq.com/v2/api-products/<APIProductID>' \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Authorization: Bearer kpat...' \
--data '{"portal_ids":["<portal_id>"]}'
```

To remove it, we just need to remove the portal IDs from the command above.

Ex:

```bash

curl --request PATCH \
--url 'https://us.api.konghq.com/v2/api-products/<APIProductID>' \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Authorization: Bearer kpat...' \
--data '{"portal_ids":[]}'
```
