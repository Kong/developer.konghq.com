---
title: How to get Data Plane Status information
content_type: support
description: "How to check a Control Plane's Data Plane status in Kong Konnect, and why to use the documented PAT-based Konnect API instead of an internal session-cookie endpoint."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: generating a PAT
    url: /konnect-platform/authentication/
  - text: the official Konnect API reference
    url: /api/
tldr:
  q: How do I get the Data Plane status in Kong Konnect?
  a: |
    Kong Konnect doesn't document a public API path for Data Plane status; the endpoint shown here (`.../clustering/data-planes?count_dp=true`) is an internal, UI-backing route authenticated with a session cookie, and can change without notice. Also, `konnect.konghq.com` no longer resolves — Konnect's UI is now at `cloud.konghq.com`. Prefer authenticating to the documented Konnect API with a Personal Access Token (PAT) and confirm the current Data Plane status path there instead of relying on the internal endpoint.
---

## Overview

How to get the Data Plane status in Kong Konnect?

## Steps

You can use the following command to get the status of a Data Plane

```bash
curl 'https://konnect.konghq.com/api/control_planes/{id}/default/clustering/data-planes?count_dp=true' -H 'cookie: {cookie-value}'
```

Note: the command above (extracting a session cookie from an authenticated browser tab) uses an internal, UI-backing endpoint that is not part of Konnect's officially documented, supported API. As of this writing, the documented and recommended way to authenticate to the Konnect API is a Personal Access Token (PAT) sent as a Bearer token against the regional API host, e.g. `https://us.api.konghq.com/v2/control-planes/{control_plane_id}/...` (see generating a PAT). Confirm the exact current path for listing/counting a Control Plane's Data Planes against the official Konnect API reference before relying on the internal endpoint shown above, since undocumented internal endpoints can change without notice.

The docs link this article previously pointed to for generating a session cookie (`/konnect/reference/konnect-api/#make-a-request-with-the-session-cookie`) no longer resolves to that content — it now redirects to the general Konnect docs landing page (/konnect/) rather than an equivalent session-cookie how-to.

> **Additionally confirmed live:** the `konnect.konghq.com` domain itself no longer resolves at all (DNS lookup failure) — Konnect's UI has moved to `cloud.konghq.com`. Both occurrences of `konnect.konghq.com` in this article (the internal endpoint's host and the runtime-manager URL below) are dead as literally written; substitute `cloud.konghq.com` for the current UI, though the internal endpoint's continued existence/path at the new domain was not confirmed (all the more reason to use the documented PAT-based API above instead).

Your `{ID}` can be obtained from the runtime manager url which is in the format

```
https://cloud.konghq.com/runtime-manager/{id}
```
