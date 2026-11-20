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

Add `--inference` to test the {{ site.claude_code }} route with a model request. The request can cost money. If the selected profile doesn't configure {{ site.claude_code }}, `doctor` refuses `--inference` and doesn't write the report.

The report holds the `doctor` findings for each agent CLI, and names the kong-harnesses release, the operating system and the CPU architecture. For {{ site.claude_code }}, it also lists the settings and shell variables that {{ site.claude_code }} acts on, and names the {{ site.claude_code }} release when it can read it. For each other agent CLI, it names the configuration file that `doctor` finds, and whether that file exists.

The report shows a value only when the value can't hold a credential: an empty value, a switch value such as `1` or `false`, and a value that names a route, a model, a trust file or a limit. It replaces each other value with `<redacted>`, also the values of hooks, the status line and custom headers, because a command or a header can carry a token. It shows a gateway or proxy URL as its scheme, host and port only, and adds `/<redacted>` when the URL has a path after the host. Check the report for sensitive data before you send it.

Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
