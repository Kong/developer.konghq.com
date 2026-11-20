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

The report holds the `doctor` findings for each agent CLI that `doctor` checks. It names the kong-harnesses release, the operating system and the CPU architecture. For {{ site.claude_code }}, it lists the settings from the local settings files that `doctor` can read, and the shell variables that set the route, model, trust and credential of {{ site.claude_code }}. It also names the {{ site.claude_code }} release when `doctor` can read it. The report doesn't include the settings that {{ site.claude_code }} gets from a server. For each other agent CLI, the report names the configuration file that `doctor` finds, and whether that file exists.

The report replaces each value that can hold a credential with `<redacted>`:

* Of the top-level settings, the report shows `model`, `availableModels`, `modelPicker`, `modelOverrides`, `skipWebFetchPreflight` and `autoUpdates`. It shows `apiKeyHelper` only when the value is the command that kong-harnesses wrote. It redacts every other setting, such as hooks and the status line, because a command can carry a token.
* For an environment variable in the `env` settings or in the shell, the report shows an empty value and a switch value, such as `1`, `true` or `off`. It shows the value of a variable that names a route, a model, a trust file or a limit, such as `ANTHROPIC_BASE_URL` or `ANTHROPIC_MODEL`. It redacts every other value, such as custom headers and credential variables.
* For a variable that holds a gateway URL or a proxy, the report shows only the scheme, the host and the port. It adds `/<redacted>` only if the URL has a path other than the root. It redacts a value that doesn't look like a host.

Check the report for sensitive data before you send it.

Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
