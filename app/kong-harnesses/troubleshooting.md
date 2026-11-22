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
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

When an agent CLI such as {{ site.claude_code }} can't reach {{ site.ai_gateway }} through kong-harnesses, [`kong-harnesses doctor`](/kong-harnesses/doctor/) finds the cause.
`doctor` checks the profile, the sign-in, the agent CLI settings and the gateway, and, when it knows one, prints the next step under a problem.
`doctor` doesn't change any settings.
To undo agent CLI settings, sign out, delete a profile, or uninstall kong-harnesses, see [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).

## Run doctor

Check the profile and the agent CLI that fails:

```sh
kong-harnesses doctor --profile PROFILE_NAME --client CLIENT_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile, here and in each command on this page.
Replace `CLIENT_NAME` with the name of the agent CLI, such as `claude-code`.

Without `--client`, `doctor` checks each agent CLI that the profile configures and that this kong-harnesses build sets up, with one report for each.
When the profile doesn't configure any of them, `doctor` says so before any report and exits with `2`.
Then ask your administrator for a profile that sets up your agent CLI, and [import it](/kong-harnesses/profile/import/).
Run `doctor` in the shell and the folder where you start the agent CLI, because some checks read the environment and the project settings of {{ site.claude_code }} there.
`doctor` uses the network to check the gateway, and, unless the profile uses a static key, the identity provider.
To check the sign-in and the agent CLI setup of a profile without the network, run `kong-harnesses status --profile PROFILE_NAME`.

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
    problem: The network, the identity provider, the gateway or its MCP routes, the OpenCode plugin download, the `--inference` request, or a check that couldn't complete.
  - code: "`2`"
    problem: The profile, the agent CLI or its settings, the shell that starts the agent CLI, or the kong-harnesses install.
  - code: "`3`"
    problem: The sign-in, or a missing key for a gateway MCP server.
  - code: "`130`"
    problem: You canceled `doctor` before it finished the report, for example with Ctrl+C.
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
      The `install` check runs once, before the reports, and only on Windows for an install under `Program Files`.
      It checks that only administrators can change the install and the folders above it.
    next: Ask your administrator to install kong-harnesses again with its MSI, or to remove write access for every account that isn't an administrator.
  - check: "`profile`"
    what: The profile is installed, and kong-harnesses can read it.
    next: |
      Run `kong-harnesses profile list` to see the installed profiles, or `kong-harnesses profile get PROFILE_NAME` to inspect one.
      If `doctor` or `profile get` says that the profile is invalid, run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator.
      If `profile get` says that the profile needs a newer kong-harnesses, update kong-harnesses, then run `doctor` again.
      If `doctor` says that the selected profile doesn't configure an agent CLI that this kong-harnesses build sets up, ask your administrator for a profile that sets up your agent CLI, and [import it](/kong-harnesses/profile/import/).
      If your administrator installed the profile for every user, ask your administrator to install it again.
      If the `profile` line says that the session doesn't have a per-user runtime directory, which is common in a container or a CI job on Linux, set `XDG_RUNTIME_DIR` to a new directory that only your user can open.
  - check: "`login`"
    what: You're signed in to the profile. For a profile that uses a static key, a key is saved, or `KONG_HARNESSES_STATIC_KEY` contains the key for a CI profile.
    next: |
      Do what the `fix:` line says, usually `kong-harnesses login --profile PROFILE_NAME`.
      For OpenCode and Hermes, the agent CLI can own the sign-in.
      Then `doctor` reports `ok` and says that the client owns it, so check the sign-in in the agent CLI.
      When the `fix:` line names the sign-in command of the agent CLI, run that command.
      For a CI profile that reads its key from the environment, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator, because `login` refuses that profile.
      If the report says that no Secret Service runs on Linux, use a desktop session that runs a keyring, such as GNOME Keyring.
      If the `login` check, `login` or `status` says that the `max_access_token_lifetime_seconds` of the profile is below the shortest token lifetime that sign-in accepts, ask your administrator to raise the value to at least 365 seconds, then import the corrected profile.
      The `login` check then fails even when you're signed in, because the next renewal of the sign-in fails.
      For more about the sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: kong-harnesses, or the managed settings of your organization, set up the agent CLI for this profile, and the agent CLI settings still contain what that setup wrote.
    next: |
      Do what the `fix:` line says.
      For an agent CLI that the profile lists, `kong-harnesses profile activate PROFILE_NAME --client CLIENT_NAME` sets up the agent CLI, or applies what changed in the profile.
      When the settings are inconsistent with what kong-harnesses wrote, and the `fix:` line names `profile cleanup`, run that command first.
      When the settings have two ownership documents, `profile cleanup` refuses them, so remove the leftover values and both documents manually, then activate the profile, as the `fix:` line says.
      If `profile cleanup` reports that the settings no longer match what kong-harnesses installed, inspect them and remove the leftover values manually.
      When the settings name the profile, but kong-harnesses didn't record that it wrote them, `profile activate` takes them over.
      For OpenCode, remove the gateway plugin entry that kong-harnesses didn't record from the settings file first, then activate the profile.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: Update {{ site.claude_code }}. The `fix:` line names the oldest release that works.
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can read the gateway plugin package from the registry, and a plugin version that works is in the OpenCode cache.
    next: |
      If the `npm` check reports an access problem, fix it first, for example the npm token.
      Then do what the `fix:` line says, for example remove an old plugin from the cache and start OpenCode once.
  - check: "`issuer`"
    what: |
      The `issuer` check tests a direct connection to the token endpoint of the identity provider of the profile, and skips that test when a proxy applies.
      A profile that uses a static key skips this check.
    next: |
      If `doctor` reports a proxy for the endpoint, check that the proxy can connect to the endpoint.
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the identity provider, install the certificate authority that issued it in the system trust store.
  - check: "`gateway`"
    what: |
      The `gateway` check tests a direct connection to the gateway.
      For an `http://` gateway, the check fails when a proxy applies to the gateway, or when `doctor` can't check the proxy settings.
      For an `https://` gateway, the check skips the test when a proxy applies.
      When `--inference` runs for {{ site.claude_code }}, the check skips the direct test, but still fails an `http://` gateway for the same proxy reasons.
      For an `https://` gateway, other checks, such as `catalog`, can send their requests through the proxy.
    next: |
      Check the network, the VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the gateway, install the certificate authority that issued it in the system trust store.
      When a proxy in the shell applies to an `http://` gateway on this computer, add the exact gateway host, without the port, such as `localhost`, to `NO_PROXY` and `no_proxy` in the shell that starts the agent CLI.
      For an IPv6 loopback address, add instead each form of the address, with brackets and the port, with brackets, and bare, such as `[::1]:8000,[::1],::1`.
      For {{ site.claude_code }}, then run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again, which writes the same exclusion to the {{ site.claude_code }} settings.
      When the `fix:` line names only that `profile activate` step, run it on its own.
      When project settings or managed settings of {{ site.claude_code }} set a proxy variable, or `doctor` can't read them, do what the `fix:` line says, because those settings take precedence over the `NO_PROXY` that activation writes.
      The same applies when a settings file sets a proxy variable to a value that isn't a string or that contains a NUL character.
      On Windows, it also applies when a settings file sets one proxy variable twice, with different letter case and different values.
      Codex, OpenCode and Hermes need an `https://` gateway, and the other agent CLIs can use one too.
  - check: "`route`"
    what: |
      The gateway has a route for the requests that the agent CLI sends.
      `doctor` sends a request with the JSON body `{}` to check for the route.
      When it sends your credential, an HTTP `401` or `403` answer means that the gateway refuses the credential on that route.
    next: |
      When the check fails because the gateway doesn't have a route, or refuses the sign-in on it, ask the gateway operators to add the route, or to accept the sign-in of the profile on it.
      When the check reports a warning with a `fix:` line, do what it says before you contact the operators, for example sign in, unset a variable, or make the managed settings readable.
      When the `fix:` line says to send a prompt, send one from the agent CLI to test the route.
  - check: "`catalog`"
    what: |
      The gateway answers `GET /v1/models` with the list of models that it serves.
      When the provider mode of the profile takes model IDs from the profile, `catalog` reports `ok` without a request, and the `picker` and `model` checks use the models of the profile.
    next: |
      Do what the `fix:` line says.
      When the check says that the gateway needs a sign-in, and the profile doesn't use your Claude subscription, sign in as the `fix:` line says, then run `doctor` again.
      For a profile that uses your Claude subscription, `doctor` can't send that sign-in, so the `fix:` line says to start {{ site.claude_code }}, which reads the model list with your subscription sign-in.
      When the `fix:` line names the gateway operators, ask them to serve the models at `/v1/models`.
      When the gateway doesn't answer, run `doctor` again later.
  - check: "`picker`"
    what: |
      Without gateway discovery, the `/model` menu of {{ site.claude_code }} offers only models that the gateway serves or that the profile lists.
      When gateway discovery fills the menu, the menu keeps the built-in models and adds each gateway model whose ID contains `claude` or `anthropic`, and each gateway model that discovery skips needs its own row.
    next: |
      Do what the `fix:` line says, when the report has one.
      It's usually `kong-harnesses profile activate PROFILE_NAME --client claude-code` again, which updates the menu.
      When your organization's managed settings set the menu, ask your administrator to change them.
  - check: "`model`"
    what: The model that a new {{ site.claude_code }} session starts on, and the model that each role such as a subagent uses, are models that the gateway serves, or that the profile lists.
    next: |
      Do what the `fix:` line says, when the report has one.
      When the `fix:` line says to pick a model, pick a gateway model with `/model`.
      When the `fix:` line says to unset a variable, unset it in the shell that starts {{ site.claude_code }}, because that variable overrides the choice in `/model`.
      If the profile sets the model, import the profile again from your administrator, then run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again.
      When your organization's managed settings set the model, ask your administrator to change them.
  - check: "`anthropic`"
    what: |
      The settings that keep {{ site.claude_code }} on the gateway still contain the values that kong-harnesses wrote.
      A static Anthropic credential in the `env` block of the settings file is a changed value.
    next: |
      Remove a static Anthropic credential from the `env` block first, because `profile activate` refuses a credential there.
      Then do what the `fix:` line says, usually `kong-harnesses profile activate PROFILE_NAME --client claude-code` again.
      When the settings are inconsistent with what kong-harnesses wrote, the `fix:` line can name `kong-harnesses profile cleanup` first.
      After the cleanup, inspect the settings and remove any leftover values manually.
  - check: "`overrides`"
    what: |
      The check reports each variable in the shell that starts {{ site.claude_code }} that overrides the gateway setup.
      These are credential variables that aren't empty, such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, and switches for another provider that are turned on, such as `CLAUDE_CODE_USE_BEDROCK`.
      The check skips a variable that the `env` block of the settings file also sets, because the value in the settings file takes precedence.
      It also reports a switch for another provider that the `env` block turns on, and a credential for the provider mode of the profile that the `env` block sets.
      `ANTHROPIC_AUTH_TOKEN` fails, because it replaces the sign-in.
      For a profile that signs in through an identity provider, `ANTHROPIC_API_KEY` is a warning, because it sends a second credential beside the sign-in.
      For a profile that uses a static key or your own Claude subscription, both variables fail.
    next: |
      Do each step that the `fix:` line names.
      It can say to unset a variable in the shell that starts {{ site.claude_code }}, to remove a key from the `env` block of a settings file, or to ask your administrator to change managed settings.
  - check: "`gateway-mcp`"
    what: |
      No setting keeps {{ site.claude_code }} from loading the gateway MCP servers that the profile lists, and the gateway accepts your sign-in on them.
      `doctor` doesn't send a request to a server that takes its own OAuth sign-in or a saved key, or that {{ site.claude_code }} uses through another entry at the same address.
    next: |
      If {{ site.claude_code }} doesn't load a server, do what the `fix:` line says, usually `kong-harnesses profile activate PROFILE_NAME --client claude-code`, which installs the servers.
      For a server that takes a key, run `kong-harnesses login --profile PROFILE_NAME`, which asks for each missing key.
      If the gateway refuses the sign-in on an MCP route, or doesn't serve a server that the profile lists, ask the gateway operators.
      If your organization's managed settings block the servers, ask your administrator.
      When `doctor` can't read a saved key, or your own MCP settings block the servers, do what the `fix:` line says.
  - check: "`inference`"
    what: |
      With `--inference` only, one small model request through the route of {{ site.claude_code }} gets a complete answer.
      The request can cost money.
      For a profile that uses your Claude subscription, `doctor` doesn't send the request, so send a prompt from {{ site.claude_code }} to test the route.
    next: |
      Read the result for the cause, such as a refused sign-in, a missing route or model, or a rate limit.
      Do what the `fix:` line says, when the report has one.
{% endtable %}
