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
When you pass a profile file or HTTPS URL, `setup` is safe to run again: an unchanged source isn't re-imported, a usable sign-in is left alone, and a configured client is left unchanged.
It stops at the first step that fails, and running the same command with that file or URL resumes there.
Without a source, running `setup` again starts profile creation from the first question.

## Set up without a profile file

If you don't have a profile file or HTTPS URL, run `setup` without a source in a terminal to create a profile interactively, sign in, and configure your agent CLI (for example, for {{ site.claude_code }} only):

```sh
kong-harnesses setup --client claude-code
```

`setup` asks the questions of `profile create`.
You need the gateway URL from your administrator, and also a model ID from your administrator if the gateway doesn't list its models, because `setup` can ask for the model before the sign-in step asks for the key.
When you have only an administrator-issued key, pick **Use a key from the administrator** at the **Sign-in** question.
If the gateway lists its models only with a key, `setup` asks for the key during profile creation to fetch the model list when the terminal can hide input.
When you enter a key and the gateway doesn't reject it, the sign-in step saves that key without asking again.
Otherwise, the sign-in step asks for the key.

## Command usage

{% include_cached kong-harnesses/help/setup/index.md %}
