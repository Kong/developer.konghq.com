---
title: "\"Configuration does not fit in LMDB database\" Error"
content_type: support
description: Pushing configuration to data planes fails with an HTTP 413 "Configuration does not fit in LMDB database" error; raise lmdb_map_size to fix it.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do configurations fail to push to data planes with an HTTP 413 \"Configuration does not fit in LMDB database\" error?"
  a: |
    The default LMDB size is `128m`, and configurations that exceed it fail to get pushed to data
    planes. Increase the size by raising `lmdb_map_size` (for example, `KONG_LMDB_MAP_SIZE=256m`,
    or `lmdb_map_size: "256m"` on Kubernetes, along with a larger `prefixDir` `sizeLimit`).
related_resources: []
---

## Problem

We see the following error in our Kong logs:

```
time="2023-01-31T11:12:33Z" level=error msg="could not update kong admin" error="posting new config to /config: HTTP status 413 (message: \"Configuration does not fit in LMDB database, consider raising the \\\"lmdb_map_size\\\" config for Kong\")" subsystem=dataplane-synchronizer
```

We see configurations failing to get pushed to our data planes.

## Solution

The default size of the LMDB is 128m. To increase the size, we need to make the following changes to our configuration.

General:

```bash
KONG_LMDB_MAP_SIZE=256m
```

Kubernetes:

```yaml
env:
  lmdb_map_size: "256m"
```

```yaml
deployment:
  prefixDir:
    sizeLimit: 1Gi
```
