---
title: Old data plane entries are not getting removed from clustering data-plane endpoint
content_type: support
description: This is because Kong keeps data plane entries for 14 days by default.
products:
  - gateway
works_on:
  - on-prem
  - konnect
published: false
related_resources:
  - text: the `cluster_data_plane_purge_delay` configuration reference
    url: /gateway/configuration/#cluster-data-plane-purge-delay
tldr:
  q: Why does the `/clustering/data-planes` API endpoint return more data planes than there are active pods?
  a: |
    Kong keeps data plane entries for 14 days by default, so a control plane that hasn't heard from a data plane within that window still lists it. Lower `cluster_data_plane_purge_delay` to shorten the retention window.
---

## Old data plane entries are not getting removed from clustering data-plane endpoint

Why does the `/clustering/data-planes` API endpoint return more data planes than there are actual working pods?

This is because Kong keeps data plane entries for 14 days by default. If the CP hasn't heard from a DP for 14 days, its entry will be removed.

If users want to shorten this time, they can set the time via the `cluster_data_plane_purge_delay` Kong parameter.

If users deploy Kong with a Helm chart, they need to add this under `env`

```yaml
env:
  cluster_data_plane_purge_delay: "<time>"
```
