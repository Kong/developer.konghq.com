---
title: "Kong Gateway init container stuck on \"wait for db\" when added to Kong Mesh"
content_type: support
description: "The Kong Gateway init container gets stuck on \"wait for db\" when added to Kong Mesh because the Kuma sidecar hasn't started yet and can't reach Postgres; adding a `traffic.kuma.io/exclude-outbound-ports-for-uids` annotation resolves it."
products:
  - gateway
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Kuma docs: DPP configuration on Kubernetes (init containers)"
    url: https://kuma.io/docs/2.5.x/production/dp-config/dpp-on-kubernetes/#init-containers
tldr:
  q: Why does the Kong Gateway init container get stuck on "wait for db" when adding it to Kong Mesh?
  a: |
    This happens because the Kuma sidecar hasn't started yet, so the init container can't reach the Postgres database until traffic exclusions are configured. Add a single `traffic.kuma.io/exclude-outbound-ports-for-uids` annotation (in `<protocol>:<port>:<uid>` format, e.g. `"udp:53:1000,tcp:5432:1000"`) to both the pod and migration pod annotations — the older split `exclude-outbound-tcp-ports-for-uids` / `exclude-outbound-udp-ports-for-uids` annotations have been removed from current Kuma/Kong Mesh.
---

## Problem

We have Kong Mesh currently deployed and we have data plane proxies deployed without issue. However, when we try to add Kong Gateway to the mesh the init containers are stuck.

If I check the logs for the `wait-for-db` container I see the following:

```
Error: unexpected message during auth:
```

## Cause

This issue occurs due to the sidecar on the Kong Gateway not being started yet and the init containers can't communicate to the postgres databases. So the `wait-for-db` container never completes.

## Solution

A workaround for this would be to define an exception for the init containers.

(This documentation page has been reorganized since this article was written — the old `/production/init-containers/` path now redirects to the page linked in related resources below, under "DPP configuration on Kubernetes." The annotation names and syntax below are confirmed unchanged on the current doc.)

You need to define 2 exclusions.

**The separate `traffic.kuma.io/exclude-outbound-udp-ports-for-uids` and `traffic.kuma.io/exclude-outbound-tcp-ports-for-uids` annotations shown below in the original version of this article have been removed from Kuma/Kong Mesh** (confirmed via `kumahq/kuma`'s own `UPGRADE.md`, "Upgrade to `2.9.x`" section: "The annotations `traffic.kuma.io/exclude-outbound-tcp-ports-for-uids` and `traffic.kuma.io/exclude-outbound-udp-ports-for-uids` have also been removed. Use the annotation `traffic.kuma.io/exclude-outbound-ports-for-uids` instead."). Kong Mesh's current 2.14.x line is well past this removal, so those two annotation names no longer have any effect. The correct current form is a single, consolidated annotation per exclusion, in `<protocol>:<port>:<uid>` format:

On your values file you can add the following:

```yaml
podAnnotations:
   traffic.kuma.io/exclude-outbound-ports-for-uids: "udp:53:1000,tcp:5432:1000"
```

The format is `<protocol>:<port>:<uid>`, comma-separated for multiple exclusions. By default the UID is 1000 for the kong user. Please adjust accordingly if necessary.

The ports are the default ports for TCP/UDP for Postgres.

You may also need to add this for your migration pods.

To do so, you can use the following:

```yaml
migrations:
  preUpgrade: true
  postUpgrade: true
  annotations:
    traffic.kuma.io/exclude-outbound-ports-for-uids: "udp:53:1000,tcp:5432:1000"
```
