---
title: environment list
---

## Command Description

List all environments, or sub-environments when --environment is given

## Syntax

`environment list [options]`

## Local Flags

- `--query <text>`: Case-insensitive query across environment name and description
- `--environment <id|name>`: Parent environment to list sub-environments of
- `--global`: List global environments

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

