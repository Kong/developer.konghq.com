---
title: environment update
---

## Command Description

Update environment metadata, or a sub-environment when --environment is given

## Syntax

`environment update [options] <id|name>`

## Local Flags

- `--name <name>`: New name
- `--description <desc>`: New description
- `--color <color>`: New color
- `--environment <id|name>`: Parent environment containing the sub-environment to update
- `--global`: Update within/as a global environment

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

