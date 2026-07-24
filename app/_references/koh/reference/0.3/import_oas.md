---
title: import oas
---

## Command Description

Import an OpenAPI 3.x or Swagger 2.0 Specification (YAML or JSON)

## Syntax

`import oas [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`import oas collection`](/koh/reference/import_oas_collection/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification as a collection
- [`import oas document`](/koh/reference/import_oas_document/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification as an Insomnia spec document

