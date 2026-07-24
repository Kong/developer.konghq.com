---
title: environment create
---

## Command Description

Create a new environment, or a sub-environment when --environment is given

## Syntax

`environment create [options]`

## Local Flags

- `--name <name>`: Environment name
- `--description <desc>`: Environment description
- `--color <color>`: Sub-environment color (only used with --environment)
- `--is-private <boolean>`: Whether the sub-environment is private (true/false; only used with --environment)
- `--environment <id|name>`: Parent environment to create a sub-environment within
- `--global`: Create within/as a global environment

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

