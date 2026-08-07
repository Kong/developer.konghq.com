---
title: request
---

## Command Description

Manage requests within collections

## Syntax

`request [options] [command]`

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Subcommands

- [`request list`](/koh/reference/request_list/{{page.release}}/): List requests, optionally scoped to a collection
- [`request show`](/koh/reference/request_show/{{page.release}}/): Show request details
- [`request create`](/koh/reference/request_create/{{page.release}}/): Create a new request
- [`request update`](/koh/reference/request_update/{{page.release}}/): Update a request
- [`request remove`](/koh/reference/request_remove/{{page.release}}/): Remove a request
- [`request run`](/koh/reference/request_run/{{page.release}}/): Run a request

