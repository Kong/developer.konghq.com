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

We recommend keeping kong-harnesses up to date because Kong fixes problems in new releases.

Check which kong-harnesses release you run:

```sh
kong-harnesses version
```

To update, install the new release the same way you [installed kong-harnesses](/kong-harnesses/).

## Report a problem

1. Update kong-harnesses to the latest release and check whether the problem still occurs.
2. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) and apply the fixes it shows.
3. If the session still fails, generate a support report.
   For {{ site.claude_code }}, run the command from the directory where you start {{ site.claude_code }} so `doctor` checks the project settings in that directory:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --report > report.json
   ```

   Replace `PROFILE_NAME` with your profile name, or omit `--profile PROFILE_NAME` to check your default profile.

   To also test the {{ site.claude_code }} route with a model request, add `--inference`.

   {:.warning}
   > The `--inference` flag sends a model request that can cost money.
   > If the selected profile does not configure {{ site.claude_code }}, `doctor` refuses `--inference` and does not write the report.

4. Review `report.json` for sensitive data before you send it.
   See [What the support report contains](#what-the-support-report-contains) and [Redaction rules](#redaction-rules) for details.
5. Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/), describe what you did and what happened, and attach `report.json`.

### What the support report contains

The support report contains the `doctor` findings for each agent CLI that `doctor` checks.
It also includes the kong-harnesses release, operating system, and CPU architecture of the build.

For {{ site.claude_code }}, the report lists the local settings sources that `doctor` checks, including a source that is absent or that `doctor` can't read:

* The managed settings files
* The managed preferences on macOS
* The registry on Windows
* The project `settings.json` and `settings.local.json` files
* The user `settings.json` file

The report names the {{ site.claude_code }} release when `doctor` can read it.

The report shows the setting values that `doctor` resolves across the local settings sources.
It also shows the selected shell variables that are set, such as `ANTHROPIC_BASE_URL`, `HTTPS_PROXY`, and `ANTHROPIC_CUSTOM_HEADERS`.
If the user settings file exists but `doctor` can't read or parse it, the report omits resolved setting values and still lists the sources and shell variables.
The report doesn't include settings that {{ site.claude_code }} gets from a server.

For each other agent CLI, the report records whether the configuration file exists and includes its path when `doctor` can determine the path.

### Redaction rules

The support report redacts values with the following rules.
A redacted value appears as `<redacted>`.

#### Top-level settings

For {{ site.claude_code }}, the support report shows the following top-level settings:

* `model`
* `availableModels`
* `modelPicker`
* `modelOverrides`
* `skipWebFetchPreflight`
* `autoUpdates`

The report shows `apiKeyHelper` only when the value is the command that kong-harnesses wrote.
It checks each variable in `env` with the [environment variable rules](#environment-variables).
It redacts every other setting, such as hooks and the status line, because a command can contain a token.

#### Environment variables

For an environment variable in the `env` settings or in the shell, the support report shows a value that is empty or a switch value: `0`, `1`, `true`, `false`, `yes`, `no`, `on`, or `off`, in any case.
The report also shows the value of a variable on the allowlist.
URL and proxy variables follow the [URL and proxy rules](#url-and-proxy-values).

The allowlist includes the following variables:

* The provider base URLs
* The provider project ID, region, and workspace ID
* The model and auto mode variables
* `ANTHROPIC_BETAS`
* The token limits
* The cache and API key helper times
* `ENABLE_TOOL_SEARCH`
* The certificate store, client certificate, client key, and extra CA certificate variables
* The proxy variables
* `CLAUDE_CONFIG_DIR`
* `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`
* The kong-harnesses fleet build and pricing variables

For any other variable value that the report collects, such as a custom header or a credential, the report shows `<redacted>`.

#### URL and proxy values

For the provider base URLs and for `HTTP_PROXY`, `HTTPS_PROXY`, `http_proxy`, and `https_proxy`, the support report shows only the scheme, host, and port.
It adds `/<redacted>` only if the URL has a path other than the root.
It redacts a value that doesn't look like a host.
It shows `NO_PROXY` and `no_proxy` in full.

#### Unredacted metadata

The support report keeps the following information unredacted:

* The name of each setting and variable that it includes
* The profile name
* The path of each settings source
* The full text of each `doctor` finding

A finding can name the gateway and a settings file path.
A path can contain your username.

## Report a security vulnerability

To report a security vulnerability in kong-harnesses, use [Kong's Responsible Disclosure Program](/gateway/vulnerabilities/#reporting-vulnerabilities-in-kong-code).
