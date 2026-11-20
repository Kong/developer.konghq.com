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

When a command fails, {{site.kong_harnesses}} prints one line that starts with `Error:` to standard error, and says what to do next. For a wrong flag or argument, most commands also print `Run 'kong-harnesses <command> --help' for usage`.

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
    meaning: "A temporary failure, such as a network error or a locked password store."
    action: "Follow the message, then run the command again."
  - value: "2"
    meaning: "A wrong flag or argument, or a problem in the profile, the client settings or this computer."
    action: "Fix what the message names. Running the command again without a change gives the same error."
  - value: "3"
    meaning: "The command needs a new sign-in."
    action: "Run `kong-harnesses login --profile <name>`, or set the key that the message names."
  - value: "4"
    meaning: "A command that removes something did only part of its work, for example `logout` removed the local sign-in but couldn't confirm the sign-out at the identity provider."
    action: "Follow the message, then run the command again."
  - value: "130"
    meaning: "You cancelled the command, for example with Ctrl+C."
    action: "Run the command again when you are ready."
{% endtable %}

## Profile errors

### "selected profile does not exist"

The name that you gave with `--profile` or `KONG_HARNESSES_PROFILE` isn't installed on this computer. To see the installed profiles, run:

```sh
kong-harnesses profile list
```

### "requires a profile, and no installed profile is usable"

The command needs a profile, and no installed profile works. Run `kong-harnesses profile list` to see the profiles, then install one with [`kong-harnesses profile import`](/kong-harnesses/profile/import/) or [`kong-harnesses profile create`](/kong-harnesses/profile/create/).

### "profile import rejected; check the profile document"

The profile file isn't valid for this release. Common causes:

* The file isn't valid JSON, or it has a field that this release doesn't know.
* The `schema_version` is newer than this release reads. [Install a newer {{site.kong_harnesses}}](/kong-harnesses/), or ask your administrator for a profile with an older version.
* A field has a value that the schema version doesn't allow.

Check the file against the [profile file reference](/kong-harnesses/profile-file/).

### "selected profile is invalid" or "uses an unsupported format"

The installed copy of the profile can't be read. Install the profile again from your administrator's file or URL with `kong-harnesses profile import`.

### "selected profile still has a saved sign-in"

`profile delete` refuses a profile that is still signed in. Run `kong-harnesses logout --profile <name>`, then delete the profile.

### "selected profile is still activated"

`profile delete` refuses a profile that an agent CLI still uses. Run `kong-harnesses profile cleanup --client <client>`, then delete the profile.

## Sign-in and access token errors

The errors that `login`, `credential` and `token` print, such as an expired sign-in, a locked Keychain or a proxy in front of an `http://` gateway, are listed with their fixes in [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/#when-kong-harnesses-cant-give-an-access-token).

## Client setup errors

### "your Claude Code settings file sets ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"

{{ site.claude_code }} would send that value in place of your sign-in. Delete the variable from the settings file, then try again.

### "settings are inconsistent" or "settings no longer match what this tool installed"

Someone changed the settings that {{site.kong_harnesses}} wrote for an agent CLI. Check the settings file of that client. Then run `kong-harnesses profile cleanup --client <client>`, or remove the leftover values by hand when the message says so.

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
