---
title: Troubleshoot kong-harnesses
description: Run kong-harnesses doctor and find the next step for each check in its report.

content_type: reference
layout: reference

tools:
  - kong-harnesses

tags:
  - ai
  - cli
  - troubleshooting

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: kong-harnesses support
    url: /kong-harnesses/support/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

When an agent CLI, such as {{ site.claude_code }}, can't reach {{ site.ai_gateway }} through kong-harnesses, run [`kong-harnesses doctor`](/kong-harnesses/doctor/) to find the cause.
The `doctor` command checks the profile, the sign-in, the agent CLI settings, and the gateway, and it doesn't change any settings.
For most problems, the report also shows the next step.

## Run doctor

Run `doctor` in the shell and folder where you start the agent CLI, because some checks read the variables of that shell and the project settings in that folder:

```sh
kong-harnesses doctor --profile PROFILE_NAME --client CLIENT_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile, and `CLIENT_NAME` with the agent CLI to check, such as `claude-code`.
To check the only installed profile or the default profile, omit `--profile`.
To check every agent CLI that the profile configures, omit `--client`.

## Read the report

Each finding starts with a level (`ok`, `warn`, or `fail`) and the name of the check.
When `doctor` knows the next step for a problem, a `fix:` line under the finding names it:

```text
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

Do the steps on the `fix:` line in order, and run each command as the line shows it.
Keep the `--client` flag in a command that has one, so that a command such as [`profile cleanup`](/kong-harnesses/profile/cleanup/) changes only that agent CLI.
Then run `doctor` again.

## What each check means

A report includes only the checks that apply to the profile and the agent CLI.
The following table explains each check and what to do when it fails.
The `fix:` line takes priority over this table.

{% table %}
columns:
  - title: Check
    key: check
  - title: What it checks
    key: what
  - title: When it fails
    key: next
rows:
  - check: "`install`"
    what: On Windows, only administrators can change the kong-harnesses program file.
    next: Ask your administrator to reinstall kong-harnesses with its MSI.
  - check: "`profile`"
    what: The profile is installed and readable.
    next: |
      Run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to see the installed profiles.
      If your profile is invalid, delete it with [`profile delete`](/kong-harnesses/profile/delete/) and import it again.
      If an administrator installed it, ask your administrator to reinstall it.
  - check: "`login`"
    what: You're signed in to the profile.
    next: |
      Run [`kong-harnesses login --profile PROFILE_NAME`](/kong-harnesses/login/).
      For a CI profile, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
  - check: "`client`"
    what: The agent CLI is set up for this profile, and its settings still match.
    next: |
      Do the `fix:` step, usually [`profile activate`](/kong-harnesses/profile/activate/) for your profile and agent CLI.
      If your organization's managed settings run another profile, run `doctor` with that profile.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: Update {{ site.claude_code }} to the release that the `fix:` line names, or to a newer release.
  {%- comment %}
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can read the gateway plugin package from the registry, and a working plugin version is in the OpenCode cache.
    next: |
      Fix the `npm` problem first, such as an npm token that doesn't work.
      Then do the step on the `fix:` line of `plugin`, such as removing an old cached plugin and starting OpenCode once.
  - check: "`provider`"
    what: |
      For OpenCode, the settings files don't replace, remove, or turn off the provider that the gateway plugin registers, and don't send the provider to another URL.
      The check also makes sure that OpenCode reads the settings file where activation wrote the gateway plugin entry.
      The `provider` check appears only when it finds a problem.
    next: |
      Do the step on the `fix:` line, such as removing a provider, base URL, or plugin entry from the settings file that the report names, then run `doctor` again.
      When the `fix:` line says to run `profile cleanup`, use the following steps for the cleanup and the activation.
      Do the other steps on the `fix:` line as the line names them.

      1. If the `fix:` line names a variable for the cleanup step, open a shell without that variable.
      1. Run `kong-harnesses --client opencode profile cleanup`.
         Keep `--client opencode`, because `profile cleanup` without `--client` cleans up every agent CLI.
      1. Open the shell that starts OpenCode.
         If the `fix:` line names `OPENCODE_CONFIG_DIR` for the activation step, set the variable to a clean absolute folder or unset the variable.
      1. Run `kong-harnesses --client opencode profile activate PROFILE_NAME`.
      1. After you do all the steps on the `fix:` line, run `doctor` again.
  {% endcomment %}
  - check: "`issuer`"
    what: kong-harnesses can reach the identity provider.
    next: Check the network, VPN, and any proxy, then run `doctor` again.
  - check: "`gateway`"
    what: kong-harnesses can reach the gateway.
    next: |
      Check the network, VPN, proxy, and certificate, then run `doctor` again.
      An `http://` gateway must use a loopback host, such as `localhost`.
      {%- comment %}
      Codex, OpenCode, and Hermes require an `https://` gateway.
      {% endcomment %}
  - check: "`route`"
    what: The gateway has a route for the requests of the agent CLI.
    next: |
      Do the `fix:` step.
      If it names the gateway operators, give them the host and route from the report.
  - check: "`catalog`"
    what: The gateway answers `GET /v1/models` with its model list.
    next: |
      Do the `fix:` step.
      If the gateway answers `404`, it serves no model list, and {{ site.claude_code }} uses its built-in model names.
  - check: "`picker`"
    what: The `/model` menu of {{ site.claude_code }} matches the models that the gateway serves.
    next: Run `profile activate` as the `fix:` line says, or remove the rows that the finding names.
  - check: "`model`"
    what: The gateway or the profile includes the startup model and the model for each role.
    next: Run `/model` and pick a gateway model, or import the profile again, as the `fix:` line says.
  - check: "`anthropic`"
    what: The settings that keep {{ site.claude_code }} on the gateway still match what kong-harnesses wrote.
    next: Correct the settings field that the report names, or ask your administrator to deliver the managed settings again.
  - check: "`overrides`"
    what: The gateway setup of {{ site.claude_code }} stays in effect.
    next: Unset the variables that the report names in the shell that starts {{ site.claude_code }}, or remove the settings keys that the report names.
  - check: "`mcp`"
    what: The MCP policy of {{ site.claude_code }} allows your MCP servers.
    next: |
      Edit the `deniedMcpServers` or `allowedMcpServers` entry that the report names.
      If your organization's policy blocks a server, ask your administrator.
  - check: "`gateway-mcp`"
    what: The gateway MCP servers that the profile lists load, and the gateway accepts your sign-in on them.
    next: |
      Do the `fix:` step, such as `profile activate` or `kong-harnesses login`.
      If the gateway refuses the sign-in, ask the gateway operators.
  - check: "`inference`"
    what: |
      With `--inference`, a small model request through the gateway returns a complete answer.
      The request can cost money.
    next: |
      If the `fix:` line says to send a prompt, send one from {{ site.claude_code }}.
      Otherwise, do the `fix:` step.
{% endtable %}

When managed settings of your organization set a value, ask your administrator to change the settings.
To report a problem that `doctor` doesn't solve, see [kong-harnesses support](/kong-harnesses/support/).
