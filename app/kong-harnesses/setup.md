---
title: kong-harnesses setup
description: Import one profile, sign in, and configure the client, in one run.

content_type: reference
layout: reference

tools:
  - kong-harnesses

breadcrumbs:
  - /kong-harnesses/
---

The `setup` command imports one profile, signs in, and configures the client, in one run.
On every rerun, `setup` leaves a usable sign-in and a configured client as they are.
Only an unchanged profile file or HTTPS URL makes `setup` skip the import.
Running `setup` without a source starts profile creation from the first question.
`setup` stops at the first step that fails.
After you fix the cause, run the command that the message names to resume past the finished steps, unless a client is refused.
When the gateway or this computer refuses a client, a rerun stops at the same step or leaves that client out until you make the fix that the message names, as ["setup stopped at step"](/kong-harnesses/errors/#setup-stopped-at-step) describes.

## Set up without a profile file

If you don't have a profile file or HTTPS URL, run `setup` without a source in a terminal to create a profile interactively, sign in, and configure your agent CLI (for example, for {{ site.claude_code }} only):

```sh
kong-harnesses setup --client claude-code
```

`setup` asks the questions of `profile create`.
You need the gateway URL from your administrator, and also a model ID from your administrator if the gateway doesn't list its models, because `setup` can ask for the model before the sign-in step asks for the key.
When you have only an administrator-issued key, pick **Use a key from the administrator** at the **Sign-in** question.
With that choice, if the gateway lists its models only with a key, `setup` asks for the key during profile creation to fetch the model list when the terminal can hide input.
At the sign-in step, if the profile already has a usable sign-in, `setup` keeps the saved key.
When the sign-in step needs a key, it saves the key from profile creation without asking again if you entered one and the gateway didn't reject it, or asks for the key otherwise.

## Command usage

{% include_cached kong-harnesses/help/setup/index.md %}
