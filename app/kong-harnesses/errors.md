---
title: "{{site.kong_harnesses}} errors and exit codes"
description: "What each {{site.kong_harnesses}} exit code means, and how to fix the errors that {{site.kong_harnesses}} prints."
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - troubleshooting

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "Troubleshoot kong-harnesses"
    url: /kong-harnesses/troubleshooting/
  - text: "Sign in with kong-harnesses"
    url: /kong-harnesses/sign-in/
  - text: "kong-harnesses support"
    url: /kong-harnesses/support/
  - text: "kong-harnesses profile file"
    url: /kong-harnesses/profile-file/
---

When a {{site.kong_harnesses}} command fails, it usually prints a line that starts with `Error:` to standard error, and says what to do next.
Find the quoted part of that message on this page to see the cause and the fix.
For a wrong flag or argument, most commands also print `Run 'kong-harnesses COMMAND --help' for usage`.

Some commands report a problem in their own output instead.
`profile list` and `status` list a profile that they can't read as unreadable, as [Unreadable profiles](#unreadable-profiles) describes.
`kong-harnesses doctor` prints its findings, and the `--report` output, to standard output.
To act on the findings of `doctor`, see [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/).

{:.info}
> The text of a message can change between releases.
> In a script, check the exit code, not the message.

## Exit codes

Every {{site.kong_harnesses}} command returns one of the following exit codes:

{% table %}
columns:
  - title: Code
    key: value
  - title: Meaning
    key: meaning
  - title: What to do
    key: action
rows:
  - value: "0"
    meaning: "The command succeeded."
    action: "Nothing."
  - value: "1"
    meaning: >-
      An operational failure, such as a network error, a locked password store, or a profile that another command uses.
      For `doctor`, see [Exit codes of doctor](#exit-codes-of-doctor).
    action: "Follow the message, then run the command again."
  - value: "2"
    meaning: "A wrong flag or argument, or a problem in the profile, the client settings, or this computer."
    action: >-
      Fix what the message names.
      Running the command again without a change gives the same error.
  - value: "3"
    meaning: >-
      The command needs a sign-in, a new sign-in, or a key that isn't saved yet.
      When a renewal of the sign-in didn't finish, the next command resumes it.
    action: >-
      Follow the command in the message.
      Usually, run `kong-harnesses login --profile PROFILE_NAME`, or set the key that the message names.
      If the message says that the next call resumes the renewal, or tells you to run `logout` again, run the command again first.
  - value: "4"
    meaning: >-
      A partial result.
      For example, `logout` removed the local sign-in but couldn't confirm the sign-out at the identity provider.
      Another example is `profile activate` that set up some agent CLIs, and failed for or left out another one.
      `profile activate --dry-run` can exit with `4` without a change to any file, when it leaves out a client.
    action: "Follow the message, then run the command again."
  - value: "130"
    meaning: >-
      You canceled the command, for example with Ctrl+C.
      The message says that the command stopped, and for some commands what it did before it stopped.
    action: "Run the command again when you are ready."
{% endtable %}

### Exit codes of doctor

`kong-harnesses doctor` exits with `0` when it doesn't find a failure, even when it reports warnings.
An interrupted sign-in renewal (`refresh-pending`) resumes on the next credential call, so `doctor` reports `ok` on the `login` check for it.
When `doctor` finds a failure, it uses these exit codes:

* `1` for the network, the identity provider, the gateway or its MCP routes, {% comment %}the OpenCode plugin download, {% endcomment %}the `--inference` request, or a check that couldn't complete.
  This includes a failure that doesn't go away on a retry, such as a missing route or a refused sign-in.
* `2` for the profile, the agent CLI or its settings, the shell that starts the agent CLI, or the {{site.kong_harnesses}} install on Windows.
  This includes a `login` finding when `max_access_token_lifetime_seconds` is too low.
* `3` for the sign-in, or a missing key for a gateway MCP server.
* `130` when you cancel `doctor` before it finishes the report, for example with Ctrl+C.

Within one report, the first failed check in report order sets the exit code of that report.
`doctor` first lists the findings that don't belong to an agent CLI, such as the install check, then writes one report for each agent CLI.
Across those findings and the agent CLI reports, it exits with the most severe code: `2` takes precedence over `1`, and `1` takes precedence over `3`.

## Profile errors

Most messages about choosing a profile start with the command name, such as `login`, `logout`, `doctor`, or `profile activate`.

### Unreadable profiles

`profile list` lists each installed profile, and so does `status` when you don't select a profile with `--profile` or `KONG_HARNESSES_PROFILE`.
When one of them can't read a profile file, it lists that profile as unreadable and continues:

* In text output, the profile shows "Unreadable" and the recovery step.
* In JSON or YAML output, the profile has the state `unreadable`, without the recovery step.
* The command exits with `2`.

When `profile list` can't read which profile is the default, it still lists the profiles and marks none as the default.
It prints "the default profile could not be read, so none is marked" and exits with `1`, even when another profile is unreadable.
Run `kong-harnesses profile default PROFILE_NAME` to choose the default profile again.

`status` also prints one message on standard error, about the first problem with the most severe exit code.
When that problem is an unreadable profile, the message says "is unreadable" and gives the recovery step.
The message can also be about another problem, such as an agent CLI failure.
To see the recovery step for every unreadable profile, run `kong-harnesses status` in text output, without `--profile` or `KONG_HARNESSES_PROFILE`.

A command that selects one profile, and `doctor`, prints the message for the cause instead, as the following entries describe.

### "selected profile does not exist"

The name that you gave with `--profile` or `KONG_HARNESSES_PROFILE` isn't installed on this computer.
To see the installed profiles, run:

```sh
kong-harnesses profile list
```

### "requires a profile"

The command needs a profile, and didn't get one.
The end of the message tells you what to do:

* "and no installed profile is usable" or "and none is installed": Without a profile name, `login`, `logout`, `doctor`, and `fleet build` use the default profile, or the only installed profile.
  They didn't find a usable one.
  Run `kong-harnesses profile list` to see the profiles.
  Install one with [`kong-harnesses profile import`](/kong-harnesses/profile/import/) or [`kong-harnesses profile create`](/kong-harnesses/profile/create/), or name one with `--profile PROFILE_NAME`.
* "specify one with --profile <name> or KONG_HARNESSES_PROFILE": `token`, `credential`, `statusline`, the MCP header helper that {{ site.claude_code }} runs, and `budget refresh` don't use a default profile.
  Name the profile with `--profile PROFILE_NAME`, or with `KONG_HARNESSES_PROFILE`.
* "requires a profile name": The command takes the profile name as its argument, as in `kong-harnesses profile activate PROFILE_NAME`.
  Add the name.

### "accepts one profile" or "accepts one profile name"

The command got more than one profile, for example `--profile` twice, or a profile name argument together with `--profile`.
A command that takes `--profile PROFILE_NAME`, such as `login`, also prints this error when you pass the profile name as an argument, as in `kong-harnesses login PROFILE_NAME`.
Give one profile, in the form that the command takes.

### "profile name is invalid", "profile name after --profile is invalid", or "KONG_HARNESSES_PROFILE holds an invalid profile name"

The profile name after the command, after `--profile`, or in `KONG_HARNESSES_PROFILE` doesn't follow the [rules for `name`](/kong-harnesses/profile-file/#top-level-fields).
Check the spelling, set `KONG_HARNESSES_PROFILE` to the name of an installed profile, or pass `--profile PROFILE_NAME`.
The flag takes precedence over the variable.

### "profile import rejected; check the profile document"

The profile file isn't valid for this release.
Common causes:

* The file isn't valid JSON, or it has a field that this release doesn't support.
* The file, or the answer from the HTTPS URL, is larger than 65,536 bytes.
* A field has a value that the schema version doesn't allow, or two choices conflict.

A profile with a newer `schema_version` gets its own message, as ["selected profile needs a newer kong-harnesses"](#selected-profile-needs-a-newer-kong-harnesses) describes.

Check the file against the [profile file reference](/kong-harnesses/profile-file/).

### "does not offer the advisor" or "turns the advisor"

`profile import` or `profile create` refused `advisor: true`, because {{ site.claude_code }} can't turn on the advisor tool with this profile.
The message names the cause:

* "does not offer the advisor in the provider mode of this profile's route": The route uses `foundry-messages` or `bedrock-mantle-messages`.
  Set `advisor` to `false`.
* "turns the advisor off when experimental betas are off": Set `experimental_betas` to `true`, or set `advisor` to `false`.
* "turns the advisor on through a feature flag from Anthropic": On `anthropic-messages`, set `feature_flags` and `anthropic_telemetry` to `true`, or set `advisor` to `false`.

For `profile create`, run the command again with the flag that the message names.
For the rules, see [Choices that can't go together](/kong-harnesses/profile-file/#choices-that-can-t-go-together).

### "before schema 18" and "also turns off"

The full message starts with `before schema 18, auto_updates false also turns off`.
`profile import` refused a profile before version 18 that sets `auto_updates: false` together with a choice that `auto_updates: false` turns off.
The message names the choices.
Set `auto_updates` to `true`, set the named choices to `false`, or ask your administrator for a version 18 profile.

### "one switch that turns /bug, /feedback and /share on or off together"

{{ site.claude_code }} turns `/bug`, `/feedback`, and `/share` on or off together.
`profile import` refused a profile at version 18 or later, because it sets only one of `bug_command` and `feedback_command`.
Set both to the same value, or leave both out.
A profile that sets them to different values gets ["profile import rejected; check the profile document"](#profile-import-rejected-check-the-profile-document) instead.

### "need an HTTPS gateway"

The message starts with `a Claude subscription and a gateway MCP server with its own OAuth sign-in need an HTTPS gateway`.
`profile import` ends it with `give the profile an https:// gateway_origin`, and `profile create` ends it with `give --gateway-origin an https:// address`.
A `subscription` profile, and a profile with an `oauth` MCP server, send a sign-in that only HTTPS keeps private.
Change `gateway_origin` in the profile, or `--gateway-origin` in `profile create`, to an `https://` URL.

### "the profile file is in" an encoding that kong-harnesses can't read

`profile import` prints this message when the profile file isn't in an encoding that it reads, and names what it found and how to save a copy.
For the accepted encodings and the fix for each refused encoding, see [Profile file encoding](/kong-harnesses/profile-file/#profile-file-encoding).

### "OIDC discovery failed; check issuer access and retry"

`profile create` couldn't read the discovery document of your identity provider.
Check that the issuer URL is right and that this computer can reach it over HTTPS, then run the command again.

### "profile creation rejected"

`profile create` refused the values that you gave.
When the message ends with "check the public flag values and scopes", a flag value isn't valid, for example a URL or a scope.
When it ends with "check the profile name and public values", the profile that it built from the values isn't valid.
Check the values against the [profile file reference](/kong-harnesses/profile-file/), then run the command again.

### "profile create cannot configure"

`profile create` can't build a profile for the agent CLI that you named with `--client`.
The end of the message gives the reason and the fix, for example:

* "only Claude Code signs in to a Claude subscription": A `subscription` profile sets up only {{ site.claude_code }}.
  Use `--client claude-code`, or use a different `--sign-in`.{% comment %}
* "needs an identity provider": OpenCode and Hermes Agent don't work with `--sign-in static-key` or `--sign-in environment-key`.
  Create the profile with an identity provider.
* "pass --audience-parameter audience and no other --scope": Hermes Agent sends the audience in the `audience` parameter and requests only the scopes `openid`, `profile`, `email`, and `offline_access`.
  Add `--audience-parameter audience`, and remove the other `--scope` values.{% endcomment %}
* "only Claude Code reaches the gateway in this provider mode": Only {{ site.claude_code }} works with the `--provider` that you gave.
  Use `--client claude-code`, or use a different `--provider`.

### "the profile was saved, but its result could not be shown"

`profile create` saved the profile, then couldn't print its result, and exits with `1`.
The profile is installed, so don't create it again.
To see the profile, run:

```sh
kong-harnesses profile get PROFILE_NAME
```

### "OIDC metadata is incompatible with profile creation"

`profile create` read the discovery document of your identity provider, but can't build a profile from it.
For example, the issuer in the document differs from the issuer that you gave, or an endpoint doesn't use `https://`.
Check the issuer URL, and the settings of the identity provider.

### "the identity provider's discovery does not list none"

The full message says that the discovery document doesn't list `none` in `token_endpoint_auth_methods_supported`.
{{site.kong_harnesses}} signs in as a public client, without a client secret.
The discovery document of your identity provider doesn't say that its token endpoint accepts a public client.
Some identity providers, such as Keycloak, accept a public client but don't list it.
First, check on a test deployment that sign-in and renewal work without a client secret.
Then run `profile create` again with `--public-client-evidence deployment`, or set [`public_client_evidence`](/kong-harnesses/profile-file/#sign-in-fields) to `deployment` in the profile file.

### "profile import failed; retry after checking source access"

{{site.kong_harnesses}} couldn't read the profile from the file or URL that you gave, or couldn't save it.
Check that the file exists and that you can read it, or that the URL opens from this computer over HTTPS.
Then run the import again.

### "profile is busy; retry the import" or "profile is busy; retry creation"

Another {{site.kong_harnesses}} command, such as a sign-in or a renewal, uses the profile now.
Wait for that command to finish, then run `profile import` or `profile create` again.

### "the existing sign-in or a client's settings could not be inspected"

Before `profile import` or `profile create` replaces a profile, it checks the saved sign-in and the settings of each agent CLI.
One of these checks didn't finish.
Unlock the system password store if it is locked, and check that your account can read the settings file of each agent CLI.
Then run the command again.

### "this session has no per-user runtime directory (XDG_RUNTIME_DIR)"

On Linux, {{site.kong_harnesses}} keeps its locks in the per-user runtime directory, and this session doesn't have one.
A desktop sign-in or an SSH login creates this directory on most Linux hosts.
In another session, such as a container or a CI job, set `XDG_RUNTIME_DIR` to a new directory that only your account can open.

### "no Secret Service runs in this session, so kong-harnesses cannot reach a saved sign-in"

`profile import` and other commands print this message on Linux when the session doesn't have a keyring.
The fix is in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token).

### "still uses this profile, so its security identity cannot change"

The profile that you create or import changes a [security identity field](/kong-harnesses/profile-file/#security-identity), and an agent CLI still uses the installed profile.
Run the command that the message names, `kong-harnesses profile cleanup --client CLIENT_NAME`, or activate another profile in that client.
Then create or import the profile, and activate it again.

### "your organization's managed settings run"

Your organization delivers the profile to {{ site.claude_code }} through managed settings.
Your account can't change its security identity or remove its credential helper with `profile cleanup`.
When `profile import` or `profile create` prints "your organization's managed settings run this profile in Claude Code", ask your administrator to deliver the new profile with `kong-harnesses fleet build`.
When `profile delete` prints "your organization's managed settings run the selected profile", ask your administrator to remove the fleet build from your computer.
`kong-harnesses fleet remove` tells the administrator what to remove from the managed computers.
After the removal, delete the profile.

### "your administrator installed a profile with this name for every user" or "installed this profile for every user"

An administrator installed this profile for every user of the computer, so `profile import` and `profile create` can't replace it, and `profile delete` can't remove it.
`profile delete` refuses any machine-wide profile before asking you to confirm or removing saved keys.
For a valid machine-wide profile, `profile import`, `profile create`, and `setup` tell you to sign in to it with `kong-harnesses login`.
Sign in to it, or ask your administrator to change or remove it.
When the message also says that the profile "is invalid", or that "an account that is not an administrator can change it", {{site.kong_harnesses}} can't use the profile.
Ask your administrator to reinstall it.

### "selected profile is invalid" or "the installed profile of this name is invalid, so import cannot replace it"

The installed copy of a user profile fails validation or can't be read, and `profile import` doesn't replace an installed profile that it can't read.
`profile list` and `status` report it as unreadable with the same `profile delete` and import step in text output.
`doctor` reports "the stored profile is invalid".
Run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator's file or URL with `kong-harnesses profile import`.

When you confirm the deletion of an invalid user profile, `profile delete` deletes the profile file.
It also removes the saved gateway MCP server key for each server name in `mcp_servers`.
Its result tells you what is left to clean up:

* A gateway MCP server key: `profile delete` can't remove a key when your password store refuses or fails to delete it.
  It also can't find the keys when the file doesn't have a readable `mcp_servers` object, including when `mcp_servers` is absent or `null`.
  The result names each item to delete from your system password store: `PROFILE_NAME.mcp-key.SERVER_NAME`, or `PROFILE_NAME.mcp-key.*` when it can't read the object.
* A saved sign-in: `profile delete` doesn't remove a saved sign-in.
  When it finds one or can't rule one out, it warns before it asks you to confirm, and again in its result.
  When the result says that the login may remain, import a valid copy of the profile, then run `kong-harnesses logout --profile PROFILE_NAME`.
* An agent CLI that still uses the profile: `profile delete` can't check which agent CLIs use an invalid profile.
  For each agent CLI that used it, run `kong-harnesses profile cleanup --client CLIENT_NAME`.

### "selected profile needs a newer kong-harnesses"

The installed profile, whether user or machine-wide, has a schema version that this release can't read, usually because a newer release installed it.
`profile list` and `status` report it as unreadable with "update kong-harnesses, then run the command again" in text output.
`doctor` reports "the stored profile needs a newer kong-harnesses".
`profile import` and `profile create` print "the installed profile of this name needs a newer kong-harnesses" when an installed profile has a newer version.
`profile import` prints "this profile needs a newer kong-harnesses" when a source file or URL has a newer version.
Reinstalling the same profile doesn't change its schema version, so a machine-wide profile also needs an update of {{site.kong_harnesses}}.
[Update {{site.kong_harnesses}}](/kong-harnesses/), then run the command again.

### "the selected profile installed for every user is invalid" or "the profile installed for every user can be changed by an account that is not an administrator"

An administrator installed the profile for every user of the computer, and {{site.kong_harnesses}} can't use it:

* "the selected profile installed for every user is invalid" or "the profile installed for every user is invalid": The machine-wide profile file fails validation, is damaged, or names another profile.
  `doctor` prints the shorter message.
* "the profile installed for every user can be changed by an account that is not an administrator": The machine-wide profile file or folder lets an account that isn't an administrator change it, so {{site.kong_harnesses}} doesn't use it.

For either cause, `profile list` and `status` report the profile as unreadable with "ask your administrator to reinstall it" in text output.
`profile delete` refuses a machine-wide profile, so ask your administrator to reinstall the profile.

### "is not a profile name"

`profile list` and `status` report a `.json` file in a profile folder as unreadable when its filename without `.json` doesn't follow the [rules for `name`](/kong-harnesses/profile-file/#top-level-fields).
In text output, the end of the message tells you what to do:

* "ask your administrator to remove it": The file is in the machine-wide profile folder.
  Ask your administrator to remove the file, because reinstalling under the same filename keeps the invalid name.
* "so no command can use or delete it": The file is in your user profile folder.
  No {{site.kong_harnesses}} command can select, sign out of, or delete the file.

### "selected profile is missing, invalid, or unsupported"

The MCP header helper that {{ site.claude_code }} runs prints this message when it can't read the profile.
The profile isn't installed, can't be read, or needs a newer release.
`token`, `credential`, and `doctor` print this message only when they can't tell which of those causes applies.
In the same case, `login --diagnostics` prints it on its `Reason` line.
Otherwise, they print a more specific profile error.
Run `kong-harnesses profile list` to check whether the profile is installed, then import it or follow the step that `profile list` prints for it.

### "selected profile configures no agent client that this kong-harnesses sets up"

Without `--client`, `status` and `doctor` work on each agent CLI that the profile has a block for.
The profile doesn't have a block for any agent CLI that this release sets up.
Ask your administrator for a profile with a block for your agent CLI in [`clients`](/kong-harnesses/profile-file/#clients).
To check one agent CLI now, name it with `--client CLIENT_NAME`.

### "doctor --inference sends its request through Claude Code"

`doctor --inference` sends a test request with {{ site.claude_code }}, and the selected profile doesn't set up {{ site.claude_code }}.
Run `doctor` without `--inference`, or select a profile with a `claude-code` block.

### "saved sign-in", "still activated", or "profile delete could not inspect"

`profile delete` checks for a saved sign-in and inspects each agent CLI's settings before it removes a profile:

* "selected profile still has a saved sign-in" or "the saved sign-in could not be inspected, so the profile was not deleted": The profile is still signed in, or `profile delete` couldn't check.
  For example, the password store is locked.
  Run `kong-harnesses logout --profile PROFILE_NAME`, then delete the profile.
* "cannot tell whether the profile still has a saved sign-in and did not delete it": The message starts with "no Secret Service runs in this session".
  On Linux, a session without a keyring can't see a sign-in that a desktop session saved, so `profile delete` refuses.
  Delete the profile from a desktop session with a keyring, such as GNOME Keyring or KWallet.
* "selected profile is still activated": An agent CLI still uses the profile.
  Run `kong-harnesses profile cleanup --client CLIENT_NAME`, then delete the profile.
* "profile delete could not inspect": When the message ends with "retry later", the settings check didn't finish, so run `profile delete` again.
  When the message ends with "settings configuration", the settings of that agent CLI can't be read.
  Fix the settings file of that client, then run `profile delete` again.

## Sign-in errors

`login` and `logout` print their own errors, and [When the login or logout command fails](/kong-harnesses/sign-in/errors/#when-the-login-or-logout-command-fails) lists them with their fixes.
[When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token) lists the errors that `credential` and `token` print, with their fixes.
Examples are an expired sign-in, a locked system password store, or a proxy in front of an `http://` gateway.
This section lists the `login` result that leaves a client check open, and the errors that {{ site.claude_code }} gets for a gateway MCP server.

### "the sign-in is saved, but the client setup check did not finish"

`login`, or the sign-in step of `setup`, saved the sign-in, then stopped before it finished checking the settings of each agent CLI.
The command exits with `1`, or with `130` if you canceled it.
The sign-in works, so you don't need to sign in again.
After `login`, run the `status` command that the message names to finish the check.
After `setup`, run the resume command that `setup` prints, because `status` only checks the settings and doesn't configure the agent CLIs.

When {{ site.claude_code }} refuses to start on its managed settings, that message comes first and the command exits with `2`.
See ["refuses to start on its managed settings"](#refuses-to-start-on-its-managed-settings).

### "no key for the gateway MCP server"

The full message is `no key for the gateway MCP server SERVER is saved on this computer`, with the name of the server in place of `SERVER`.
A gateway MCP server in the profile takes a key, and you didn't save one yet.
Run `kong-harnesses login --profile PROFILE_NAME`, and enter the key from your administrator when `login` asks for it.

### "lists no gateway MCP server at the address Claude Code named"

{{ site.claude_code }} asked for a credential for an MCP server that the installed profile doesn't list, usually because the profile changed after activation.
Run `kong-harnesses --client claude-code profile activate PROFILE_NAME` again.

## Client setup errors

When `profile activate` checks several agent CLIs and stops before it changes a file, the message starts with `profile activate changed nothing:`.

### "settings file sets ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"

The full message says that your {{ site.claude_code }} settings file sets `ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`.
{{ site.claude_code }} would send that value in place of your sign-in.
Delete the variable from the settings file, then try again.

{% comment %}
### "has a saved key for the kong provider"

pi has its own saved key for the `kong` provider, and it would send that key in place of your sign-in.
Run `pi auth logout kong`, then try again.
{% endcomment %}

### "a proxy is set for the plain-HTTP gateway"

The profile uses an `http://` gateway, and a proxy variable in the shell applies to the gateway host.
The proxy could read the credential, so `profile activate` doesn't set up any client.
To fix it, follow the row for this message in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token), then run `profile activate` again.

{% comment %}
### "is not configured: it can choose a proxy"

The full message is `CLIENT_NAME is not configured: it can choose a proxy that would read the credential for the plain-HTTP gateway GATEWAY_URL unencrypted; use an HTTPS gateway for it`.
`profile activate` doesn't set up Codex, OpenCode, or Hermes Agent for an `http://` gateway, and sets up the other clients as [Plain HTTP gateways](/kong-harnesses/profile-file/#plain-http-gateways) describes.
A failure while writing the settings can still leave some clients set up.
Give these clients a profile with an `https://` gateway.
{% endcomment %}

### "is not configured" for a missing or refused gateway route

The message names the agent CLI, says `HOST has no POST PATH route` or `HOST refuses your sign-in on POST PATH`, and ends with `--skip-route-check`.
Before `profile activate` configures an agent CLI, it checks that the gateway has a route for that client and accepts your sign-in there.
Ask the operators of the gateway to add the route or give you access, then run `profile activate` again.
Some gateway routes match on a header that only the agent CLI sends, such as its `User-Agent`.
For such a route, run `profile activate` again with `--skip-route-check`.

{% comment %}
### "uses plain http, or redirects to it"

The full message names the npm registry of OpenCode and says that it uses plain HTTP or redirects to it.
When `profile activate` sets up several agent CLIs, the message starts with `OpenCode is not configured:`.
OpenCode installs the {{site.kong_harnesses}} plugin from that registry, and over plain HTTP the network could read the registry credential and change the package.
Set the registry in your npm configuration to an `https://` URL, or to a registry on this computer, then run `profile activate` again.
{% endcomment %}

### "managed settings could send"

The message starts with "your organization's managed settings could send".
The profile uses an `http://` gateway, and the managed settings of {{ site.claude_code }} could send its requests through a proxy.
Managed settings take precedence over the `NO_PROXY` value that `profile activate` writes.
The message names the cause, such as a `NO_PROXY` value that leaves out the gateway host, or a managed settings source that {{site.kong_harnesses}} can't read.
Use an `https://` gateway, or ask your administrator to make the change that the message names.

### "refuses to start on its managed settings"

The managed settings of {{ site.claude_code }} on this computer have a value that stops {{ site.claude_code }} from starting.
The command exits with `2`, and this message comes before any other error.
When `doctor` prints this message, the message names the setting and the managed settings file, so ask your administrator to fix that setting in that file.
Other commands name a `doctor` command instead.
Run it to find the setting and the file.

### "applies none of" a settings file

{{ site.claude_code }} ignores a whole settings file when one field in it has the wrong type.
The setup that `profile activate` writes to that file then wouldn't take effect, so `profile activate` refuses.
The message names the file, the field, and the type that the field needs.
Set the field to that type, or remove it, then try again.

### "could not inspect the selected" or "could not use the selected" settings

The message says "could not inspect the selected" or "could not use the selected", names the agent CLI, and ends with "settings configuration".
`status`, `profile activate`, or `profile cleanup` can't read the settings of that agent CLI.
Fix the settings file of that client, then run the command again.

### "settings are inconsistent" or "settings no longer match what this tool installed"

Someone changed the settings that {{site.kong_harnesses}} wrote for an agent CLI.
Check the settings file of that client.
Then run `kong-harnesses profile cleanup --client CLIENT_NAME`, or remove the leftover values manually when the message says so.

### "settings have two ownership documents"

{{site.kong_harnesses}} found two records of what it wrote for the client: one in the settings folder and one next to the settings file.
It can't tell which record is newer.
Remove the leftover values and both records manually, then run the `profile activate` command that the message names.

{% comment %}
### "resolve the same ownership document"

pi and `omp` both read `PI_CODING_AGENT_DIR`, so when that variable is set, a profile that sets up both points them at the same folder.
`profile activate` refuses before it changes a file.
Unset `PI_CODING_AGENT_DIR`, or configure one of the two clients manually.
{% endcomment %}

### "a client configuration directory environment variable is invalid"

One of the environment variables that the message lists holds a folder path that {{site.kong_harnesses}} can't use.
Fix or unset that variable, then run the command again.

### "settings cleanup is incomplete"

`profile cleanup` removed only part of what it wrote, and exits with `4`.
Check the settings of that client, then run `profile cleanup` again.

### "did not finish for" a list of clients

`status`, `profile activate`, or `profile cleanup` worked on several agent CLIs, and failed for each client in the list, for different reasons.
Run the command again with `--client CLIENT_NAME` for each client to see each reason.

### "selected profile does not configure"

The message names an agent CLI that you gave with `--client`, in `profile activate` or `setup`, and the installed profile doesn't have a block for it.
The end of the message tells you what to do:

* "ask your administrator for a profile that sets it up, then import it": No command adds the client to the profile.
  Ask your administrator for a profile with a block for this agent CLI in [`clients`](/kong-harnesses/profile-file/#clients), then [import it](/kong-harnesses/profile/import/).
* "so create the profile again": You made the profile with an older `profile create`, which didn't add this client.
  Run [`kong-harnesses profile create`](/kong-harnesses/profile/create/) again for the profile.

### "no supported agent client was detected" or "does not configure any detected agent client"

`profile activate` didn't find an agent CLI on this computer that the profile sets up.
Install the agent CLI, or name the client with `--client CLIENT_NAME`.
Check that the profile has a block for that client in [`clients`](/kong-harnesses/profile-file/#clients).

### "this kong-harnesses runs from a temporary folder"

When {{site.kong_harnesses}} runs from a temporary folder, the agent CLI would lose its credential helper after that folder is cleaned.
[Install {{site.kong_harnesses}}](/kong-harnesses/), then run `profile activate` with the installed copy.

### "needs an interactive controlling terminal" or "requires an interactive controlling terminal"

The command needs a terminal, and it runs without one, for example in a script.
Run the command in a terminal, or avoid the terminal step:

* For `profile activate`, pass `--auto-approve` or name one agent CLI with `--client CLIENT_NAME`.
* For `profile delete` or `logout`, pass `--auto-approve`.
* For `login`, run it in a terminal.
  In a CI job or a script, use a profile with [`sign_in`](/kong-harnesses/profile-file/#sign-in-fields) set to `environment_key`, which doesn't need `login`.

## Setup errors

[`kong-harnesses setup`](/kong-harnesses/setup/) runs its steps in order and keeps each finished step when a later step fails.

### "setup accepts a profile source or --profile, not both"

You gave `setup` a profile file or HTTPS URL, and also `--profile`.
Give one of them: the source to import a profile, or `--profile PROFILE_NAME` to use an installed profile.

### "setup without a profile source asks profile create's questions, which needs a terminal"

`setup` without a profile file, HTTPS URL, or `--profile` asks the questions of `profile create`, and it runs without a terminal, for example in a script.
Give `setup` a profile file, an HTTPS URL, or `--profile PROFILE_NAME`, or run it in a terminal.

### "setup stopped at step" or "setup configured the other clients at step"

The message names the step that failed and the reason, and the lines before it can give more detail.
Fix the cause, using the entry for that message on this page.
Then run the command that the message names, which resumes after the finished steps.

When the gateway or this computer refuses an agent CLI, the line before the message names the fix.
The message then says what `setup` did:

* "setup configured the other clients at step": `setup` configured each other agent CLI, left out the refused ones, and exits with `4`.
* "which leaves" an agent CLI "out until the fix above is made": Another part of the step failed too.
  Fix it, then run the command that the message names, which leaves the refused agent CLI out.
* "cannot be configured": `setup` refused every agent CLI that it was to configure, so it stopped.
  When you named the agent CLI with `--client`, you can also run `setup` without `--client` to set up the other agent CLIs that the gateway serves.

Until you make the fix for a refused agent CLI, `setup` leaves it out each time, or stops at the same step.

## Fleet build errors

Most `fleet build` and `fleet remove` errors name the flag to add or remove.
[Pin a {{ site.claude_code }} fleet to a tested version range](/kong-harnesses/pin-a-claude-code-fleet/) walks through a new build with `--record`, which needs the record of the build that the computers run.

### "fleet build needs an https:// gateway"

The profile uses an `http://` gateway.
`fleet build` can't check the proxy settings of the managed computers when it runs, so a proxy there could read the credential.
Build from a profile with an `https://` `gateway_origin`.

### "fleet build cannot use a Claude subscription profile"

The managed settings that `fleet build` writes sign every {{ site.claude_code }} session in with the credential helper.
A `subscription` profile uses each developer's own Claude sign-in.
Build from a profile that doesn't use `sign_in: subscription`.

### "already holds the settings of an earlier fleet build"

The policy file that you gave with `--policy` already has the settings of an earlier `fleet build`.
Pass the record of that build with `--record RECORD_FILE`.
`fleet build` then removes the earlier settings from the policy before it adds the new ones.

## Errors that ask you to retry

Some messages say only that an operation failed, or ask you to retry later.
Check the part of the computer that the message names, then run the command again:

{% table %}
columns:
  - title: Message
    key: message
  - title: What to check
    key: check
rows:
  - message: "`profile creation could not verify local storage; retry later`, `profile creation failed; retry after checking local storage`, `profile creation failed`, `profile lock could not be verified; retry after checking local storage`, or `profile storage could not be read`"
    check: "The profile folder of {{site.kong_harnesses}}: that the disk isn't full, and that your account can read and write the folder."
  - message: "`could not write the identity header to Claude Code's settings; retry later`"
    check: "That your account can write the {{ site.claude_code }} settings file."
  - message: "`the key for the gateway MCP server SERVER could not be read; retry later`"
    check: "That the system password store is unlocked."
  - message: "`diagnosis could not complete; retry later`"
    check: >-
      Run `doctor` again.
      If it fails again, collect a debug log as [Collect details for support](#collect-details-for-support) describes.
{% endtable %}

## Collect details for support

To see what a command does, run it with a debug log:

```sh
kong-harnesses COMMAND --log-level debug --log-file kong-harnesses.log
```

You can also set `KONG_HARNESSES_LOG_LEVEL` and `KONG_HARNESSES_LOG_FILE` in the shell.

To report a problem to Kong Support with a `doctor` report, see [kong-harnesses support](/kong-harnesses/support/).
