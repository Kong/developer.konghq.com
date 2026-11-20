---
title: kong-harnesses support
description: Check which kong-harnesses release you run, keep it up to date, and report a problem to Kong Support with a support report.

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

The report contains the `doctor` findings for each agent CLI that `doctor` checks. It names the kong-harnesses release, and the operating system and CPU architecture that the kong-harnesses build is for. For {{ site.claude_code }}, the report lists the local settings sources that `doctor` checks, including a source that is absent or that `doctor` can't read. These sources are the managed settings files, the managed preferences on macOS, the registry on Windows, the project `settings.json` and `settings.local.json` files, and the user `settings.json` file. The report shows the setting values that `doctor` resolves across these sources. If the user settings file exists but `doctor` can't read or parse it, the report omits all resolved values. It also lists selected shell variables that are set, such as `ANTHROPIC_BASE_URL`, `HTTPS_PROXY` and `ANTHROPIC_CUSTOM_HEADERS`. It names the {{ site.claude_code }} release when `doctor` can read it. The report doesn't include the settings that {{ site.claude_code }} gets from a server.

For each other agent CLI, the report names the configuration file path for that CLI when `doctor` can determine the path, and whether that file exists.

The report uses these redaction rules, and shows each redacted value as `<redacted>`:

* Of the top-level settings, the report shows `model`, `availableModels`, `modelPicker`, `modelOverrides`, `skipWebFetchPreflight` and `autoUpdates`. It shows `apiKeyHelper` only when the value is the command that kong-harnesses wrote. It checks each variable in `env` with the rules for environment variables. It redacts every other setting, such as hooks and the status line, because a command can contain a token.
* For an environment variable in the `env` settings or in the shell, the report shows an empty value and a switch value: `0`, `1`, `true`, `false`, `yes`, `no`, `on` or `off`, in any case. For other values, the report shows the values of the variables on the allowlist, with the URL rules in the next item. The allowlist has the provider base URLs, the provider project ID, region and workspace ID, the model and auto mode variables, `ANTHROPIC_BETAS`, the token limits, the cache and API key helper times, `ENABLE_TOOL_SEARCH`, the certificate store, certificate file and key file variables, the proxy variables, `CLAUDE_CONFIG_DIR`, and the kong-harnesses fleet build and pricing variables. For any other variable value that it collects, such as a custom header or a credential, the report shows `<redacted>`.
* For the provider base URLs and for `HTTP_PROXY`, `HTTPS_PROXY`, `http_proxy` and `https_proxy`, the report shows only the scheme, the host and the port. It adds `/<redacted>` only if the URL has a path other than the root. It redacts a value that doesn't look like a host. It shows `NO_PROXY` and `no_proxy` in full.

The report keeps the name of each setting and variable that it includes, the path of each settings source, which can contain your user name, and the profile name.

Check the report for sensitive data before you send it.

Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

To report a security problem, follow the [Kong vulnerability patching process](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
