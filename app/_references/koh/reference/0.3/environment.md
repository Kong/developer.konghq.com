---
title: environment
---

## Command Description

Manage environments

## Syntax

`environment [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`environment list`](/koh/reference/environment_list/{{page.release}}/): List all environments, or sub-environments when --environment is given
- [`environment show`](/koh/reference/environment_show/{{page.release}}/): Show environment details, or a sub-environment when --environment is given
- [`environment create`](/koh/reference/environment_create/{{page.release}}/): Create a new environment, or a sub-environment when --environment is given
- [`environment update`](/koh/reference/environment_update/{{page.release}}/): Update environment metadata, or a sub-environment when --environment is given
- [`environment remove`](/koh/reference/environment_remove/{{page.release}}/): Remove an environment, or a sub-environment when --environment is given

