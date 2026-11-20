---
title: kong-harnesses support
description: Check which kong-harnesses release you run, keep it up to date, and report a problem to Kong Support with a doctor report.

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

## kong-harnesses versions

Kong fixes problems in new releases of kong-harnesses. We recommend keeping kong-harnesses up to date.

Print the release that you run:

```sh
kong-harnesses version
```

To update, install the new release the same way that you [installed kong-harnesses](/kong-harnesses/).

## Report a problem

Before you report a problem, update to the latest release and check whether the problem is still there.

When a session still fails after you apply the fixes that [`doctor`](/kong-harnesses/doctor/) shows, write a support report:

```sh
kong-harnesses doctor --profile <profile> --report > report.json
```

To include a real model request, add `--inference`. kong-harnesses sends the request on the {{ site.claude_code }} route, so the profile must set up {{ site.claude_code }}. The request costs the same as any other model request.

The report names the kong-harnesses release and the operating system. For {{ site.claude_code }}, it also names the {{ site.claude_code }} release and lists the settings and shell variables that {{ site.claude_code }} acts on. For each other agent CLI, it names the configuration file and whether that file exists. The report doesn't hold an access token, a refresh token or a key: kong-harnesses replaces each value that can hold a credential with `<redacted>`, and it shows each URL as its scheme, host and port only. Read the report before you send it.

Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
