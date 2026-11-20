---
title: kong-harnesses support
description: Learn which kong-harnesses release Kong supports, and how to report a problem with a support report that doesn't hold a credential.

content_type: reference
layout: reference

tools:
  - kong-harnesses

tags:
  - support-policy

search_aliases:
  - kong-harnesses support policy
  - report a kong-harnesses problem

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/
---

## Supported releases

Kong supports the latest release of kong-harnesses. When a new release is out, it replaces the earlier ones, and Kong fixes problems only in new releases.

We recommend keeping kong-harnesses up to date. Print the release that you run:

```sh
kong-harnesses version
```

To update, use the same tool that you used to [install kong-harnesses](/kong-harnesses/).

## Report a problem

Before you report a problem, update to the latest release and check whether the problem is still there.

When a session still fails after you apply the fixes that [`doctor`](/kong-harnesses/doctor/) shows, write a support report:

```sh
kong-harnesses doctor --profile <profile> --report > report.json
```

To include a real model request through the {{ site.claude_code }} route, add `--inference`.

The report names the kong-harnesses release and the operating system, and the {{ site.claude_code }} release when the report covers {{ site.claude_code }}. It also lists the settings that each agent CLI acts on. The report doesn't hold an access token, a sign-in or a key: kong-harnesses replaces each value that can hold a credential with `<redacted>`, and it shows each URL as its scheme, host and port only. Read the report before you send it.

Open a ticket on the [Kong Support website](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
