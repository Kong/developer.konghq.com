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

When a command fails, {{site.kong_harnesses}} prints a line that starts with `Error:` to standard error, and says what to do next. For a wrong flag or argument, most commands also print `Run 'kong-harnesses <command> --help' for usage`.

`kong-harnesses doctor` works in another way. It prints its findings, and the `--report` output, to standard output. When a check fails, its exit code comes from the first failed check: 2 for a profile or setup problem, 3 for a sign-in problem, and 1 for any other problem. A warning alone exits with 0.

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
    action: "Run `kong-harnesses login --profile <name>`, or set the key that the message names. If the message says that the next call resumes the renewal, run the command again first."
  - value: "4"
    meaning: "The command did part of its work. For example, `logout` removed the local sign-in but couldn't confirm the sign-out at the identity provider, or `profile activate` set up some agent CLIs and then failed for another one."
    action: "Follow the message, then run the command again."
  - value: "130"
    meaning: "You canceled the command, for example with Ctrl+C. The message says what the command changed, if anything."
    action: "Run the command again when you are ready."
{% endtable %}

## Profile errors

### "selected profile does not exist"

The name that you gave with `--profile` or `KONG_HARNESSES_PROFILE` isn't installed on this computer. To see the installed profiles, run:

```sh
kong-harnesses profile list
```

### "requires a profile, and no installed profile is usable" or "and none is installed"

The command needs a profile, and no installed profile works. Run `kong-harnesses profile list` to see the profiles, then install one with [`kong-harnesses profile import`](/kong-harnesses/profile/import/) or [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

### "profile name is invalid"

The profile name that you gave doesn't follow the [rules for `name`](/kong-harnesses/profile-file/#top-level-fields). Check the spelling of the name.

### "profile import rejected; check the profile document"

The profile file isn't valid for this release. Common causes:

* The file isn't valid JSON, or it has a field that this release doesn't know.
* The `schema_version` is newer than this release reads. [Install a newer {{site.kong_harnesses}}](/kong-harnesses/), or ask your administrator for a profile with an older version.
* A field has a value that the schema version doesn't allow, or two choices conflict.

Check the file against the [profile file reference](/kong-harnesses/profile-file/).

### "need an HTTPS gateway"

Release 0.18.0 and later. The full message is "a Claude subscription and a gateway MCP server with its own OAuth sign-in need an HTTPS gateway". Change `gateway_origin` in the profile to an `https://` URL. Earlier releases refuse the same profile with "profile import rejected".

### "profile import failed; retry after checking source access"

{{site.kong_harnesses}} couldn't read the profile from the file or URL that you gave, or couldn't save it. Check that the file exists and that you can read it, or that the URL opens from this computer over HTTPS. Then run the import again.

### "profile is busy; retry the import"

Another {{site.kong_harnesses}} command, such as a sign-in or a renewal, uses the profile now. Wait for that command to finish, then run the import again.

### "still uses this profile, so its security identity cannot change"

The profile that you import changes a [security identity field](/kong-harnesses/profile-file/#security-identity), and an agent CLI still uses the installed profile. Run the command that the message names, `kong-harnesses profile cleanup --client <client>`, or activate another profile in that client. Then import the profile, and activate it again.

### "your organization's managed settings run this profile in Claude Code"

Your organization delivers the profile to {{ site.claude_code }} through managed settings, so you can't change its security identity or delete it on your computer. Ask your administrator to deliver the new profile with `kong-harnesses fleet build`.

### "your administrator installed a profile with this name for every user"

An administrator installed this profile for every user of the computer, so you can't replace or remove it. Sign in to it with `kong-harnesses login`, or ask your administrator to change it.

### "selected profile is invalid"

The installed copy of the profile can't be read. Install the profile again from your administrator's file or URL with `kong-harnesses profile import`.

### "selected profile needs a newer kong-harnesses" or "uses an unsupported format"

The installed profile has a schema version that this release can't read, usually because a newer release installed it. [Update {{site.kong_harnesses}}](/kong-harnesses/), then run the command again. Up to 0.17.1, the message is "selected profile uses an unsupported format; reinstall it with this version", and the fix is the same: update {{site.kong_harnesses}}.

### "selected profile is missing, invalid, or unsupported"

`token`, `credential`, `doctor` and the MCP credential helper print this message when the profile isn't installed, can't be read, or needs a newer release. Run `kong-harnesses profile list` to check that the profile is installed. If it is, install it again with `kong-harnesses profile import`, or update {{site.kong_harnesses}} when a newer release wrote it.

### "the profile installed for every user can be changed by an account that is not an administrator"

An administrator installed the profile for every user of the computer, but its file or folder lets other accounts change it, so {{site.kong_harnesses}} doesn't use it. Ask your administrator to install the profile again.

### "selected profile still has a saved sign-in"

`profile delete` refuses a profile that is still signed in. Run `kong-harnesses logout --profile <name>`, then delete the profile.

### "selected profile is still activated"

`profile delete` refuses a profile that an agent CLI still uses. Run `kong-harnesses profile cleanup --client <client>`, then delete the profile.

## Sign-in errors

The errors that `credential` and `token` print, such as an expired sign-in, a locked Keychain or a proxy in front of an `http://` gateway, are listed with their fixes in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/#when-kong-harnesses-cant-give-an-access-token). This section lists the other sign-in errors.

### "a usable login already exists"

The profile is already signed in, and `login` keeps that sign-in. To sign in with another account, run `kong-harnesses login --profile <name> --replace`.

### "no key for the gateway MCP server"

The message ends with "is saved on this computer". A gateway MCP server in the profile takes a key, and you didn't save one yet. Run `kong-harnesses login --profile <name>`, and enter the key from your administrator when `login` asks for it.

### "the sign-in is saved, but a gateway MCP server has no key yet"

You canceled `login` after the sign-in, before you entered the key for a gateway MCP server. Run `kong-harnesses login --profile <name>` again to add the key.

### "lists no gateway MCP server at the address Claude Code named"

{{ site.claude_code }} asked for a credential for an MCP server that the installed profile doesn't list, usually because the profile changed after activation. Run `kong-harnesses --client claude-code profile activate <name>` again.

### "server sign-out unconfirmed" or "local cleanup incomplete"

`logout` did only part of its work, and exits with 4. Run `kong-harnesses logout --profile <name>` again. When the message says that the server sign-out is unconfirmed, also check the sign-in in your identity provider.

## Client setup errors

### "settings file sets ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"

The message says "your Claude settings file". {{ site.claude_code }} would send that value in place of your sign-in. Delete the variable from the settings file, then try again.

### "has a saved key for the kong provider"

pi has its own saved key for the `kong` provider, and it would send that key in place of your sign-in. Run `pi auth logout kong`, then try again.

### "settings are inconsistent" or "settings no longer match what this tool installed"

Someone changed the settings that {{site.kong_harnesses}} wrote for an agent CLI. Check the settings file of that client. Then run `kong-harnesses profile cleanup --client <client>`, or remove the leftover values manually when the message says so.

### "settings have two ownership documents"

{{site.kong_harnesses}} found two records of what it wrote for the client, one in the settings folder and one next to the settings file, and it can't tell which one is newer. Remove the leftover values and both records manually, then run the `profile activate` command that the message names.

### "settings cleanup is incomplete"

`profile cleanup` removed only part of what it wrote, and exits with 4. Check the settings of that client, then run `profile cleanup` again.

### "did not finish for" a list of clients

A command that sets up or cleans up several agent CLIs failed for each client in the list, for different reasons. Run the command again with `--client <client>` for each client to see each reason.

### "no supported agent client was detected" or "does not configure any detected agent client"

`profile activate` didn't find an agent CLI on this computer that the profile sets up. Install the agent CLI, or name the client with `--client <client>`. Check that the profile has a block for that client in [`clients`](/kong-harnesses/profile-file/#clients).

### "this kong-harnesses runs from a temporary folder"

The agent CLI would lose its credential helper when the folder is removed. [Install {{site.kong_harnesses}}](/kong-harnesses/), then run `profile activate` with the installed copy.

### "requires an interactive controlling terminal"

The command asks you a question, and it runs without a terminal, for example in a script. Run it in a terminal.

## Collect details for support

To see what a command does, run it with a debug log:

```sh
kong-harnesses <command> --log-level debug --log-file kong-harnesses.log
```

You can also set `KONG_HARNESSES_LOG_LEVEL` and `KONG_HARNESSES_LOG_FILE` in the shell.

To report a problem to Kong Support with a `doctor` report, see [kong-harnesses support](/kong-harnesses/support/).
