---
title: "{{site.kong_harnesses}} commands"
description: "Find the {{site.kong_harnesses}} command for each task: set up and sign in, manage profiles, check your setup, get an access token, and show budget numbers."
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

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: "Sign in with {{site.kong_harnesses}}"
    url: /kong-harnesses/sign-in/
  - text: "Troubleshoot {{site.kong_harnesses}}"
    url: /kong-harnesses/troubleshooting/
  - text: "Install {{site.kong_harnesses}} for every user of a computer"
    url: /kong-harnesses/install/
---

{{site.kong_harnesses}} has one command for each task: setting up a computer, signing in, managing profiles, checking the setup, and getting an access token.
Use this page to find the command that fits your task, then follow the link to its page for the full list of options.

Most developers run [`setup`](/kong-harnesses/setup/) once and [`doctor`](/kong-harnesses/doctor/) when something stops working.
Agent CLIs such as {{site.claude_code}} call `credential` and `statusline` for you, so you don't run them yourself.

## Set up and sign in

If you have a profile URL or file from your administrator, run `setup` to import the profile, sign in, and configure the agent CLI in one run.
Run `login` and `logout` on their own when you only need to repair a sign-in or remove it.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses setup](/kong-harnesses/setup/)
    description: "Import a profile, sign in, and configure the agent CLI, in one run."
  - command: |
      [kong-harnesses login](/kong-harnesses/login/)
    description: "Sign in to a profile, repair a saved sign-in, or report why a sign-in fails."
  - command: |
      [kong-harnesses logout](/kong-harnesses/logout/)
    description: "Sign out of a profile and remove its saved sign-in from this computer."
{% endtable %}

## Manage profiles

A profile names the gateway, the identity provider, and the model.
An administrator creates a profile once with `profile create`, and developers install it with `profile import`.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses profile create](/kong-harnesses/profile/create/)
    description: "Create a profile from your identity provider's details."
  - command: |
      [kong-harnesses profile import](/kong-harnesses/profile/import/)
    description: "Install a profile from a file or HTTPS URL."
  - command: |
      [kong-harnesses profile list](/kong-harnesses/profile/list/)
    description: "List installed profiles."
  - command: |
      [kong-harnesses profile get](/kong-harnesses/profile/get/)
    description: "Show the settings of an installed profile."
  - command: |
      [kong-harnesses profile activate](/kong-harnesses/profile/activate/)
    description: "Configure one or every detected agent CLI to use a profile."
  - command: |
      [kong-harnesses profile default](/kong-harnesses/profile/default/)
    description: "Choose the profile that commands use when you don't give `--profile`."
  - command: |
      [kong-harnesses profile cleanup](/kong-harnesses/profile/cleanup/)
    description: "Remove the agent CLI settings that kong-harnesses owns."
  - command: |
      [kong-harnesses profile delete](/kong-harnesses/profile/delete/)
    description: "Delete an installed profile from this computer."
{% endtable %}

## Check your setup

Run `status` to see the local sign-in and agent CLI state of a profile.
It opens no network connections and doesn't change any settings, so it's quick.
Run `doctor` when `status` looks right but the agent CLI still can't reach the gateway, because `doctor` also checks both endpoints and shows a fix for each finding.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses status](/kong-harnesses/status/)
    description: "Inspect the local sign-in and agent CLI state of a profile."
  - command: |
      [kong-harnesses doctor](/kong-harnesses/doctor/)
    description: "Check a profile end to end and report a fix beside each finding."
{% endtable %}

For the next step after each `doctor` finding, see [Troubleshoot {{site.kong_harnesses}}](/kong-harnesses/troubleshooting/).

## Get an access token

Agent CLIs run `credential` to get a short-lived access token, and it starts a first sign-in when the profile doesn't have one.
Run `token` when you need a token for a script, because it prints the token for the profile that you name and never starts a sign-in.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses credential](/kong-harnesses/credential/)
    description: "Return a short-lived access token, and sign in first when needed."
  - command: |
      [kong-harnesses token](/kong-harnesses/token/)
    description: "Print a short-lived access token for a profile that you name."
{% endtable %}

## Show budget numbers in the status bar

The agent CLI runs `statusline` to render one status-bar line, and `budget refresh` updates the budget numbers that the line shows.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kong-harnesses statusline](/kong-harnesses/statusline/)
    description: "Render one status-bar line for the agent CLI that calls it."
  - command: |
      [kong-harnesses budget refresh](/kong-harnesses/budget/refresh/)
    description: "Refresh the budget numbers of a profile."
{% endtable %}

## Global flags

Every command accepts the following flags.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Description
    key: description
rows:
  - flag: "`--client`"
    description: "The agent CLI to work on. The only supported value is `claude-code`."
  - flag: "`--log-file`"
    description: "Write the debug log to this path instead of stderr."
  - flag: "`--log-level`"
    description: "Set the log level: `trace`, `debug`, `info`, `warn`, or `error`. The default is `error`. The `debug` and `trace` levels also write the debug log."
{% endtable %}
