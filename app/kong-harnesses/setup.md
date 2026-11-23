---
title: kong-harnesses setup
description: Import or create one profile, or use an installed profile, sign in, and configure the client in one run.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `setup` command gets a profile, signs in, and configures your agent CLI in one run.
Use it to get a developer from a profile to a working agent CLI with one command.

`setup` takes the profile from one of these sources:

* A profile file or HTTPS URL from your administrator, which `setup` imports.
* An installed profile, which you name with `--profile PROFILE_NAME` (or `-p PROFILE_NAME`).
  `setup` checks that the profile is installed, then starts at sign-in.
* Nothing, in a terminal.
  `setup` then asks the questions of [`profile create`](/kong-harnesses/profile/create/), as [Set up without a profile file](#set-up-without-a-profile-file) describes.

If you pass both a profile source and `--profile`, `setup` exits with a usage error.

`setup` skips the sign-in step in two cases:

* The profile uses `sign_in: environment_key`, because each command reads the key from `KONG_HARNESSES_STATIC_KEY`.
* Every agent CLI that `setup` configures signs in through its own plugin.

## Run setup again

You can run `setup` again at any time.
A rerun doesn't change what is already correct:

* `setup` keeps a usable sign-in.
* `setup` changes the settings of a configured client only when they don't match the profile, for example after the profile changes its model aliases.
* With a profile file or HTTPS URL, `setup` imports the profile again only when the source differs from the installed profile.
* Without a source or `--profile`, `setup` starts profile creation again from the first question.

## Resume after a step fails

`setup` stops at the first step that fails, and keeps each step that finished.
The message names the failed step, the reason, and the command that resumes setup.
Fix the cause, then run that command.

The resume command is usually the same `setup` command.
After `profile create` saves a new profile, the resume command is `setup --profile PROFILE_NAME`, so you don't answer the profile creation questions again.
It keeps the `--client`, `--no-browser`, `--auto-approve`, `--skip-route-check`, `--log-level`, and `--log-file` flags of your run.

The gateway or this computer can refuse an agent CLI.
Until you make the fix that the message names, `setup` then leaves that client out, or stops at the same step if it's the only client.
For each message and its fix, see [Setup errors](/kong-harnesses/errors/#setup-errors).

## Set up without a profile file

When you don't have a profile file or HTTPS URL, run `setup` in a terminal without a source or `--profile`.
`setup` asks the questions of `profile create`, then signs in and configures your agent CLI.
For example, to configure only {{ site.claude_code }}:

```sh
kong-harnesses setup --client claude-code
```

Before you start, get the gateway URL from your administrator.
If the gateway doesn't list its models, also get a model ID, because `setup` asks for the model before the sign-in step.

When your administrator gave you a key, pick **Use a key from the administrator** at the **Sign-in** question.
If the gateway lists its models only to a caller with a key, `setup` asks for the key during profile creation to read the model list, when the terminal can hide what you type.
The sign-in step then saves that key without asking again, unless the gateway refused it.
When the profile already has a usable sign-in, `setup` keeps the saved key.

## Command usage

{% include_cached kong-harnesses/help/setup/index.md %}
