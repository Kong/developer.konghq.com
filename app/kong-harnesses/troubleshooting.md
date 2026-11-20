---
title: Troubleshoot kong-harnesses
description: Find the next step for each problem that kong-harnesses doctor reports, and undo the agent CLI settings that kong-harnesses setup and profile activate changed.

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
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

When an agent CLI such as {{ site.claude_code }} can't reach {{site.ai_gateway}} through kong-harnesses, [`kong-harnesses doctor`](/kong-harnesses/doctor/) finds the cause.
`doctor` checks the profile, the sign-in, the agent CLI settings and the gateway, and prints the next step under each problem it finds.
`doctor` doesn't change any settings.
When you want to stop using kong-harnesses on a computer, [`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) gives the agent CLI settings back.

## Run doctor

Check the profile and the agent CLI that fails:

```sh
kong-harnesses doctor --profile <profile> --client claude-code
```

Without `--client`, `doctor` checks every agent CLI that the profile lists, with one report for each.
`doctor` uses the network, because it connects to the identity provider and to the gateway.
`kong-harnesses status` shows the sign-in and the agent CLI settings without the network.

Each line of the report starts with a level, `ok`, `warn` or `fail`, and the name of the check.
The line under a problem starts with `fix:` and names the next step, with the command for your profile.
The following part of a report shows a failed `overrides` check:

```
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

`doctor` exits with `0` when it doesn't find a failure, even when it reports warnings.
When it finds a failure, the first failure in the report sets the exit code:

{% table %}
columns:
  - title: Exit code
    key: code
  - title: Kind of problem
    key: problem
rows:
  - code: "`1`"
    problem: The network, the identity provider, the gateway, or the OpenCode plugin download.
  - code: "`2`"
    problem: The profile, the agent CLI or its settings, the shell that starts the agent CLI, or the kong-harnesses install.
  - code: "`3`"
    problem: The sign-in.
{% endtable %}

## Next step for each check

The `fix:` line in the report names the exact command for your profile and agent CLI.
A check that doesn't apply to the profile or the agent CLI isn't in the report.

{% table %}
columns:
  - title: Check
    key: check
  - title: What it checks
    key: what
  - title: Next step
    key: next
rows:
  - check: "`profile`"
    what: The profile is installed, and kong-harnesses can read it.
    next: |
      Run `kong-harnesses profile list` to see the installed profiles.
      If the profile is damaged, get the profile file or URL from your administrator and install it again with `kong-harnesses profile import`.
  - check: "`login`"
    what: You're signed in to the profile. For a profile that uses a static key, a key is saved.
    next: |
      Run `kong-harnesses login --profile <profile>`.
      For a CI profile that reads its key from the environment, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
      For more about the sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: kong-harnesses set up the agent CLI for this profile, and the agent CLI settings still hold what kong-harnesses wrote.
    next: |
      Run `kong-harnesses profile activate <profile> --client <client>` to set up the agent CLI, or to apply what changed in the profile.
      When the settings are inconsistent with what kong-harnesses wrote, check the settings file, or remove what kong-harnesses owns with `kong-harnesses profile cleanup`.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: Update {{ site.claude_code }}. The `fix:` line names the oldest release that works.
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can download the gateway plugin, and the plugin is in the OpenCode cache.
    next: Fix npm access to the registry first. Then start OpenCode once, and sign in as the `fix:` line says.
  - check: "`issuer`"
    what: kong-harnesses connects to the identity provider of the profile. A profile that uses a static key skips this check.
    next: |
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the identity provider, install the certificate authority that issued it in the system trust store.
  - check: "`gateway`"
    what: kong-harnesses connects to the gateway.
    next: |
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the gateway, install the certificate authority that issued it in the system trust store.
      For an `http://` gateway on this computer, add the gateway host to `NO_PROXY`, or use an `https://` gateway.
  - check: "`route`"
    what: The gateway has a route for the requests that the agent CLI sends, and accepts your sign-in on that route. `doctor` sends an empty request to find out.
    next: |
      Ask the gateway operators to add the route, or to accept the sign-in of the profile on it.
      When the check reports that it didn't check the route, send a prompt from the agent CLI to test the route.
  - check: "`catalog`"
    what: The gateway answers `GET /v1/models` with the list of models that it serves.
    next: |
      Sign in again if the gateway refuses the request.
      If the gateway answers `404`, or its list doesn't include a model that `/model` can show, ask the gateway operators to serve the model list.
  - check: "`picker`"
    what: The `/model` menu of {{ site.claude_code }} offers only models that the gateway serves.
    next: Run `kong-harnesses profile activate <profile> --client claude-code` again to update the menu.
  - check: "`model`"
    what: The model that a new {{ site.claude_code }} session starts on, and the model that each role such as a subagent uses, are models that the gateway serves.
    next: |
      Pick a gateway model with `/model`, or unset the variable that the `fix:` line names in the shell that starts {{ site.claude_code }}.
      If the profile sets the model, import the profile again from your administrator, then run `kong-harnesses profile activate <profile> --client claude-code` again.
  - check: "`anthropic`"
    what: The settings that keep {{ site.claude_code }} on the gateway still hold the values that kong-harnesses wrote.
    next: Run `kong-harnesses profile activate <profile> --client claude-code` again to restore them.
  - check: "`overrides`"
    what: The shell that starts {{ site.claude_code }} doesn't set a credential variable, such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, or a switch that moves {{ site.claude_code }} off the gateway, such as `CLAUDE_CODE_USE_BEDROCK`.
    next: Unset the variable in the shell that starts {{ site.claude_code }}.
  - check: "`gateway-mcp`"
    what: "{{ site.claude_code }} loads the gateway MCP servers that the profile lists, and the gateway accepts your sign-in on them."
    next: |
      Run `kong-harnesses profile activate <profile> --client claude-code` to install the servers.
      For a server that takes a key, run `kong-harnesses login --profile <profile>`, which asks for each missing key.
      If your organization's managed settings block the servers, ask your administrator.
  - check: "`inference`"
    what: "With `--inference` only: one small model request through the route of {{ site.claude_code }} gets a complete answer. The request can cost money."
    next: Do what the `fix:` line says. It names the cause, such as a refused sign-in, a missing route or model, or a rate limit.
  - check: "`install`"
    what: On Windows, only administrators can change a kong-harnesses install under `Program Files`.
    next: Ask your administrator to install kong-harnesses again with its MSI, or to remove write access for every account that isn't an administrator.
{% endtable %}

## Undo setup

`kong-harnesses setup` and `kong-harnesses profile activate` change the settings of each agent CLI that they set up.
`kong-harnesses profile cleanup` gives back the values that those settings held before, and removes the values that kong-harnesses added.

1. Show what `profile cleanup` would change:

   ```sh
   kong-harnesses profile cleanup --dry-run
   ```

1. Remove the settings:

   ```sh
   kong-harnesses profile cleanup
   ```

Without `--client`, `profile cleanup` works on every supported agent CLI.
To clean up one agent CLI, add `--client`, for example `--client claude-code`.

`profile cleanup` changes only the values that kong-harnesses still owns.
If you edited a value after kong-harnesses wrote it, `profile cleanup` keeps your edit and reports the settings as inconsistent.
When `profile cleanup` cleans up some agent CLIs and then fails on another, it exits with `4`.
`profile cleanup` doesn't sign you out, and doesn't delete the profile.

To remove the profile from the computer too, sign out and delete the profile, in this order:

```sh
kong-harnesses logout --profile <profile>
kong-harnesses profile cleanup
kong-harnesses profile delete <profile>
```

`profile delete` comes last, because the profile holds what `logout` needs to revoke the sign-in.
`profile delete` refuses while you're signed in, or while an agent CLI is still set up for the profile.
It asks you to type the profile name to confirm.
For what `logout` revokes, see [Sign out](/kong-harnesses/sign-in/#sign-out).
