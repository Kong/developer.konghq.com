---
title: document
---

## Command Description

Manage API specifications

## Syntax

`document [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`document list`](/koh/reference/document_list/{{page.release}}/): List all documents in the project
- [`document show`](/koh/reference/document_show/{{page.release}}/): Show document details
- [`document remove`](/koh/reference/document_remove/{{page.release}}/): Remove a document
- [`document spec`](/koh/reference/document_spec/{{page.release}}/): Inspect specs within documents

