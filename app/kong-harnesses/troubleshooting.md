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
`doctor` checks the profile, the sign-in, the agent CLI settings and the gateway, and, when it knows one, prints the next step under a problem.
`doctor` doesn't change any settings.
When you want to stop using kong-harnesses on a computer, [`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) gives the agent CLI settings back.

## Run doctor

Check the profile and the agent CLI that fails:

```sh
kong-harnesses doctor --profile <profile> --client claude-code
```

Without `--client`, `doctor` checks every agent CLI that the profile lists, with one report for each.
`doctor` uses the network to check the gateway, and, unless the profile uses a static key, the identity provider.
`kong-harnesses status` shows the sign-in and the agent CLI settings without the network.

Each line of the report starts with a level, `ok`, `warn` or `fail`, and the name of the check.
When `doctor` knows the next step for a problem, the line under it starts with `fix:` and names that step, often with the command for your profile.
The following part of a report shows a failed `overrides` check:

```
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

`doctor` exits with `0` when it doesn't find a failure, even when it reports warnings.
In each report, the kind of the first failed check sets the exit code.
When `doctor` prints more than one report, or finds a problem with the kong-harnesses install, it exits with the most serious of those codes: `2` takes precedence over `1`, and `1` over `3`:

{% table %}
columns:
  - title: Exit code
    key: code
  - title: Kind of problem
    key: problem
rows:
  - code: "`1`"
    problem: The network, the identity provider, the gateway, the OpenCode plugin download, the `--inference` request, or a check that couldn't complete.
  - code: "`2`"
    problem: The profile, the agent CLI or its settings, the shell that starts the agent CLI, the gateway MCP servers, or the kong-harnesses install.
  - code: "`3`"
    problem: The sign-in.
  - code: "`130`"
    problem: The run stopped before `doctor` finished the report, for example after Ctrl+C.
{% endtable %}

## Next step for each check

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
  - check: "`install`"
    what: |
      The `install` check runs once, before the reports.
      On Windows, only administrators can change a kong-harnesses install under `Program Files`.
    next: Ask your administrator to install kong-harnesses again with its MSI, or to remove write access for every account that isn't an administrator.
  - check: "`profile`"
    what: The profile is installed, and kong-harnesses can read it.
    next: |
      Run `kong-harnesses profile list` to see the installed profiles, or `kong-harnesses profile get <profile>` to inspect one.
      If your administrator installed the profile for every user, ask your administrator to install it again.
      If the report says that the session doesn't have a per-user runtime directory, which is common in a container or a CI job on Linux, set `XDG_RUNTIME_DIR` to a new directory that only your user can open.
  - check: "`login`"
    what: You're signed in to the profile. For a profile that uses a static key, a key is saved, or `KONG_HARNESSES_STATIC_KEY` contains the key for a CI profile.
    next: |
      Do what the `fix:` line says, usually `kong-harnesses login --profile <profile>`.
      For OpenCode and Hermes, the `fix:` line names the sign-in command of the agent CLI.
      For a CI profile that reads its key from the environment, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator, because `login` refuses that profile.
      If the report says that no Secret Service runs on Linux, use a desktop session that runs a keyring, such as GNOME Keyring.
      For more about the sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: kong-harnesses set up the agent CLI for this profile, and the agent CLI settings still contain what kong-harnesses wrote.
    next: |
      Do what the `fix:` line says.
      For an agent CLI that the profile lists, `kong-harnesses profile activate <profile> --client <client>` sets up the agent CLI, or applies what changed in the profile.
      When the settings are inconsistent with what kong-harnesses wrote, remove what kong-harnesses owns in that agent CLI with `kong-harnesses profile cleanup --client <client>`.
      When the settings name the profile, but kong-harnesses didn't record that it wrote them, `profile activate` takes them over.
      For OpenCode, remove the gateway plugin entry that kong-harnesses didn't record from the settings file first, then activate the profile.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: Update {{ site.claude_code }}. The `fix:` line names the oldest release that works.
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can read the gateway plugin package from the registry, and a plugin version that works is in the OpenCode cache.
    next: |
      Fix npm access to the registry first, for example the npm token.
      Then do what the `fix:` line says, for example remove an old plugin from the cache and start OpenCode once.
  - check: "`issuer`"
    what: kong-harnesses connects to the identity provider of the profile. A profile that uses a static key skips this check.
    next: |
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the identity provider, install the certificate authority that issued it in the system trust store.
  - check: "`gateway`"
    what: |
      The `gateway` check tests a direct connection to the gateway, and skips that test when a proxy applies.
      Other checks, such as `catalog`, send their requests through the proxy.
    next: |
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the gateway, install the certificate authority that issued it in the system trust store.
      When a proxy applies to an `http://` gateway on this computer, run `kong-harnesses profile activate <profile> --client claude-code` again for {{ site.claude_code }}.
      When project settings or managed settings of {{ site.claude_code }} set a proxy variable, do what the `fix:` line says, because those settings take precedence over the `NO_PROXY` that activation writes.
      For another agent CLI, add the gateway host to `NO_PROXY` and `no_proxy` where the agent CLI starts.
      For an `http://` gateway on an IPv6 loopback address, add each form of the address, such as `[::1]:8000,[::1],::1`.
      You can also use an `https://` gateway.
  - check: "`route`"
    what: |
      The gateway has a route for the requests that the agent CLI sends.
      `doctor` sends a request with the JSON body `{}` to check for the route.
      When it sends your credential, it also checks that the gateway accepts the credential on that route.
    next: |
      When the check fails because the gateway doesn't have a route, or refuses the sign-in on it, ask the gateway operators to add the route, or to accept the sign-in of the profile on it.
      When the check reports a warning with a `fix:` line, do what it says before you contact the operators, for example sign in, unset a variable, or make the managed settings readable.
      When the `fix:` line says to send a prompt, send one from the agent CLI to test the route.
  - check: "`catalog`"
    what: |
      The gateway answers `GET /v1/models` with the list of models that it serves.
      When the provider mode of the profile takes model IDs from the profile, `catalog` reports `ok` without a request, and the `picker` and `model` checks use the models of the profile.
    next: |
      When the check says that the gateway needs a sign-in, or refuses the request, do what the `fix:` line says, for example sign in again.
      If the gateway answers `404` or something other than a model list, or its list doesn't include a model that `/model` can show, ask the gateway operators to correct the model list.
  - check: "`picker`"
    what: The `/model` menu of {{ site.claude_code }} offers only models that the gateway serves, or the models that the profile lists.
    next: |
      Do what the `fix:` line says, when the report has one.
      It's usually `kong-harnesses profile activate <profile> --client claude-code` again, which updates the menu.
      When your organization's managed settings set the menu, ask your administrator to change them.
  - check: "`model`"
    what: The model that a new {{ site.claude_code }} session starts on, and the model that each role such as a subagent uses, are models that the gateway serves, or that the profile lists.
    next: |
      Do what the `fix:` line says, when the report has one.
      Pick a gateway model with `/model`, or unset the variable that the `fix:` line names in the shell that starts {{ site.claude_code }}.
      If the profile sets the model, import the profile again from your administrator, then run `kong-harnesses profile activate <profile> --client claude-code` again.
      When your organization's managed settings set the model, ask your administrator to change them.
  - check: "`anthropic`"
    what: |
      The settings that keep {{ site.claude_code }} on the gateway still contain the values that kong-harnesses wrote.
      A static Anthropic credential in the `env` block of the settings file is a changed value.
    next: |
      Remove a static Anthropic credential from the `env` block first, because `profile activate` refuses a credential there.
      Then do what the `fix:` line says, usually `kong-harnesses profile activate <profile> --client claude-code` again.
      When the settings are inconsistent with what kong-harnesses wrote, the `fix:` line names `kong-harnesses profile cleanup` first.
  - check: "`overrides`"
    what: |
      The shell that starts {{ site.claude_code }} doesn't set a credential variable, such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, that the settings file doesn't override.
      Neither the shell nor the `env` block of the settings file turns on a switch for another provider, such as `CLAUDE_CODE_USE_BEDROCK`, or sets a credential of another provider mode.
    next: |
      Do each step that the `fix:` line names.
      It can say to unset a variable in the shell that starts {{ site.claude_code }}, to remove a key from the `env` block of a settings file, or to ask your administrator to change managed settings.
  - check: "`gateway-mcp`"
    what: |
      No setting keeps {{ site.claude_code }} from loading the gateway MCP servers that the profile lists, and the gateway accepts your sign-in on them.
      `doctor` doesn't send a request to a server that takes its own OAuth sign-in or a saved key.
    next: |
      Run `kong-harnesses profile activate <profile> --client claude-code` to install the servers.
      For a server that takes a key, run `kong-harnesses login --profile <profile>`, which asks for each missing key.
      If the gateway refuses the sign-in on an MCP route, or doesn't serve a server that the profile lists, ask the gateway operators.
      If your organization's managed settings block the servers, ask your administrator.
      When `doctor` can't read a saved key, or your own MCP settings block the servers, do what the `fix:` line says.
  - check: "`inference`"
    what: "With `--inference` only: one small model request through the route of {{ site.claude_code }} gets a complete answer. The request can cost money."
    next: |
      Read the result for the cause, such as a refused sign-in, a missing route or model, or a rate limit.
      Do what the `fix:` line says, when the report has one.
{% endtable %}

## Undo setup

`kong-harnesses setup` and `kong-harnesses profile activate` change the settings of each agent CLI that they set up.
`kong-harnesses profile cleanup` gives back the values that those settings contained before, and removes the values that kong-harnesses added.

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
If you edited a value after kong-harnesses wrote it, `profile cleanup` leaves your edit as it is.
If `profile cleanup` can't tell which values it owns, it exits with `2`.
Inspect the settings, and remove the remaining values manually.
If `profile cleanup` changes the settings of some agent CLIs but doesn't finish for every agent CLI, it exits with `4`.
Do the step that the message names, then run it again.
`profile cleanup` doesn't sign you out, and doesn't delete the profile.

To remove one profile from the computer, sign out first:

```sh
kong-harnesses logout --profile <profile>
```

If `logout` fails, do what its message says, and run it again.
After `logout` succeeds, delete the profile:

```sh
kong-harnesses profile delete <profile>
```

While an agent CLI still uses the profile, `profile delete` refuses, and its message names the next step, such as the `profile cleanup` command for that agent CLI.
Do that step, then run `profile delete` again.
`profile cleanup` without `--client` also removes the settings that other profiles wrote in every agent CLI.

`profile delete` comes last, because the profile contains what `logout` needs to revoke the sign-in.
`profile delete` also refuses while you're signed in.
It asks you to type the profile name to confirm.
For what `logout` revokes, see [Sign out](/kong-harnesses/sign-in/#sign-out).
