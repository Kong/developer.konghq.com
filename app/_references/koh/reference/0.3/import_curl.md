---
title: import curl
---

## Command Description

Import a cURL command as a request

## Syntax

`import curl [options] [curl]`

## Local Flags

- `--from-file <path>`: Read the cURL command from a file (avoids shell escaping)
- `--collection <id|name>`: Collection to create the request in
- `--parent <id>`: Parent ID (collection or folder); overrides --collection
- `--name <name>`: Request name (defaults to "METHOD <url>")

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

