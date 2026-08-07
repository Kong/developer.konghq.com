---
title: import
---

## Command Description

Import resources into a project

## Syntax

`import [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`import oas`](/koh/reference/import_oas/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification (YAML or JSON)
- [`import curl`](/koh/reference/import_curl/{{page.release}}/): Import a cURL command as a request

