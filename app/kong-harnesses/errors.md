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

When a command fails, {{site.kong_harnesses}} prints a line that starts with `Error:` to standard error, and says what to do next. For a wrong flag or argument, most commands also print `Run 'kong-harnesses COMMAND --help' for usage`.

`kong-harnesses doctor` works in another way. It prints its findings, and the `--report` output, to standard output. For each agent CLI, the failed check to fix first gives a code: 2 for a profile or setup problem, 3 for a sign-in problem, and 1 for any other problem. `doctor` exits with the most severe of these codes across the profile and every agent CLI, in the order 2, then 1, then 3. A warning alone exits with 0. To act on the findings, see [Troubleshoot kong-harnesses](/kong-harnesses/troubleshooting/).

{:.info}
> The text of a message can change between releases. In a script, check the exit code, not the message.

## Exit codes

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
    meaning: "A temporary failure, such as a network error, a locked password store, or a profile that another command uses."
    action: "Follow the message, then run the command again."
  - value: "2"
    meaning: "A wrong flag or argument, or a problem in the profile, the client settings or this computer."
    action: "Fix what the message names. Running the command again without a change gives the same error."
  - value: "3"
    meaning: "The command needs a sign-in, a new sign-in, or a key that isn't saved yet. When a renewal of the sign-in didn't finish, the next command resumes it."
    action: "Run `kong-harnesses login --profile PROFILE_NAME`, or set the key that the message names. If the message says that the next call resumes the renewal, run the command again first."
  - value: "4"
    meaning: "A partial result. For example, `logout` removed the local sign-in but couldn't confirm the sign-out at the identity provider, or `profile activate` set up some agent CLIs and failed for or left out another one. `profile activate --dry-run` can exit with 4 without a change to any file, when it leaves out a client."
    action: "Follow the message, then run the command again."
  - value: "130"
    meaning: "You canceled the command, for example with Ctrl+C. The message says that the command stopped, and for some commands what it did before it stopped."
    action: "Run the command again when you are ready."
{% endtable %}

## Profile errors

### "selected profile does not exist"

The name that you gave with `--profile` or `KONG_HARNESSES_PROFILE` isn't installed on this computer. To see the installed profiles, run:

```sh
kong-harnesses profile list
```

Most of the messages about the choice of a profile start with the name of the command, such as `login`, `logout`, `doctor` or `profile activate`.

### "requires a profile"

The command needs a profile, and didn't get one. The end of the message tells you what to do:

* "and no installed profile is usable" or "and none is installed": When you don't name a profile, `login`, `logout`, `doctor` and `fleet build` use the default profile, or the only installed profile, and they didn't find one. Run `kong-harnesses profile list` to see the profiles, then install one with [`kong-harnesses profile import`](/kong-harnesses/profile/import/) or [`kong-harnesses profile create`](/kong-harnesses/profile/create/), or name one with `--profile PROFILE_NAME`.
* "specify one with --profile <name> or KONG_HARNESSES_PROFILE": `token`, `credential`, `statusline`, the MCP header helper that {{ site.claude_code }} runs, and `budget refresh` don't use a default profile. Name the profile with `--profile PROFILE_NAME`, or with `KONG_HARNESSES_PROFILE`.
* "requires a profile name": The command takes the profile name as its argument, as in `kong-harnesses profile activate PROFILE_NAME`. Add the name.

### "accepts one profile" or "accepts one profile name"

The command got more than one profile, for example `--profile` twice, or a profile name argument together with `--profile`. A command that takes `--profile PROFILE_NAME`, such as `login`, also prints it when you give the profile name as an argument, as in `kong-harnesses login PROFILE_NAME`. Give one profile, in the form that the command takes.

### "profile name is invalid" or "profile name after --profile is invalid"

The profile name that you gave doesn't follow the [rules for `name`](/kong-harnesses/profile-file/#top-level-fields). Check the spelling of the name.

### "KONG_HARNESSES_PROFILE holds an invalid profile name"

You didn't give `--profile`, and `KONG_HARNESSES_PROFILE` is set to a value that can't be a profile name. Set `KONG_HARNESSES_PROFILE` to the name of an installed profile, or name the profile with `--profile PROFILE_NAME`. The flag wins over the variable.

### "profile import rejected; check the profile document"

The profile file isn't valid for this release. Common causes:

* The file isn't valid JSON, or it has a field that this release doesn't know.
* The `schema_version` is newer than this release reads. [Install a newer {{site.kong_harnesses}}](/kong-harnesses/), or ask your administrator for a profile with an older version.
* A field has a value that the schema version doesn't allow, or two choices conflict.

Check the file against the [profile file reference](/kong-harnesses/profile-file/).

### "need an HTTPS gateway"

The full message is `a Claude subscription and a gateway MCP server with its own OAuth sign-in need an HTTPS gateway; give the profile an https:// gateway_origin`. A `subscription` profile, and a profile with an `oauth` MCP server, send a sign-in that only HTTPS keeps private. Change `gateway_origin` in the profile to an `https://` URL. `profile create` prints the same message with `--gateway-origin` in place of `gateway_origin`.

### "the profile file is in" an encoding that kong-harnesses can't read

`profile import` reads a file in UTF-8, with or without a byte-order mark, or in UTF-16 with a byte-order mark. The message names what it found instead, and the fix for it:

* "UTF-16 without a byte-order mark": Save a copy with a byte-order mark, for example in PowerShell with `Get-Content -Raw -Encoding Unicode PROFILE_FILE | Set-Content -Encoding Unicode COPY_FILE`, then import the copy.
* "UTF-32": Save a copy as UTF-16, for example in PowerShell with `Get-Content -Raw PROFILE_FILE | Set-Content -Encoding Unicode COPY_FILE`, then import the copy.
* "UTF-16 with a broken character": The file is cut short or damaged. Get the profile file again.
* "a text encoding that is not UTF-8", or "UTF-8 with a byte-order mark" for a file with two byte-order marks: Save a copy as UTF-8 with an editor, then import the copy.

### "OIDC discovery failed; check issuer access and retry"

`profile create` couldn't read the discovery document of your identity provider. Check that the issuer URL is right and that this computer can reach it over HTTPS, then run the command again.

### "profile creation rejected"

`profile create` refused the values that you gave. When the message ends with "check the public flag values and scopes", a flag value isn't valid, for example a URL or a scope. When it ends with "check the profile name and public values", the profile that it built from the values isn't valid. Check the values against the [profile file reference](/kong-harnesses/profile-file/), then run the command again.

### "OIDC metadata is incompatible with profile creation"

`profile create` read the discovery document of your identity provider, but can't build a profile from it. For example, the issuer in the document differs from the issuer that you gave, or an endpoint doesn't use `https://`. Check the issuer URL, and the settings of the identity provider.

### "profile import failed; retry after checking source access"

{{site.kong_harnesses}} couldn't read the profile from the file or URL that you gave, or couldn't save it. Check that the file exists and that you can read it, or that the URL opens from this computer over HTTPS. Then run the import again.

### "profile is busy; retry the import" or "profile is busy; retry creation"

Another {{site.kong_harnesses}} command, such as a sign-in or a renewal, uses the profile now. Wait for that command to finish, then run `profile import` or `profile create` again.

### "the existing sign-in or a client's settings could not be inspected"

`profile import` checks the saved sign-in and the settings of each agent CLI before it replaces a profile, and one of them didn't answer, for example a locked password store. Unlock the password store if it is locked, then run the import again.

### "no Secret Service runs in this session, so kong-harnesses cannot reach a saved sign-in"

`profile import` and other commands print this message on Linux when the session has no keyring. The fix is in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/#when-kong-harnesses-can-t-give-an-access-token).

### "still uses this profile, so its security identity cannot change"

The profile that you import changes a [security identity field](/kong-harnesses/profile-file/#security-identity), and an agent CLI still uses the installed profile. Run the command that the message names, `kong-harnesses profile cleanup --client CLIENT_NAME`, or activate another profile in that client. Then import the profile, and activate it again.

### "your organization's managed settings run this profile in Claude Code"

Your organization delivers the profile to {{ site.claude_code }} through managed settings, so `profile import` can't change its security identity on your computer. Ask your administrator to deliver the new profile with `kong-harnesses fleet build`.

### "your organization's managed settings run the selected profile"

`profile delete` prints this message when your organization delivers the profile to {{ site.claude_code }} through managed settings. The managed settings run the credential helper of the profile, and `profile cleanup` can't take the helper out either. Ask your administrator to remove the fleet build with `kong-harnesses fleet remove`, then delete the profile.

### "your administrator installed a profile with this name for every user" or "installed this profile for every user"

An administrator installed this profile for every user of the computer, so `profile import` can't replace it, and `profile delete` can't remove it. Sign in to it with `kong-harnesses login`, or ask your administrator to change it.

### "selected profile is invalid"

The installed copy of the profile can't be read. Run `kong-harnesses profile delete PROFILE_NAME`, then import the profile again from your administrator's file or URL with `kong-harnesses profile import`. `profile delete` can't check the client settings of an invalid profile, and it keeps a saved sign-in. When its result says that the login may remain, import the profile, then run `kong-harnesses logout --profile PROFILE_NAME`. For an agent CLI that still uses the profile, run `kong-harnesses profile cleanup --client CLIENT_NAME`.

### "the installed profile of this name is invalid, so import cannot replace it"

`profile import` doesn't replace an installed profile that it can't read. Run `kong-harnesses profile delete PROFILE_NAME`, then run the import again. The steps after the delete are in ["selected profile is invalid"](#selected-profile-is-invalid).

### "selected profile needs a newer kong-harnesses"

The installed profile has a schema version that this release can't read, usually because a newer release installed it. [Update {{site.kong_harnesses}}](/kong-harnesses/), then run the command again.

### "selected profile is missing, invalid, or unsupported"

The MCP header helper that {{ site.claude_code }} runs prints this message when it can't read the profile, because the profile isn't installed, can't be read, or needs a newer release. `login`, `token`, `credential` and `doctor` print it only when they can't tell which of these is the cause. Otherwise, they print one of the messages above, such as "selected profile does not exist". Run `kong-harnesses profile list` to check that the profile is installed. If it is, install it again with `kong-harnesses profile import`, or update {{site.kong_harnesses}} when a newer release wrote it.

### "the profile installed for every user can be changed by an account that is not an administrator"

An administrator installed the profile for every user of the computer, but its file or folder lets other accounts change it, so {{site.kong_harnesses}} doesn't use it. Ask your administrator to install the profile again.

### "selected profile configures no agent client that this kong-harnesses sets up"

`status`, `doctor` and `login --diagnostics` without `--client` work on each agent CLI that the profile has a block for, and the profile doesn't have a block for one that this release sets up. Ask your administrator for a profile with a block for your agent CLI in [`clients`](/kong-harnesses/profile-file/#clients). To check one agent CLI now, name it with `--client CLIENT_NAME`.

### "selected profile still has a saved sign-in"

`profile delete` refuses a profile that is still signed in. Run `kong-harnesses logout --profile PROFILE_NAME`, then delete the profile.

### "the saved sign-in could not be inspected, so the profile was not deleted"

`profile delete` couldn't find out whether the profile is still signed in, for example because the password store is locked, and it doesn't delete a profile that could still have a sign-in. Run `kong-harnesses logout --profile PROFILE_NAME`, then delete the profile.

### "cannot tell whether the profile still has a saved sign-in and did not delete it"

The message starts with "no Secret Service runs in this session". On Linux, a session without a keyring can't see a sign-in that a desktop session saved, so `profile delete` refuses. Delete the profile from a desktop session with a keyring, such as GNOME Keyring.

### "profile delete could not inspect"

`profile delete` checks the settings of each agent CLI before it removes the profile. When the message ends with "retry later", the check didn't finish, so run `profile delete` again. When the message ends with "settings configuration", the settings of that agent CLI can't be read. Fix the settings file of that client, then run `profile delete` again.

### "selected profile is still activated"

`profile delete` refuses a profile that an agent CLI still uses. Run `kong-harnesses profile cleanup --client CLIENT_NAME`, then delete the profile.

## Sign-in errors

`login` and `logout` print their own errors, and [When the login or logout command fails](/kong-harnesses/sign-in/#when-the-login-or-logout-command-fails) lists them with their fixes. When `logout` exits with 4, see [Sign out](/kong-harnesses/sign-in/#sign-out). The errors that `credential` and `token` print, such as an expired sign-in, a locked Keychain or a proxy in front of an `http://` gateway, are listed with their fixes in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/#when-kong-harnesses-can-t-give-an-access-token). This section lists the errors that {{ site.claude_code }} gets for a gateway MCP server.

### "no key for the gateway MCP server"

The message ends with "is saved on this computer". A gateway MCP server in the profile takes a key, and you didn't save one yet. Run `kong-harnesses login --profile PROFILE_NAME`, and enter the key from your administrator when `login` asks for it.

### "lists no gateway MCP server at the address Claude Code named"

{{ site.claude_code }} asked for a credential for an MCP server that the installed profile doesn't list, usually because the profile changed after activation. Run `kong-harnesses --client claude-code profile activate PROFILE_NAME` again.

## Client setup errors

### "settings file sets ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"

The message says "your Claude settings file". {{ site.claude_code }} would send that value in place of your sign-in. Delete the variable from the settings file, then try again.

### "has a saved key for the kong provider"

pi has its own saved key for the `kong` provider, and it would send that key in place of your sign-in. Run `pi auth logout kong`, then try again.

### "a proxy is set for the plain-HTTP gateway"

The profile uses an `http://` gateway, and a proxy variable in the shell applies to the gateway host. The proxy could read the credential, so `profile activate` sets up no client. To fix it, follow the row for this message in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/#when-kong-harnesses-can-t-give-an-access-token), then run `profile activate` again.

### "is not configured: it can choose a proxy"

The full message is `CLIENT_NAME is not configured: it can choose a proxy that would read the credential for the plain-HTTP gateway GATEWAY_URL unencrypted; use an HTTPS gateway for it`. Codex, OpenCode and Hermes Agent pick their proxy in ways that {{site.kong_harnesses}} can't check, so `profile activate` doesn't set them up for an `http://` gateway, even on this computer. It sets up the other clients. When a check of their settings fails before the write, `profile activate` changes no client settings. A failure later, while it writes the settings, can leave some clients set up. Give these clients a profile with an `https://` gateway.

### "managed settings could send"

The message starts with "your organization's managed settings could send". The profile uses an `http://` gateway, and the managed settings of {{ site.claude_code }} could send its requests through a proxy, because they win over the `NO_PROXY` value that `profile activate` writes. The message names the cause, such as a `NO_PROXY` value that leaves out the gateway host, or a managed settings source that {{site.kong_harnesses}} can't read. Use an `https://` gateway, or ask your administrator to make the change that the message names.

### "settings are inconsistent" or "settings no longer match what this tool installed"

Someone changed the settings that {{site.kong_harnesses}} wrote for an agent CLI. Check the settings file of that client. Then run `kong-harnesses profile cleanup --client CLIENT_NAME`, or remove the leftover values manually when the message says so.

### "settings have two ownership documents"

{{site.kong_harnesses}} found two records of what it wrote for the client, one in the settings folder and one next to the settings file, and it can't tell which one is newer. Remove the leftover values and both records manually, then run the `profile activate` command that the message names.

### "settings cleanup is incomplete"

`profile cleanup` removed only part of what it wrote, and exits with 4. Check the settings of that client, then run `profile cleanup` again.

### "did not finish for" a list of clients

`status`, `profile activate` or `profile cleanup` worked on several agent CLIs, and failed for each client in the list, for different reasons. Run the command again with `--client CLIENT_NAME` for each client to see each reason.

### "selected profile does not configure"

The message names an agent CLI that you gave with `--client`, in `profile activate` or `setup`, and the installed profile has no block for it. The end of the message tells you what to do:

* "ask your administrator for a profile that sets it up, then import it": No command adds the client to the profile. Ask your administrator for a profile with a block for this agent CLI in [`clients`](/kong-harnesses/profile-file/#clients), then [import it](/kong-harnesses/profile/import/).
* "so create the profile again": You made the profile with an older `profile create`, which didn't add this client. Run [`kong-harnesses profile create`](/kong-harnesses/profile/create/) again for the profile.

### "no supported agent client was detected" or "does not configure any detected agent client"

`profile activate` didn't find an agent CLI on this computer that the profile sets up. Install the agent CLI, or name the client with `--client CLIENT_NAME`. Check that the profile has a block for that client in [`clients`](/kong-harnesses/profile-file/#clients).

### "this kong-harnesses runs from a temporary folder"

The agent CLI would lose its credential helper when the folder is removed. [Install {{site.kong_harnesses}}](/kong-harnesses/), then run `profile activate` with the installed copy.

### "requires an interactive controlling terminal"

The command asks you a question, and it runs without a terminal, for example in a script. Run it in a terminal.

## Setup errors

[`kong-harnesses setup`](/kong-harnesses/setup/) runs its steps in order and keeps each finished step when a later step fails.

### "setup without a profile source asks profile create's questions, which needs a terminal"

`setup` without a profile file or URL asks the questions of `profile create`, and it runs without a terminal, for example in a script. Give `setup` the file or URL of the profile, or run it in a terminal.

### "setup stopped at step"

The message names the step that failed and the reason, and the lines before it can give more detail. Fix the cause, using the entry for that message on this page, then run the same `setup` command again. It keeps the work of the finished steps, so it is safe to run again.

When the message says that `setup` leaves a client out, or that a client "cannot be configured", the gateway or this computer refuses that agent CLI, and the line above names the fix. Until you make that fix, `setup` leaves the client out each time, or stops at the same step when it is the only client. To set up the other agent CLIs that the gateway serves, run `setup` without `--client`.

## Fleet build errors

Most `fleet build` and `fleet remove` errors name the flag to add or take out. [Roll out {{ site.claude_code }} through MDM](/kong-harnesses/roll-out-claude-code-through-mdm/) describes `--policy`, `--no-policy`, `--mcp-servers`, `--mcp-config` and `fleet remove`. [Keep a {{ site.claude_code }} fleet on tested versions](/kong-harnesses/maintain-a-claude-code-fleet/) describes a new build with `--record`, which needs the record of the build that the computers have now.

### "fleet build needs an https:// gateway"

The profile uses an `http://` gateway. `fleet build` can't check the proxy settings of the managed computers when it runs, so a proxy there could read the credential. Build from a profile with an `https://` `gateway_origin`.

### "fleet build cannot use a Claude subscription profile yet"

The managed settings that `fleet build` writes sign every {{ site.claude_code }} session in with the credential helper, and a `subscription` profile uses each developer's own Claude sign-in. Build from a profile that doesn't use `sign_in: subscription`.

## Errors that ask you to retry

These messages say only that an operation failed, or ask you to retry later. Check the part of the computer that the message names, then run the command again:

{% table %}
columns:
  - title: Message
    key: message
  - title: What to check
    key: check
rows:
  - message: "`profile creation could not verify local storage; retry later`, `profile creation failed; retry after checking local storage`, `profile creation failed`, `profile lock could not be verified; retry after checking local storage` or `profile storage could not be read`"
    check: "The profile folder of {{site.kong_harnesses}}: that the disk isn't full, and that your account can read and write the folder."
  - message: "`could not write the identity header to Claude Code's settings; retry later`"
    check: "That your account can write the {{ site.claude_code }} settings file."
  - message: "`the key for the gateway MCP server SERVER could not be read; retry later`"
    check: "That the password store, such as the macOS Keychain, is unlocked."
  - message: "`diagnosis could not complete; retry later`"
    check: "Run `doctor` again. If it fails again, collect a debug log as [Collect details for support](#collect-details-for-support) describes."
{% endtable %}

## Collect details for support

To see what a command does, run it with a debug log:

```sh
kong-harnesses COMMAND --log-level debug --log-file kong-harnesses.log
```

You can also set `KONG_HARNESSES_LOG_LEVEL` and `KONG_HARNESSES_LOG_FILE` in the shell.

To report a problem to Kong Support with a `doctor` report, see [kong-harnesses support](/kong-harnesses/support/).
