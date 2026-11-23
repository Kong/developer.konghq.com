---
title: kong-harnesses support
description: Check your kong-harnesses version, update to the latest release, and generate a support report for Kong Support.

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
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

## kong-harnesses versions

We recommend keeping kong-harnesses up to date because Kong fixes problems in new releases.

Check which version of kong-harnesses you run:

```sh
kong-harnesses version
```

To update, install the new release the same way you [installed kong-harnesses](/kong-harnesses/).

## Report a problem

1. Update kong-harnesses to the latest release and check whether the problem still occurs.
2. Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) and apply the fixes it shows.
3. If the problem still occurs, generate a support report.
   Run the command from the directory where you start your agent CLI so `doctor` checks the same project settings files that your agent CLI reads:

   ```sh
   kong-harnesses doctor --profile PROFILE_NAME --report > report.json
   ```

   Replace `PROFILE_NAME` with your profile name, or omit `--profile PROFILE_NAME` to check your default profile.

   To also test the {{ site.claude_code }} route with one small model request, add `--inference`.
   The `--inference` flag works only when the selected profile configures {{ site.claude_code }}.
   For any other profile, `doctor` exits with an error without writing the report, which leaves `report.json` empty.

   {:.warning}
   > The model request that `--inference` sends through the gateway can cost money.
   > The request does not send local files or chat history.

4. Review `report.json` for sensitive data before you send it.
   See [What the support report contains](#what-the-support-report-contains) and [Redaction rules](#redaction-rules) for details.
5. Open a ticket on the [Kong Support portal](https://support.konghq.com/support/s/) and attach `report.json`.
   Describe what you did and what happened.

### What the support report contains

The support report contains the profile name and every `doctor` finding with its fix.
The findings cover both the profile and each agent CLI that `doctor` checks.
The report also includes the kong-harnesses version, operating system, and CPU architecture of the build.
When the report covers {{ site.claude_code }}, the report includes the {{ site.claude_code }} version from `claude --version`.
The report records each part that `doctor` can't read, such as the {{ site.claude_code }} version, under `unavailable`.

For {{ site.claude_code }}, the report lists the local settings sources that `doctor` checks, including sources that are absent or that `doctor` can't read:

* The managed settings files (`managed-settings.json` and files in `managed-settings.d`)
* The {{ site.claude_code }} managed preferences on macOS
* The {{ site.claude_code }} policy keys in the Windows registry
* The project `.claude/settings.json` and `.claude/settings.local.json` files
* The user `settings.json` file

The report includes each setting value that `doctor` resolves across the local settings sources, after applying the [redaction rules](#redaction-rules).
The report also includes {{ site.claude_code }} shell variables that are set for routing, models, certificates, and credentials.
Examples include `ANTHROPIC_BASE_URL`, `HTTPS_PROXY`, and `ANTHROPIC_CUSTOM_HEADERS`, with sensitive values redacted.
The report ignores unrelated shell variables.
If the user settings file exists but `doctor` can't read or parse it, the report omits resolved setting values.
The report still lists the settings sources and shell variables, and records the failure under `unavailable`.
The report doesn't include settings that {{ site.claude_code }} gets from a server, or Windows managed settings when {{ site.claude_code }} runs in Windows Subsystem for Linux (WSL).

For other supported agent CLIs (`codex`, `opencode`, `omp`, `hermes`, and `pi`), the report records whether the configuration file exists and includes its path when `doctor` can determine the path.

### Redaction rules

The support report shows a value only when the value can't contain a credential.
For every other value, the report keeps the setting or variable name and replaces the value with `<redacted>`.
Environment variable rules apply to variables in both the {{ site.claude_code }} `env` settings and the shell.

{% table %}
columns:
  - title: Data category
    key: category
  - title: What appears in `report.json`
    key: behavior
rows:
  - category: Allowed {{ site.claude_code }} top-level settings
    behavior: |
      Full value for:

      * `model`
      * `availableModels`
      * `modelPicker`
      * `modelOverrides`
      * `skipWebFetchPreflight`
      * `autoUpdates`
  - category: "`apiKeyHelper`"
    behavior: |
      Full command only when the value matches the command that kong-harnesses wrote.
      Otherwise `<redacted>`.
  - category: Other {{ site.claude_code }} top-level settings, except `env`
    behavior: |
      `<redacted>`, including `hooks` and `statusLine`, because commands can contain tokens.
  - category: Empty or switch environment variables
    behavior: |
      Full value when empty or equal to `0`, `1`, `true`, `false`, `yes`, `no`, `on`, or `off` in any letter case.
  - category: Provider base URLs and proxy URLs (`HTTP_PROXY`, `HTTPS_PROXY`, `http_proxy`, and `https_proxy`)
    behavior: |
      Scheme, host, and port only.
      Removes any username, password, query string, or fragment.
      Appends `/<redacted>` only if the URL has a path other than `/`.
      For a value without a scheme, keeps the host only when the host includes a port or a dot (for example, `proxy.example.com:3128`), and replaces any other value with `<redacted>`.
  - category: "`NO_PROXY` and `no_proxy`"
    behavior: Full value.
  - category: Other allowlisted environment variables
    behavior: |
      Full value.
      See [Allowlisted environment variables](#allowlisted-environment-variables).
  - category: Other collected environment variables
    behavior: |
      `<redacted>`, including credentials, `ANTHROPIC_CUSTOM_HEADERS`, and `CLAUDE_CODE_CLIENT_KEY_PASSPHRASE`.
{% endtable %}

#### Allowlisted environment variables

The support report allowlist includes the following environment variables, subject to the URL rules for provider base URLs and proxy URLs:

* Provider base URLs
* Provider project ID, region, and workspace ID
* Model and auto mode variables
* `ANTHROPIC_BETAS`
* Token limits
* Prompt cache and API key helper time-to-live (TTL) variables
* `ENABLE_TOOL_SEARCH`
* Certificate store and TLS file path variables (`CLAUDE_CODE_CERT_STORE`, `CLAUDE_CODE_CLIENT_CERT`, `CLAUDE_CODE_CLIENT_KEY`, and `NODE_EXTRA_CA_CERTS`)
* Proxy variables (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, `http_proxy`, `https_proxy`, and `no_proxy`)
* `CLAUDE_CONFIG_DIR`
* `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`
* Internal kong-harnesses metadata variables (`KONG_HARNESSES_FLEET_BUILD`, `KONG_HARNESSES_FLEET_PRICING`, `AGENT_AUTH_CLI_FLEET_BUILD`, and `AGENT_AUTH_CLI_FLEET_PRICING`)

#### Unredacted metadata

The support report keeps the following metadata unredacted:

* Name of each included setting and environment variable
* Profile name
* Path of each settings source
* Full text of each `doctor` finding and fix, which can include:
  * Gateway host and identity provider host
  * Model names
  * Callback URI
  * Other profile names
  * Settings file paths

File paths in findings, settings sources, `apiKeyHelper`, and path environment variables can contain your username.

## Report a security vulnerability

{% include_cached /support/vulnerability-reporting.md %}
