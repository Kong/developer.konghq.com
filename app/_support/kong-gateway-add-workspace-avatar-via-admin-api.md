---
title: Add a workspace avatar via the Admin API
content_type: support
description: "Add a workspace avatar in Kong Gateway by base64-encoding an image and setting it via the workspace's `meta.thumbnail` field in the Admin API."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I add a workspace avatar via the Kong Gateway Admin API?
  a: |
    Base64-encode the avatar image, then `PATCH` the workspace's `meta.thumbnail` field via the Admin API using `multipart/form-data`. One quick way to get a base64 value is to upload the avatar in Kong Manager first and read it back from `GET /workspaces/<name>`.
---

## Problem

We are looking for a way to automate workspace creation including the workspace avatars/thumbnails. Is it possible to include the avatar in the Admin API? If so, how can we do this.

## Solution

It is possible to add a workspace avatar via the Admin API. We will need to base64 encode the image prior to calling the Admin API for workspaces.

One of the easier ways to do this is to add the image manually through Kong Manager and use the Admin API to gather the base64 encoded image.

There are other options outside of Kong but this is an internal option.

```bash
curl --request GET \
  --url http://localhost:8001/workspaces/default \
  --header 'kong-admin-token: <token>'
```

This will return a field called `meta.thumbnail` with the base64 encoded value.

```json
"meta": {
  "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAmCAYAAACCjRgBAAABTmlDQ1BJQ0MgUHJvZmlsZQAA...."
}
```

Once you have the base64 encoded image, you can use the Admin API to add the image in the future whenever needed.

```bash
curl --request PATCH \
  --url http://localhost:8001/workspaces/default \
  --header 'Content-Type: multipart/form-data' \
  --header 'kong-admin-token: <token>' \
  --form 'meta.thumbnail=data:image/png;base64,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'
```
