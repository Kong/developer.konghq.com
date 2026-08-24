---
title: The `clustering/data-planes` endpoint is limited to showing only 100 entries
content_type: support
description: As with other endpoints, the data-planes endpoint supports query parameters to increase or limit the size.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I increase the number of entries returned by the `clustering/data-planes` endpoint beyond the default 100?
  a: |
    The `/clustering/data-planes` endpoint supports the same `size` and `offset` query parameters as other Admin API endpoints. Append `?size=N` to increase the page size, and use a base64-encoded `offset` array (containing the last-seen entry's ID) to paginate beyond a single page.
---

## Problem

When viewing the `clustering/data-planes` endpoint in Hybrid mode, an active DP cannot be found because the endpoint limits the view to 100 entries.

## Solution

As with other endpoints, the data-planes endpoint supports query parameters to increase or limit the size. You can simply append the parameter `size=N`, where N is the number of entries you would like returned.

For example, to return 200 entries:

```bash
curl -S http://localhost:8001/clustering/data-planes?size=200
```

An `offset` parameter can also be used for pagination purposes, but requires a base64 encoded JSON array.

Note, this is not inclusive of the `offset` value.

For example:

You have two entries  (shortened for readability)

```

1
version	"3.14.0.0"
id		"fd9baea4-65dd-4312-8b8d-915b38bcad7e"

2
version	"3.14.0.0"
id		"ffc6b3b4-240e-4796-8072-112e01eb56b1"
```

If you want to retrieve the data planes starting with entry 2 (id `ffc6b3b4-240e-4796-8072-112e01eb56b1`), you would set the `offset` to the ID of entry 1

```bash
OFFSET=$(echo '["fd9baea4-65dd-4312-8b8d-915b38bcad7e"]' | base64)

curl -s http://localhost:8001/clustering/data-planes?offset=$OFFSET
```
