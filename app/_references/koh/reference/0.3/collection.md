---
title: collection
---

## Command Description

Manage collections

## Syntax

`collection [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`collection list`](/koh/reference/collection_list/{{page.release}}/): List all collections in the project
- [`collection show`](/koh/reference/collection_show/{{page.release}}/): Show collection details
- [`collection create`](/koh/reference/collection_create/{{page.release}}/): Create a new empty collection
- [`collection update`](/koh/reference/collection_update/{{page.release}}/): Update a collection
- [`collection remove`](/koh/reference/collection_remove/{{page.release}}/): Remove a collection

