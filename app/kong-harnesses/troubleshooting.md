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
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

When an agent CLI such as {{ site.claude_code }} can't reach {{ site.ai_gateway }} through kong-harnesses, [`kong-harnesses doctor`](/kong-harnesses/doctor/) finds the cause.
`doctor` checks the profile, sign-in, agent CLI settings, and gateway, and prints the next step under a problem when it knows one.
`doctor` doesn't change any settings.
To sign out, undo agent CLI settings, delete a profile, or uninstall kong-harnesses, in that order, see [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).
To troubleshoot {{ site.claude_code }} configured through managed settings and MDM, see [Troubleshoot a {{ site.claude_code }} fleet](/kong-harnesses/troubleshooting/claude-code-fleet/).

## Run doctor

Check a profile and agent CLI with `kong-harnesses doctor`:

```sh
kong-harnesses doctor --profile PROFILE_NAME --client CLIENT_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile across the commands on this page.
Replace `CLIENT_NAME` with the name of the agent CLI, such as `claude-code`.

When you omit `--client`, `doctor` checks every supported agent CLI that the profile configures, with one report for each.
When the profile doesn't configure any supported agent CLI, `doctor` says so before printing a report and exits with `2`.
Ask your administrator for a profile that sets up your agent CLI, and [import it](/kong-harnesses/profile/import/).
Run `doctor` in the shell and folder where you start the agent CLI, because some checks read the environment and the project settings of {{ site.claude_code }} there.
`doctor` uses the network to check the gateway and, unless the profile uses a static key, the identity provider.
To check the sign-in and agent CLI setup without the network, run [`kong-harnesses status --profile PROFILE_NAME`](/kong-harnesses/status/).

Each line of the report starts with a level (`ok`, `warn`, or `fail`) and the name of the check.
When `doctor` knows the next step for a problem, the `fix:` line under the finding names that step, often with the command for your profile.
The following part of a report shows a failed `overrides` check:

```
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

For what each exit code means, see [Exit codes](/kong-harnesses/errors/#exit-codes).

## Next step for each check

Each `kong-harnesses doctor` report includes only the checks that apply to the profile and agent CLI.
When a finding includes a `fix:` line, follow it first.

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
      The `install` check runs once before the client reports, only on Windows for an install under `Program Files`.
      It verifies that only administrators can change the install and parent folders.
    next: Ask your administrator to reinstall kong-harnesses with its MSI, or remove write access for every non-administrator account.
  - check: "`profile`"
    what: The profile is installed, and kong-harnesses can read it.
    next: |
      Run `kong-harnesses profile list` to see installed profiles, or `kong-harnesses profile get PROFILE_NAME` to inspect one.
      If `doctor` or `profile get` says the profile is invalid, run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator.
      If `profile get` says the profile needs a newer kong-harnesses, update kong-harnesses and run `doctor` again.
      If an administrator installed the profile for every user, ask your administrator to reinstall it.
      If the `profile` line says the session doesn't have a per-user runtime directory (common in a Linux container or CI job), set `XDG_RUNTIME_DIR` to a new directory that only your user can open.
  - check: "`login`"
    what: |
      You're signed in to the profile.
      For a static-key profile, a key is saved, or `KONG_HARNESSES_STATIC_KEY` contains the key for a CI profile.
    next: |
      Run `kong-harnesses login --profile PROFILE_NAME`, or the agent CLI sign-in command named on the `fix:` line.
      For OpenCode and Hermes, the agent CLI can own the sign-in.
      When it does, `doctor` reports `ok` and says the client owns it, so check sign-in status in that agent CLI.
      For a CI profile that reads its key from the environment, set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator, because `login` refuses that profile.
      If the report says that no Secret Service runs on Linux, use a desktop session that runs a keyring, such as GNOME Keyring.
      If `doctor`, `login`, or `status` says `max_access_token_lifetime_seconds` is below 365 seconds, ask your administrator to raise it to at least 365 seconds, then import the corrected profile.
      In that case, `login` fails even while you're signed in, because the next renewal fails.
      For more about sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: kong-harnesses or your organization's managed settings set up the agent CLI for this profile, and the settings still match what that setup wrote.
    next: |
      For an agent CLI listed in the profile, run `kong-harnesses profile activate PROFILE_NAME --client CLIENT_NAME` to set it up, apply profile changes, or take over settings that name the profile without a kong-harnesses ownership record.
      For OpenCode, remove an unrecorded gateway plugin entry from the settings file first, then activate the profile.
      If settings are inconsistent with what kong-harnesses wrote and the `fix:` line names [`profile cleanup`](/kong-harnesses/profile/cleanup/), run it first.
      If `profile cleanup` reports that settings no longer match what kong-harnesses installed, inspect them and remove leftover values manually.
      When settings have two ownership documents, `profile cleanup` refuses them, so remove the leftover values and both documents manually, then activate the profile.
  - check: "`claude-code`"
    what: The installed {{ site.claude_code }} is a release that kong-harnesses supports.
    next: |
      Update {{ site.claude_code }}.
      The `fix:` line names the oldest supported release.
  - check: "`npm` and `plugin`"
    what: For OpenCode, npm can read the gateway plugin package from the registry, and a working plugin version is in the OpenCode cache.
    next: |
      Fix any `npm` access problem first, such as an npm token.
      Then follow the `plugin` `fix:` line, such as removing an old cached plugin and starting OpenCode once.
  - check: "`issuer`"
    what: |
      The `issuer` check tests a direct connection to the identity provider's token endpoint, and skips the test when a proxy applies.
      For a static-key profile, `doctor` skips this check.
    next: |
      If `doctor` reports a proxy for the endpoint, check that the proxy can connect to it.
      Check the network, VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the identity provider's certificate, install its issuing certificate authority in the system trust store.
  - check: "`gateway`"
    what: |
      The `gateway` check tests a direct connection to the gateway without sending an HTTP request.
      For an `http://` gateway, it fails when a proxy applies or when `doctor` can't check proxy settings.
      For an `https://` gateway, it skips only the direct connection test and warns when a proxy applies.
      When `--inference` runs for {{ site.claude_code }}, it skips the direct test once the request is sent, but still fails an `http://` gateway for the same proxy reasons.
      The `route`, `catalog`, `gateway-mcp`, and `inference` checks can each send their own HTTP request to the gateway, through the proxy when one applies to an `https://` gateway.
      When one of those checks sends a request, it uses {{ site.claude_code }}'s proxy rule for {{ site.claude_code }}, and Go's standard proxy policy for other agent CLIs.
      When `gateway` fails, `catalog` and `gateway-mcp` skip their requests, while a `gateway` failure alone doesn't stop `route`.
    next: |
      Check the network, VPN, and any proxy, then run `doctor` again.
      If the computer doesn't trust the gateway's certificate, install its issuing certificate authority in the system trust store.
      When a shell proxy applies to an `http://` gateway on this computer, add the exact gateway host without the port, such as `localhost`, to `NO_PROXY` and `no_proxy` in the shell that starts the agent CLI.
      For an IPv6 loopback address, add instead each form of the address: with brackets and the port, with brackets, and bare, such as `[::1]:8000,[::1],::1`.
      For {{ site.claude_code }}, run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again so activation writes the same exclusion to {{ site.claude_code }} settings.
      When the `fix:` line names only that `profile activate` step, run it on its own.
      When {{ site.claude_code }} project or managed settings set a proxy variable or can't be read, follow the `fix:` line, because those settings take precedence over the `NO_PROXY` that activation writes.
      The same applies when a settings file sets a proxy variable to a non-string value or a value with a NUL character, or on Windows sets one proxy variable twice with different letter case and different values.
      Codex, OpenCode, and Hermes require an `https://` gateway, and the other agent CLIs can use one too.
  - check: "`route`"
    what: |
      The gateway has a route for the agent CLI's requests.
      `doctor` sends a request with the JSON body `{}` to check for the route.
      When `doctor` sends your credential, an HTTP `401` or `403` response means the gateway refuses the credential on that route.
      When `doctor` can't send a credential, such as when you aren't signed in, the agent CLI owns its sign-in, or the profile uses your Claude subscription, it sends the request without one.
      For a Claude subscription profile, where the route requires {{ site.claude_code }}'s subscription sign-in, `route` warns on an HTTP `401` or `403` response and doesn't confirm that the route exists.
      For other profiles, `route` reports `ok` on an HTTP `401` or `403` response without a credential.
      That `ok` result confirms only that the route exists and doesn't confirm that the gateway accepts your credential.
    next: |
      When the gateway doesn't have the route or refuses the sign-in on it, ask the gateway operators to add the route or accept the profile's sign-in on it.
      When the check warns with a `fix:` line, complete that step, such as signing in, unsetting a variable, or making managed settings readable, before contacting the operators.
      When the `fix:` line says to send a prompt, send one from the agent CLI to test the route.
  - check: "`catalog`"
    what: |
      The gateway answers `GET /v1/models` with the list of models it serves.
      When the profile's provider mode takes model IDs from the profile, `catalog` reports `ok` without a request, and `picker` and `model` use the profile's models.
    next: |
      When the gateway needs a sign-in and the profile doesn't use your Claude subscription, sign in as the `fix:` line says, then run `doctor` again.
      For a Claude subscription profile, `doctor` can't send that sign-in, so start {{ site.claude_code }} to read the model list with your subscription sign-in.
      When the `fix:` line names the gateway operators, ask them to serve the models at `/v1/models`.
      When the gateway doesn't answer, run `doctor` again later.
  - check: "`picker`"
    what: |
      When gateway discovery is off, the `/model` menu of {{ site.claude_code }} offers only models that the gateway serves or that the profile lists.
      When gateway discovery fills `/model`, the menu keeps built-in models, adds each gateway model whose ID contains `claude` or `anthropic`, and needs explicit rows for gateway models that discovery skips.
    next: |
      Run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again to update the menu.
      When your organization's managed settings set the menu, ask your administrator to change them.
  - check: "`model`"
    what: The startup model for {{ site.claude_code }} and the model for each role, such as a subagent, are served by the gateway or listed in the profile.
    next: |
      When the `fix:` line says to pick a model, pick a gateway model with `/model`.
      When the `fix:` line says to unset a variable, unset it in the shell that starts {{ site.claude_code }}, because that variable overrides `/model`.
      If the profile sets the model, import the profile again from your administrator, then run `kong-harnesses profile activate PROFILE_NAME --client claude-code`.
      When your organization's managed settings set the model, ask your administrator to change them.
  - check: "`anthropic`"
    what: |
      The settings that keep {{ site.claude_code }} on the gateway still match what kong-harnesses wrote.
      A static Anthropic credential in the `env` block of the settings file counts as a changed value.
    next: |
      Remove any static Anthropic credential from the `env` block first, because `profile activate` refuses a credential there.
      Run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again.
      If settings are inconsistent and the `fix:` line names `kong-harnesses profile cleanup`, run it first, then inspect the settings and remove any leftover values manually.
  - check: "`overrides`"
    what: |
      The `overrides` check reports variables in the shell that starts {{ site.claude_code }} that override the gateway setup: non-empty credential variables such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, and other-provider switches such as `CLAUDE_CODE_USE_BEDROCK`.
      It skips a shell variable that the `env` block of the settings file also sets, because the value in the settings file takes precedence.
      It also reports other-provider switches and provider-mode credentials set in the `env` block of the settings file.
      `ANTHROPIC_AUTH_TOKEN` fails because it replaces the sign-in.
      For an identity-provider profile, `ANTHROPIC_API_KEY` warns because it sends a second credential beside the sign-in.
      For a static-key or Claude subscription profile, both variables fail.
    next: Do each step that the `fix:` line names, such as unsetting variables in the shell that starts {{ site.claude_code }}, removing keys from a settings file `env` block, or asking your administrator to change managed settings.
  - check: "`gateway-mcp`"
    what: |
      No setting keeps {{ site.claude_code }} from loading the gateway MCP servers listed in the profile, and the gateway accepts your sign-in on them.
      `doctor` doesn't send a request to a server that uses its own OAuth sign-in or a saved key, or that {{ site.claude_code }} uses through another entry at the same address.
    next: |
      If {{ site.claude_code }} doesn't load a server, run `kong-harnesses profile activate PROFILE_NAME --client claude-code` to install the servers.
      For a server that takes a key, run `kong-harnesses login --profile PROFILE_NAME`, which asks for each missing key.
      If the gateway refuses the sign-in on an MCP route or doesn't serve a listed server, ask the gateway operators.
      If your organization's managed settings block the servers, ask your administrator.
      If `doctor` can't read a saved key or your own MCP settings block the servers, follow the `fix:` line.
  - check: "`inference`"
    what: |
      When you pass `--inference`, `doctor` sends one small model request through the {{ site.claude_code }} route and checks for a complete answer.
      The request can cost money.
      For a Claude subscription profile, `doctor` doesn't send the request, so send a prompt from {{ site.claude_code }} to test the route.
    next: Read the result for the cause, such as a refused sign-in, a missing route or model, or a rate limit.
{% endtable %}
