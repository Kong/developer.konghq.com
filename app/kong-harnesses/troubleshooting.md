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

When you omit `--client`, `doctor` exits with `2` before it prints a report in these cases:

* The profile doesn't configure any supported agent CLI.
  Ask your administrator for a profile that sets up your agent CLI, then [import the profile](/kong-harnesses/profile/import/).
* You pass `--inference`, and the profile doesn't configure {{ site.claude_code }}.
  The `--inference` flag works only for {{ site.claude_code }}.

When you name an agent CLI that the profile doesn't configure, read the `client` check.
The managed settings of your organization can still set up that agent CLI, or select another profile.

The `doctor` command uses the network to check the gateway.
Unless the profile uses a static key, `doctor` also checks the identity provider.
For OpenCode, `doctor` also checks the npm registry.
To check the sign-in and the agent CLI setup without the network, run [`kong-harnesses status --profile PROFILE_NAME`](/kong-harnesses/status/).

When managed settings keep {{ site.claude_code }} from starting and `doctor` checks {{ site.claude_code }}, `doctor` doesn't send network requests for any agent CLI in that run, and exits with `2`.
In the {{ site.claude_code }} report, the `client` check and each network check fail and name the managed settings file.
In a report for another agent CLI, each network check warns that `doctor` didn't check it.
Ask your administrator to correct the managed settings that the report names.

## Read the report

Each finding in the report starts with a level (`ok`, `warn`, or `fail`) and the name of the check.
When `doctor` knows the next step for a problem, a `fix:` line under the finding names the step.
The `fix:` line fits your setup.
A command on the line can include your profile name, your agent CLI, or both.

The following part of a report shows a failed `overrides` check:

```text
  fail  overrides    ANTHROPIC_AUTH_TOKEN in this shell replaces the sign-in's bearer credential, which the gateway reads
                     fix: unset ANTHROPIC_AUTH_TOKEN in the shell that starts Claude Code
```
{:.no-copy-code}

For what each exit code means, see [Exit codes](/kong-harnesses/errors/#exit-codes).

## Next step for each check

A report includes only the checks that apply to the profile and the agent CLI.
When a finding has a `fix:` line, do the steps that the line names, in the order that the line gives.
When the line gives a choice, such as two steps joined by "or", do the step that fits your case.
Run each command as the `fix:` line shows it.
Keep the `--client` flag in a command that has one, so that a command such as `profile cleanup` changes only that agent CLI.
The following table explains what each check looks at and gives the next step when the `fix:` line isn't enough.

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
      To inspect a valid profile, run `kong-harnesses profile get PROFILE_NAME`.
      Then do the step for your case:

      * A profile that you installed is invalid: run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator.
      * A profile that an administrator installed for every user is invalid: ask your administrator to reinstall the profile.
        The `profile delete` command refuses that profile.
      * The profile needs a newer kong-harnesses: update kong-harnesses and run `doctor` again.
      * On Linux, the session doesn't have a per-user runtime directory, such as in a container or CI job: set `XDG_RUNTIME_DIR` to a new directory that only your user can open.
  - check: "`login`"
    what: |
      You're signed in to the profile.
      For a static-key profile, a key is saved, or `KONG_HARNESSES_STATIC_KEY` holds the key for a CI profile.
    next: |
      Do the step on the `fix:` line, such as `kong-harnesses login --profile PROFILE_NAME`, the sign-in command of the agent CLI, or unlocking the system password store.
      These cases need more context:

      * The `login` check reports `ok` and says that the agent CLI owns the sign-in: check the sign-in status in that agent CLI.
        OpenCode and Hermes can own the sign-in.
      * A CI profile reads its key from the environment: set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
        The `login` command refuses that profile.
      * On Linux, no Secret Service runs in the session: use a desktop session that runs a keyring, such as GNOME Keyring.
        In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`.
      * The report says that `max_access_token_lifetime_seconds` is below 365 seconds: ask your administrator to raise the value to at least 365 seconds, then create or import the profile again.
        Until then, the `login` check fails even while you're signed in, because the next renewal fails.

      For more about sign-in, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
  - check: "`client`"
    what: |
      kong-harnesses or the managed settings of your organization set up the agent CLI for this profile.
      The agent CLI settings still match what that setup wrote.
    next: |
      Do the step on the `fix:` line.
      These cases need more context:

      * The profile doesn't configure the agent CLI: do the step on the `fix:` line, such as getting a profile that configures the agent CLI, or creating the profile again with `profile create`.
        The `profile activate` command doesn't add an agent CLI to a profile.
      * The managed settings of your organization run another profile: run `doctor` with that profile, as the `fix:` line says.
        No activation of your profile can override managed settings.
      * The `fix:` line names [`profile cleanup`](/kong-harnesses/profile/cleanup/): if `profile cleanup` then says that the settings no longer match what kong-harnesses installed, remove the leftover values manually.
      * The settings have two ownership documents: `profile cleanup` refuses these settings, so remove the leftover values and both documents manually.

      After `profile cleanup` succeeds, run `doctor` again and do the step on the new `fix:` line.
      In most other cases, the `fix:` line ends with a `profile activate` command for your profile and agent CLI.
      The `profile activate` command sets up an agent CLI that the profile lists and applies profile changes.
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
      The check also makes sure that OpenCode reads the settings file where activation wrote the gateway plugin entry.
      The `provider` check appears only when it finds a problem.
    next: Do the step on the `fix:` line, such as removing a provider, base URL, or plugin entry from the settings file that the report names, then run `doctor` again.
  - check: "`issuer`"
    what: |
      kong-harnesses can connect directly to the token endpoint of the identity provider.
      When a proxy applies, the `issuer` check skips the connection test and warns.
      For a static-key profile, `doctor` skips the `issuer` check.
    next: |
      Check the network, VPN, and any proxy, then run `doctor` again.
      If `doctor` reports a proxy for the endpoint, make sure that the proxy can connect to the endpoint.
      For a certificate error, ask your administrator to check the certificate of the identity provider and the system trust store.
  - check: "`gateway`"
    what: |
      kong-harnesses can connect directly to the gateway.
      For an `https://` gateway, when a proxy applies, the `gateway` check skips the connection test and warns.
      For an `http://` gateway, the `gateway` check fails when a proxy would get the requests, or when `doctor` can't tell which proxy settings {{ site.claude_code }} applies.
      When you pass `--inference` and `doctor` sends the model request, the {{ site.claude_code }} report has no `gateway` line, except when an `http://` gateway fails for a proxy reason.
      When `gateway` fails, `catalog` and `gateway-mcp` don't send their requests, but `route` still runs.
    next: |
      Check the network, VPN, and any proxy, then run `doctor` again.
      For a certificate error, ask your administrator to check the certificate of the gateway and the system trust store.
      An `http://` gateway must use a loopback host, such as `localhost`.
      Codex, OpenCode, and Hermes require an `https://` gateway.

      For an `http://` gateway behind a proxy, do the steps on the `fix:` line.
      The steps can add the gateway host to a variable such as `NO_PROXY` in the shell that starts the agent CLI.
      Add each entry exactly as the `fix:` line names it.
      When the line asks your administrator to make a managed `NO_PROXY` value name the gateway host, use the host without the port, such as `localhost`.
      For an IPv6 address, add each form of the address, with the gateway port in the first form, such as `[::1]:8000,[::1],::1`, because agent CLIs read the address in different forms.
      For {{ site.claude_code }}, the steps then run `profile activate`, which writes the same exclusion to the {{ site.claude_code }} settings.
      When the `fix:` line for {{ site.claude_code }} doesn't name `profile activate`, the cause is in a settings file, and `profile activate` can't fix the cause.
  - check: "`route`"
    what: |
      The gateway has a route for the requests of the agent CLI.
      When `doctor` sends your credential, an HTTP `401` or `403` response means that the gateway refuses the credential on that route.
      When `doctor` has no credential to send, such as when you aren't signed in or the agent CLI owns its sign-in, a `401` or `403` response gives `ok`.
      That `ok` result confirms only that the route exists, and doesn't confirm that the gateway accepts your credential.
      For a Claude subscription profile, the same response gives `warn`.
      That `warn` result doesn't confirm that the route exists, because `doctor` can't send your subscription sign-in.

      The `route`, `catalog`, `gateway-mcp`, and `inference` checks send their own requests.
      For an `https://` gateway, these requests go through the proxy when one applies.
      For {{ site.claude_code }}, the requests use the proxy rules of {{ site.claude_code }}.
      For other agent CLIs, the requests use the standard proxy rules of Go.
    next: |
      When the check warns with a `fix:` line, do that step first, such as signing in, unsetting a variable, or making managed settings readable.
      When the `fix:` line says to send a prompt, send one from the agent CLI to test the route.
      When the `fix:` line names the gateway operators, ask them to make the change that the line names, such as adding the route or accepting the sign-in of the profile.
      Give the operators the host and route that the report names.
  - check: "`catalog`"
    what: |
      The gateway answers `GET /v1/models` with the list of models that the gateway serves.
      When the provider mode of the profile takes model IDs from the profile, `catalog` reports `ok` without a request, and `picker` and `model` use the models of the profile.
    next: |
      If the `gateway` check fails, fix that problem first, because `catalog` doesn't send a request after that failure.
      When the gateway answers `404`, the gateway doesn't serve a model list, and {{ site.claude_code }} uses its built-in model names for each model that the profile doesn't pin.
      When the gateway needs a credential, do the step on the `fix:` line for your profile, such as signing in or setting `KONG_HARNESSES_STATIC_KEY`, then run `doctor` again.
      For a Claude subscription profile, only {{ site.claude_code }} can send your subscription sign-in, so start {{ site.claude_code }} to read the model list.
      When the `fix:` line names the gateway operators, ask them to serve the models at `/v1/models`.
      When the gateway doesn't answer, run `doctor` again later.
  - check: "`picker`"
    what: |
      When gateway discovery is off, the `/model` menu of {{ site.claude_code }} offers only models that the gateway serves or that the profile lists.
      When gateway discovery fills the menu, the menu keeps the built-in models and adds each gateway model with an ID that contains `claude` or `anthropic`.
      The check looks for missing menu rows for the supported gateway models that discovery skips.
    next: |
      Do each step on the `fix:` line, such as running `profile activate`, removing the rows that the line names from `modelPicker`, or removing `replaceBuiltInOptions`.
      If `picker` says that the model list isn't available, fix the `catalog` problem first.
      When the managed settings of your organization set the menu, ask your administrator to change the settings.
  - check: "`model`"
    what: The gateway serves, or the profile lists, the startup model of {{ site.claude_code }} and the model for each role, such as a subagent.
    next: |
      If the finding says that the model list isn't available, fix the `catalog` problem first.
      When the `fix:` line says to pick a model, run `/model` and pick the kind of model that the line names, a gateway model or a profile model.
      When the `fix:` line says to unset a variable, unset the variable in the shell that starts {{ site.claude_code }}, because that variable overrides `/model`.
      When the `fix:` line says that the profile pins the model, import the profile again and activate the profile, as the line says.
      If the gateway still doesn't serve the pinned model, ask your administrator to pin a model that the gateway serves.
      When the managed settings of your organization set the model, ask your administrator to change the settings.
  - check: "`anthropic`"
    what: |
      The settings that keep {{ site.claude_code }} on the gateway still match what kong-harnesses wrote.
      A static Anthropic credential in the `env` block of the settings file counts as a changed value.
    next: |
      Do each step on the `fix:` line, such as correcting the settings field that the report names, or asking your administrator to deliver the managed settings again.
      When `profile activate` refuses a credential in the `env` block, remove the non-empty `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY` entry, then run the `profile activate` command again.
  - check: "`overrides`"
    what: |
      No variable or project setting overrides the gateway setup of {{ site.claude_code }}.
      The `overrides` check looks for these values:

      * Non-empty credential variables, such as `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`, in the shell that starts {{ site.claude_code }}.
      * Switches to another provider, such as `CLAUDE_CODE_USE_BEDROCK`, in that shell or in the `env` block of the settings file.
      * Provider-mode credentials in the `env` block.
      * A {{ site.claude_code }} project settings file in the current folder that sends {{ site.claude_code }} away from the gateway.
      * `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`.

      The check skips a shell variable that the `env` block also sets, because the value in the settings file takes precedence.
      `profile activate` sets `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` to empty values in the `env` block, so a shell credential matters only when those values are gone.
      Then `ANTHROPIC_AUTH_TOKEN` fails, because the variable replaces the sign-in.
      `ANTHROPIC_API_KEY` fails for a static-key or Claude subscription profile.
      For an identity-provider profile, `ANTHROPIC_API_KEY` warns, because the variable sends a second credential beside the sign-in.
    next: |
      Do each step that the `fix:` line names, such as unsetting variables in the shell that starts {{ site.claude_code }}, or removing keys from a settings file or a project settings file.
      If the `anthropic` check also fails, do its step to restore the gateway settings.
      When the managed settings of your organization set the value, ask your administrator to change the settings.
  - check: "`mcp`"
    what: |
      The MCP policy of {{ site.claude_code }} allows the MCP servers in your user, local, and project settings.
      The `mcp` check appears only when a policy restricts MCP servers.
    next: |
      If your own `deniedMcpServers` setting blocks a server, remove the entry that blocks the server.
      A `deniedMcpServers` entry blocks a server even when `allowedMcpServers` lists the server.
      If your own `allowedMcpServers` setting doesn't list a server, add the server.
      If the policy of your organization blocks a server, ask your administrator to allow the server.
  - check: "`gateway-mcp`"
    what: |
      No setting keeps {{ site.claude_code }} from loading the gateway MCP servers that the profile lists, and the gateway accepts your sign-in on them.
      The `doctor` command doesn't send a request to a server that uses its own OAuth sign-in or a saved key, or that {{ site.claude_code }} uses through another entry at the same address.
    next: |
      Do each step on the `fix:` line.
      For example, the line can name `profile activate` to install a missing server, or `kong-harnesses login`, which asks for each missing server key.
      If the gateway refuses the sign-in on an MCP route or doesn't serve a listed server, ask the gateway operators.
      If the managed settings of your organization block the servers, ask your administrator.
  - check: "`inference`"
    what: |
      When you pass `--inference`, `doctor` sends one small model request through the {{ site.claude_code }} route and checks for a complete answer.
      The request can cost money.
      The `inference` check works only for {{ site.claude_code }}.
      The `doctor` command doesn't send the request when it can't build the request, such as when no usable sign-in or gateway model exists.
      For a Claude subscription profile, `doctor` doesn't send the request, because `doctor` can't read your subscription sign-in.
    next: |
      When the `fix:` line says to send a prompt, send one from {{ site.claude_code }} to test the route.
      When `doctor` doesn't send the request for another reason, do the step on the `fix:` line, then run `doctor` again.
      When the finding has no `fix:` line, read the finding for the reason.
      When the request fails, read the result for the cause, such as a refused sign-in, a missing route or model, or a rate limit.
{% endtable %}
