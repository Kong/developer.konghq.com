---
title: Control Plane Reporting Status shows Data Planes that are no longer active
content_type: support
description: "The `data_plane` `last_seen` field can be used to determine the 'freshness' of the `data_plane` information."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does `/clustering/data-planes` still show `sync_status: normal` for a Data Plane that's been turned off?"
  a: |
    `sync_status` is written by the Data Plane the last time it successfully reported in, and isn't re-evaluated based on current reachability — a Data Plane that's gone silent just keeps showing its last reported status. Check the `last_seen` timestamp instead to gauge freshness; an unreachable Data Plane keeps proxying with its last-known config until `cluster_data_plane_purge_delay` (default 14 days) removes its entry.
related_resources: []
---

## Problem

When querying `/clustering/data-planes` on the Control Plane's Admin API, every Data Plane shows `"sync_status":"normal"` even when a given Data Plane has been turned off.

## Cause

The `last_seen` field on each `data_plane` entry can be used to determine the "freshness" of the `data_plane` information — `sync_status` itself is written by the Data Plane the last time it successfully reported to the Control Plane, and is not re-evaluated or flipped based on whether that Data Plane is still reachable. A Data Plane that has gone silent simply keeps showing whatever `sync_status` it last reported, alongside a `last_seen` timestamp that stops advancing.

If a `data_plane` stops reporting to the control plane it is still perfectly capable of continuing to proxy using its last good received configuration. A `data_plane` that does not report in will eventually be purged from the database table according to the configuration `cluster_data_plane_purge_delay`, which defaults to 14 days (1209600 seconds) on Kong Gateway 3.14.0.0.

The `data_planes` are designed to be resilient to loss of connection to the `control_plane`. The fact that a `data_plane` has not communicated with the control plane is not necessarily a problem.

## Solution

To get just the `data_planes` heard from within the last hour:

```bash

curl -s "http://localhost:8001/clustering/data-planes" -H "Kong-Admin-Token: password" | jq ".data[] | select(.last_seen > (now | floor) - 3600)"
```

which, on a current 3.14.0.0 Control Plane, returns an entry shaped like this (some fields — `cert_details`, `rpc_capabilities`, `labels` — did not exist in older Kong versions and have been added since):

```json

{
  "id": "520857cb-b5ee-4833-95e2-c02f4d500104",
  "hostname": "e000a45a39fc",
  "ip": "172.18.0.5",
  "version": "3.14.0.0",
  "last_seen": 1787814396,
  "updated_at": 1787814396,
  "ttl": 1209586,
  "config_hash": "4b5b286e7267a66d2b4fed6970847502",
  "sync_status": "normal",
  "labels": {},
  "rpc_capabilities": [],
  "cert_details": {
    "expiry_timestamp": 1827377031
  }
}
```

Note: the `version` field inside the JSON body reports a plain version string (e.g. `"3.14.0.0"`) with no `-enterprise-edition` suffix — that suffix only appears in HTTP `Server`/`Via` headers and `kong version` CLI output, never inside a JSON response body.

Or flip the comparison to find `data_planes` that are missing for more than an hour.

Alternatively, `cluster_data_plane_purge_delay` can be lowered, for example to 1 hour, so that unavailable DPs are not kept in the report for as long, providing a more up-to-date view of which DPs are actually connected.

As a demonstration, using docker-compose the following can be set to a very low value, e.g. 10 seconds, on the Control Plane's config:

```yaml

KONG_CLUSTER_DATA_PLANE_PURGE_DELAY: 10
```

With that set, stopping a Data Plane's container will show its entry continuing to appear in `/clustering/data-planes` — with an unchanging `last_seen`, a `sync_status` frozen at whatever it last reported (commonly `"normal"`), and a `ttl` counting down — for up to 10 seconds after the container stops, after which the entry disappears from `data: []` entirely. Starting the container again causes it to reappear (with a new `id` and a fresh `last_seen`) the next time it successfully syncs with the Control Plane.
