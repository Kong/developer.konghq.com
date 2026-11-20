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
kong-harnesses doctor --profile work --report > report.json
```

Replace `work` with your profile name.

To include a real model request, add `--inference`. kong-harnesses sends the request on the {{ site.claude_code }} route, and the request costs the same as any other model request. If the profile doesn't set up {{ site.claude_code }}, `doctor` refuses `--inference` and doesn't write the report.

The report names the kong-harnesses release and the operating system. For {{ site.claude_code }}, it also lists the settings and shell variables that {{ site.claude_code }} acts on, and names the {{ site.claude_code }} release when it can read it. For each other agent CLI, it names the configuration file and whether that file exists.

The report replaces credential values, such as access tokens and keys, with `<redacted>`. In gateway and proxy URLs, it keeps only the scheme, host and port, and replaces a path with `/<redacted>`. Check the report for sensitive data before you send it.

Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
