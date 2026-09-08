---
title: How to get a list of specs using the files API
content_type: support
description: "Use the files API with `jq` to list all spec files, since the `/specs` endpoint only returns a single `.yaml` or `.json` file."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I get a list of specs using the files API?
  a: |
    The `/specs` API only returns a single spec file (`.yaml` or `.json`), so list specs by querying the files API and filtering its output with `jq` — for example piping through `grep spec` or `egrep ^spec` to match paths under `specs/`. Note: on-premises Dev Portal API routes are gated behind a separate license entitlement as of Kong Gateway 3.11.0.0, so a 404 there may mean Dev Portal isn't enabled on your license.
---

## Overview

How do you get the list of specs using the files API?

## Steps

> **Note:** As of Kong Gateway 3.11.0.0 (and unchanged through 3.14.0.0), the on-premises Developer Portal and its Admin API routes (`/specs`, `/files`, etc.) are gated behind an additional, undocumented license entitlement that a standard Enterprise license does not include. On a standard license, requests to these routes return a flat `404 {"message":"Not Found"}` regardless of workspace `portal` config. If you hit a 404 following the steps below, contact Kong Support to confirm whether Dev Portal is enabled on your license.

Since you cannot utilize `/specs` as a whole (it will only allow one specific file ending in `.yaml` or `.json`), you will have to leverage the files API instead. The files API will output everything, so you will have to alter it to get specifically what you need - specs in this case. Using `jq`, you can follow the example commands below:

```bash
curl -s -k http://<kongurl>:<port>/default/files/ | jq -r -M '.data[] | .path' | grep spec
themes/base/layouts/system/spec-renderer.html
specs/petstore.yaml
specs/httpbin.json
```

Then to pull files that only start with spec:

```bash
curl -s -k http://<kongurl>:<port>/default/files/ | jq -r -M '.data[] | .path' | egrep ^spec
specs/petstore.yaml
specs/httpbin.json
```
