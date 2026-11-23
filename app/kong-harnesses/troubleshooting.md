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
  - text: kong-harnesses errors and exit codes
    url: /kong-harnesses/errors/
  - text: Troubleshoot a {{ site.claude_code }} fleet
    url: /kong-harnesses/troubleshooting/claude-code-fleet/
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
The `doctor` command checks the profile, the sign-in, the agent CLI settings, and the gateway.
For most problems, the report also shows the next step.
The `doctor` command doesn't change any settings.

For other tasks, see these pages:

* To troubleshoot {{ site.claude_code }} that your organization configures through managed settings and mobile device management (MDM), see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).
* To sign out, undo the agent CLI settings, delete a profile, and uninstall kong-harnesses, in that order, see [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).
* To report a problem that `doctor` doesn't solve, see [kong-harnesses support](/kong-harnesses/support/).

## Run doctor

Run `doctor` in the shell and folder where you start the agent CLI.
Some checks read the variables of that shell and the {{ site.claude_code }} project settings in that folder.

```sh
kong-harnesses doctor --profile PROFILE_NAME --client CLIENT_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile.
The commands on this page use the same placeholder.
Replace `CLIENT_NAME` with the agent CLI to check, such as `claude-code`.
To check every supported agent CLI that the profile configures, omit `--client`.
The `doctor` command then prints one report for each agent CLI.

When you omit `--client` and the profile doesn't configure any supported agent CLI, `doctor` says so and exits with `2`.
Ask your administrator for a profile that sets up your agent CLI, then [import the profile](/kong-harnesses/profile/import/).
When you name an agent CLI that the profile doesn't configure, the `client` check fails.

The `doctor` command uses the network to check the gateway.
Unless the profile uses a static key, `doctor` also checks the identity provider.
For OpenCode, `doctor` also checks the npm registry.
To check the sign-in and the agent CLI setup without the network, run [`kong-harnesses status --profile PROFILE_NAME`](/kong-harnesses/status/).

## Read the report

Each finding in the report starts with a level (`ok`, `warn`, or `fail`) and the name of the check.
When `doctor` knows the next step for a problem, a `fix:` line under the finding names the step, often with the command for your profile.

The following part of a report shows a failed `overrides` check:

```text
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

For what each exit code means, see [Exit codes](/kong-harnesses/errors/#exit-codes).

## Next step for each check

A report includes only the checks that apply to the profile and the agent CLI.
When a finding has a `fix:` line, do that step first.
The following table gives the next step for each check that fails or warns.

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
      On Windows, for an install under `Program Files`, only administrators can change the kong-harnesses program file and every folder that contains the file.
      The `install` check runs once, before the agent CLI reports.
    next: Ask your administrator to reinstall kong-harnesses with its MSI, or to remove write access for every account that isn't an administrator.
  - check: "`profile`"
    what: The profile is installed, and kong-harnesses can read the profile.
    next: |
      To list the installed profiles, run `kong-harnesses profile list`.
      To inspect one profile, run `kong-harnesses profile get PROFILE_NAME`.
      If `doctor` or `profile get` says that a profile you installed is invalid, run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator.
      If an administrator installed the profile for every user, ask your administrator to reinstall the profile.
      The `profile delete` command refuses a profile that an administrator installed.
      If `profile get` says that the profile needs a newer kong-harnesses, update kong-harnesses and run `doctor` again.
      On Linux, if the `profile` line says that the session doesn't have a per-user runtime directory, such as in a container or CI job, set `XDG_RUNTIME_DIR` to a new directory that only your user can open.
  - check: "`login`"
    what: |
      You're signed in to the profile.
      For a static-key profile, a key is saved, or `KONG_HARNESSES_STATIC_KEY` holds the key for a CI profile.
    next: |
      Do the step on the `fix:` line, such as `kong-harnesses login --profile PROFILE_NAME`, the sign-in command of the agent CLI, or unlocking the system password store.
      OpenCode and Hermes can own the sign-in.
      In that case, `doctor` reports `ok` and says that the agent CLI owns the sign-in, so check the sign-in status in that agent CLI.
      For a CI profile that reads its key from the environment, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
      The `login` command refuses that profile.
      On Linux, if the report says that no Secret Service runs in the session, use a desktop session that runs a keyring, such as GNOME Keyring.
      In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`.
      If `doctor`, `login`, or `status` says that `max_access_token_lifetime_seconds` is below 365 seconds, ask your administrator to raise the value to at least 365 seconds, then import the corrected profile.
      Until then, the `login` check fails even while you're signed in, because the next renewal fails.
      For more about sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: |
      kong-harnesses or the managed settings of your organization set up the agent CLI for this profile.
      The agent CLI settings still match what that setup wrote.
    next: |
      Find the case in the report, then do the step for that case:

      * The profile doesn't configure the agent CLI: do the step on the `fix:` line.
        The `profile activate` command doesn't add an agent CLI to a profile.
      * The managed settings of your organization run another profile: run `doctor` with the profile that the `fix:` line names.
      * The `fix:` line names [`profile cleanup`](/kong-harnesses/profile/cleanup/): run `profile cleanup` first.
        If `profile cleanup` says that the settings no longer match what kong-harnesses installed, remove the leftover values manually.
      * The settings have two ownership documents: `profile cleanup` refuses these settings, so remove the leftover values and both documents manually.
      * For OpenCode, no activation recorded the gateway plugin entry: remove that entry from the settings file.

      Then run `kong-harnesses profile activate PROFILE_NAME --client CLIENT_NAME`.
      The `profile activate` command sets up an agent CLI that the profile lists, applies profile changes, and takes over settings that name the profile but don't have a kong-harnesses ownership record.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: Update {{ site.claude_code }} to the release that the `fix:` line names, or to a newer release.
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can read the gateway plugin package from the registry, and a working plugin version is in the OpenCode cache.
    next: |
      Fix the `npm` problem first, such as an npm token that doesn't work.
      Then do the step on the `fix:` line of `plugin`, such as removing an old cached plugin and starting OpenCode once.
  - check: "`provider`"
    what: |
      For OpenCode, no settings file replaces, removes, or turns off the provider that the gateway plugin registers, or sends the provider to another URL.
      The `provider` check appears only when it finds a problem.
    next: Do the step on the `fix:` line, such as removing a provider, base URL, or plugin entry from the settings file that the report names, then run `doctor` again.
  - check: "`issuer`"
    what: |
      kong-harnesses can connect directly to the token endpoint of the identity provider.
      When a proxy applies, the `issuer` check skips the connection test.
      For a static-key profile, `doctor` skips the `issuer` check.
    next: |
      Check the network, VPN, and any proxy, then run `doctor` again.
      If `doctor` reports a proxy for the endpoint, make sure that the proxy can connect to the endpoint.
      If the computer doesn't trust the certificate of the identity provider, install the certificate authority that issued the certificate in the system trust store.
  - check: "`gateway`"
    what: |
      kong-harnesses can connect directly to the gateway.
      For an `https://` gateway, when a proxy applies, the `gateway` check skips the connection test and warns.
      For an `http://` gateway, the `gateway` check fails when a proxy applies or when `doctor` can't read the proxy settings.
      When you pass `--inference` and `doctor` sends the model request, the report has no `gateway` line, except when an `http://` gateway fails for a proxy reason.

      The `route`, `catalog`, `gateway-mcp`, and `inference` checks send their own requests.
      For an `https://` gateway, these requests go through the proxy when one applies.
      For {{ site.claude_code }}, the requests use the proxy rules of {{ site.claude_code }}.
      For other agent CLIs, the requests use the standard proxy rules of Go.
      When `gateway` fails, `catalog` and `gateway-mcp` don't send their requests, but `route` still runs.
    next: |
      Check the network, VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the certificate of the gateway, install the certificate authority that issued the certificate in the system trust store.
      Codex, OpenCode, and Hermes require an `https://` gateway.

      When a shell proxy applies to an `http://` gateway on this computer, do these steps.
      When the `fix:` line names only `profile activate`, do only step 2.

      1. In the shell that starts the agent CLI, add the gateway host without the port, such as `localhost`, to each variable that the `fix:` line names, such as `NO_PROXY`.
         For an IPv6 loopback address, add each form of the address instead, such as `[::1]:8000,[::1],::1`.
      2. For {{ site.claude_code }}, run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again.
         The `profile activate` command writes the same exclusion to the {{ site.claude_code }} settings.

      In these cases, follow the `fix:` line instead, because a settings file takes precedence over the `NO_PROXY` value that `profile activate` writes:

      * The {{ site.claude_code }} project or managed settings set a proxy variable, or `doctor` can't read those settings.
      * A settings file sets a proxy variable to a value that isn't a string, or to a value with a NUL character.
      * On Windows, a settings file sets one proxy variable twice, with different letter case and different values.
  - check: "`route`"
    what: |
      The gateway has a route for the requests of the agent CLI.
      When `doctor` sends your credential, an HTTP `401` or `403` response means that the gateway refuses the credential on that route.
      When `doctor` has no credential to send, such as when you aren't signed in or the agent CLI owns its sign-in, a `401` or `403` response gives `ok`.
      That result confirms only that the route exists.
      For a Claude subscription profile, the same response gives `warn`, because `doctor` can't send your subscription sign-in.
    next: |
      When the check warns with a `fix:` line, do that step first, such as signing in, unsetting a variable, or making managed settings readable.
      When the `fix:` line says to send a prompt, send one from the agent CLI to test the route.
      When the gateway doesn't have the route, or doesn't accept the sign-in on the route, ask the gateway operators to add the route or to accept the sign-in of the profile.
  - check: "`catalog`"
    what: |
      The gateway answers `GET /v1/models` with the list of models that the gateway serves.
      When the provider mode of the profile takes model IDs from the profile, `catalog` reports `ok` without a request, and `picker` and `model` use the models of the profile.
    next: |
      When the gateway needs a sign-in and the profile doesn't use your Claude subscription, sign in as the `fix:` line says, then run `doctor` again.
      For a Claude subscription profile, `doctor` can't send that sign-in, so start {{ site.claude_code }} to read the model list with your subscription sign-in.
      When the `fix:` line names the gateway operators, ask them to serve the models at `/v1/models`.
      When the gateway doesn't answer, run `doctor` again later.
  - check: "`picker`"
    what: |
      When gateway discovery is off, the `/model` menu of {{ site.claude_code }} offers only models that the gateway serves or that the profile lists.
      When gateway discovery fills the menu, the menu keeps the built-in models and adds each gateway model with an ID that contains `claude` or `anthropic`.
      Each gateway model that discovery skips needs its own row in the menu.
    next: |
      If `catalog` can't read the model list, fix that problem first.
      If the report names rows that you added to `modelPicker`, remove those rows as the `fix:` line says.
      Otherwise, run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again to update the menu.
      When the managed settings of your organization set the menu, ask your administrator to change the settings.
  - check: "`model`"
    what: The gateway serves, or the profile lists, the startup model of {{ site.claude_code }} and the model for each role, such as a subagent.
    next: |
      When the `fix:` line says to pick a model, pick a gateway model with `/model`.
      When the `fix:` line says to unset a variable, unset the variable in the shell that starts {{ site.claude_code }}, because that variable overrides `/model`.
      If the profile sets the model, import the profile again from your administrator, then run `kong-harnesses profile activate PROFILE_NAME --client claude-code`.
      When the managed settings of your organization set the model, ask your administrator to change the settings.
  - check: "`anthropic`"
    what: |
      The settings that keep {{ site.claude_code }} on the gateway still match what kong-harnesses wrote.
      A static Anthropic credential in the `env` block of the settings file counts as a changed value.
    next: |
      Do the step on the `fix:` line, such as correcting the settings field that the report names.
      To restore the gateway settings, do these steps:

      1. Remove any static Anthropic credential from the `env` block, because `profile activate` refuses a credential there.
      2. If the `fix:` line names `kong-harnesses profile cleanup`, run that command, then remove any leftover values from the settings manually.
      3. Run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again.
  - check: "`overrides`"
    what: |
      No variable or project setting overrides the gateway setup of {{ site.claude_code }}.
      In the shell that starts {{ site.claude_code }}, the `overrides` check looks for non-empty credential variables, such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, and switches to another provider, such as `CLAUDE_CODE_USE_BEDROCK`.
      The check skips a shell variable that the `env` block of the settings file also sets, because the value in the settings file takes precedence.
      In the `env` block, the check looks for switches to another provider and provider-mode credentials.
      The check also fails when a {{ site.claude_code }} project settings file in the current folder sends {{ site.claude_code }} away from the gateway, or when `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST` is set.
      `ANTHROPIC_AUTH_TOKEN` always fails, because the variable replaces the sign-in.
      `ANTHROPIC_API_KEY` warns for an identity-provider profile, because the variable sends a second credential beside the sign-in.
      For a static-key or Claude subscription profile, `ANTHROPIC_API_KEY` fails.
    next: |
      Do each step that the `fix:` line names, such as unsetting variables in the shell that starts {{ site.claude_code }}, or removing keys from a settings file or a project settings file.
      When the managed settings of your organization set the value, ask your administrator to change the settings.
  - check: "`mcp`"
    what: |
      The MCP policy of {{ site.claude_code }} allows the MCP servers in your user, local, and project settings.
      The `mcp` check appears only when a policy restricts MCP servers.
    next: |
      If your own settings block a server, remove the server from `deniedMcpServers`, or add the server to `allowedMcpServers`.
      If the policy of your organization blocks a server, ask your administrator to allow the server.
  - check: "`gateway-mcp`"
    what: |
      No setting keeps {{ site.claude_code }} from loading the gateway MCP servers that the profile lists, and the gateway accepts your sign-in on them.
      The `doctor` command doesn't send a request to a server that uses its own OAuth sign-in or a saved key, or that {{ site.claude_code }} uses through another entry at the same address.
    next: |
      If the report says that no plugin or MCP entry lists a server, run `kong-harnesses profile activate PROFILE_NAME --client claude-code` to install the servers.
      If the report says that no key is saved for a server, run `kong-harnesses login --profile PROFILE_NAME`, which asks for each missing key.
      If the managed settings of your organization block the servers, ask your administrator.
      If the gateway refuses the sign-in on an MCP route or doesn't serve a listed server, ask the gateway operators.
      In other cases, such as when `doctor` can't read a saved key or your own MCP settings block the servers, follow the `fix:` line.
  - check: "`inference`"
    what: |
      When you pass `--inference`, `doctor` sends one small model request through the {{ site.claude_code }} route and checks for a complete answer.
      The request can cost money.
      The `doctor` command doesn't send the request when it can't build the request, such as when no usable sign-in or gateway model exists.
      For a Claude subscription profile, `doctor` doesn't send the request, so send a prompt from {{ site.claude_code }} to test the route.
    next: |
      When `doctor` doesn't send the request, do the step on the `fix:` line, then run `doctor` again.
      When the request fails, read the result for the cause, such as a refused sign-in, a missing route or model, or a rate limit.
{% endtable %}
